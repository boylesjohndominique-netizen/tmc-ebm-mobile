import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'api_service.dart';

/// Realtime connection to Laravel Reverb (Pusher protocol) for the mobile app.
///
/// Mirrors the web admin's realtime.js: the backend broadcasts lightweight
/// "something changed" signals, and the client refetches over the authorized
/// REST API in response.
///
/// Channels (backend/routes/channels.php):
///   private-user.{id} — the signed-in student's notification feed
///                       ('notification.created' → refetch notifications)
///
/// Handshake flow:
///   1. Open ws://host:port/app/{key}
///   2. Server replies 'pusher:connection_established' with a socket_id
///   3. POST /api/broadcasting/auth {socket_id, channel_name} (Sanctum token)
///   4. Send pusher:subscribe with the auth signature → live events
class RealtimeService {
  RealtimeService._();
  static final RealtimeService instance = RealtimeService._();

  WebSocketChannel? _channel;
  StreamSubscription? _sub;
  Timer? _reconnectTimer;
  Timer? _pingTimer;
  int _retry = 0;
  bool _disposed = false;

  int? _userId;
  String? _socketId;

  final _stateCtrl = StreamController<String>.broadcast();
  final _notificationCtrl = StreamController<Map<String, dynamic>>.broadcast();
  final _banCtrl = StreamController<Map<String, dynamic>>.broadcast();

  /// 'connected' | 'connecting' | 'disconnected'
  Stream<String> get stateStream => _stateCtrl.stream;
  String _state = 'disconnected';
  String get state => _state;

  /// Payloads of 'notification.created' events for the signed-in user.
  Stream<Map<String, dynamic>> get notificationStream => _notificationCtrl.stream;

  /// Payloads of 'user.banned' events ({reason, banned_at}) for the signed-in
  /// user. Fired the moment an admin bans the account, even though the API
  /// token is revoked at the same time.
  Stream<Map<String, dynamic>> get banStream => _banCtrl.stream;

  void _setState(String s) {
    if (_state == s) return;
    _state = s;
    if (!_stateCtrl.isClosed) _stateCtrl.add(s);
  }

  /// Connect (or re-connect) as the given user. Safe to call repeatedly.
  void connect({required int userId}) {
    _userId = userId;
    _disposed = false;
    _open();
  }

  void _open() {
    if (_disposed || _userId == null) return;
    _teardownSocket();
    _setState('connecting');

    final uri = Uri.parse(
      '${ApiConfig.reverbScheme}://${ApiConfig.reverbHost}:${ApiConfig.reverbPort}'
      '/app/${ApiConfig.reverbAppKey}',
    );

    try {
      _channel = WebSocketChannel.connect(uri);
    } catch (e) {
      debugPrint('[realtime] connect failed: $e');
      _scheduleReconnect();
      return;
    }

    _sub = _channel!.stream.listen(
      _onMessage,
      onError: (Object e) {
        debugPrint('[realtime] stream error: $e');
        _scheduleReconnect();
      },
      onDone: () {
        if (!_disposed) _scheduleReconnect();
      },
    );

    // Reverb expects client activity; ping every 30s keeps the socket open.
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _send({'event': 'pusher:ping', 'data': {}});
    });
  }

  void _onMessage(dynamic raw) {
    Map<String, dynamic> msg;
    try {
      msg = jsonDecode(raw as String) as Map<String, dynamic>;
    } catch (_) {
      return;
    }

    final event = msg['event'] as String?;
    final dataStr = msg['data'];
    Map<String, dynamic> data = {};
    if (dataStr is String) {
      try {
        final decoded = jsonDecode(dataStr);
        if (decoded is Map<String, dynamic>) data = decoded;
      } catch (_) {}
    } else if (dataStr is Map<String, dynamic>) {
      data = dataStr;
    }

    switch (event) {
      case 'pusher:connection_established':
        _socketId = data['socket_id'] as String?;
        _retry = 0;
        _setState('connected');
        debugPrint('[realtime] connected (socket $_socketId)');
        _subscribeUserChannel();
        break;

      case 'pusher:ping':
        _send({'event': 'pusher:pong', 'data': {}});
        break;

      case 'pusher_internal:subscription_succeeded':
        debugPrint('[realtime] subscribed: ${msg['channel']}');
        break;

      case 'pusher_internal:auth_error':
      case 'pusher:error':
        debugPrint('[realtime] server error: ${msg['data']}');
        break;

      default:
        // Events broadcast with broadcastAs('notification.created') arrive
        // prefixed by the channel namespace: 'private-user.{id}#notification.created'
        // (or plain 'notification.created' depending on protocol quirks).
        if (event != null && event.endsWith('notification.created')) {
          _notificationCtrl.add(data);
        } else if (event != null && event.endsWith('user.banned')) {
          _banCtrl.add(data);
        }
    }
  }

  void _subscribeUserChannel() {
    final userId = _userId;
    if (userId == null || _socketId == null) return;
    _authorizeAndSubscribe('private-user.$userId');
  }

  /// Private channels need a signed auth response from the backend's
  /// /api/broadcasting/auth endpoint (Sanctum-protected).
  Future<void> _authorizeAndSubscribe(String channel) async {
    final socketId = _socketId;
    if (socketId == null) return;

    try {
      final res = await ApiService.instance.request(
        'POST',
        'broadcasting/auth',
        withAuth: true,
        body: {'socket_id': socketId, 'channel_name': channel},
      );

      final auth = (res.data?['auth'] as String?) ?? '';
      if (res.success && auth.isNotEmpty) {
        _send({
          'event': 'pusher:subscribe',
          'data': {'auth': auth, 'channel': channel},
        });
        debugPrint('[realtime] authorized $channel');
      } else {
        debugPrint('[realtime] auth failed for $channel: ${res.message}');
      }
    } catch (e) {
      debugPrint('[realtime] auth exception: $e');
    }
  }

  void _send(Map<String, dynamic> payload) {
    try {
      _channel?.sink.add(jsonEncode(payload));
    } catch (e) {
      debugPrint('[realtime] send failed: $e');
    }
  }

  void _teardownSocket() {
    _pingTimer?.cancel();
    _sub?.cancel();
    try {
      _channel?.sink.close();
    } catch (_) {}
    _channel = null;
    _socketId = null;
  }

  void _scheduleReconnect() {
    _setState('disconnected');
    _teardownSocket();
    if (_disposed || _userId == null) return;
    _retry = min(_retry + 1, 6);
    final delay = Duration(seconds: 2 * _retry);
    debugPrint('[realtime] reconnecting in ${delay.inSeconds}s…');
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(delay, _open);
  }

  /// Close the socket (logout).
  void disconnect() {
    _disposed = true;
    _reconnectTimer?.cancel();
    _teardownSocket();
    _userId = null;
    _setState('disconnected');
  }
}
