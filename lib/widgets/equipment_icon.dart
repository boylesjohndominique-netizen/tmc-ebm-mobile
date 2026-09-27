import 'package:flutter/material.dart';

/// Picks a Material icon for equipment based on its category/name, replacing
/// the old hardcoded per-item icons (the backend has no icon column).
IconData equipmentIcon(String categoryOrName) {
  final s = categoryOrName.toLowerCase();

  if (s.contains('laptop') || s.contains('computer') || s.contains('chromebook') || s.contains('tablet')) {
    return Icons.computer_rounded;
  }
  if (s.contains('projector') || s.contains('led') || s.contains('tv')) {
    return Icons.cast_rounded;
  }
  if (s.contains('camera')) return Icons.photo_camera_rounded;
  if (s.contains('microphone') || s.contains('mic')) return Icons.mic_rounded;
  if (s.contains('speaker') || s.contains('amplifier') || s.contains('sound')) {
    return Icons.speaker_rounded;
  }
  if (s.contains('printer') || s.contains('scanner') || s.contains('photocopier') || s.contains('laminating')) {
    return Icons.print_rounded;
  }
  if (s.contains('cable') || s.contains('hdmi') || s.contains('vga')) return Icons.cable_rounded;
  if (s.contains('extension') || s.contains('power') || s.contains('charger')) {
    return Icons.power_rounded;
  }
  if (s.contains('router') || s.contains('switch') || s.contains('network') || s.contains('wi-fi')) {
    return Icons.router_rounded;
  }
  if (s.contains('science') || s.contains('microscope') || s.contains('lab') || s.contains('thermometer') || s.contains('calculator')) {
    return Icons.science_rounded;
  }
  if (s.contains('tripod')) return Icons.camera_alt_rounded;
  if (s.contains('flash') || s.contains('drive') || s.contains('usb') || s.contains('dvd')) {
    return Icons.usb_rounded;
  }
  if (s.contains('information technology')) return Icons.computer_rounded;
  if (s.contains('audio')) return Icons.surround_sound_rounded;
  if (s.contains('office')) return Icons.print_rounded;
  if (s.contains('electrical')) return Icons.electrical_services_rounded;
  if (s.contains('general')) return Icons.inventory_2_rounded;

  return Icons.devices_other_rounded;
}
