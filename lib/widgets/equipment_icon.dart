import 'package:flutter/material.dart';
import '../data/api_service.dart';
import '../models/equipment.dart';

/// Picks a Material icon for equipment based on its category/name, replacing
/// the old hardcoded per-item icons (when no photo is uploaded).
IconData equipmentIcon(String categoryOrName) {
  final s = categoryOrName.toLowerCase();

  if (s.contains('laptop') ||
      s.contains('computer') ||
      s.contains('chromebook') ||
      s.contains('tablet')) {
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
  if (s.contains('printer') ||
      s.contains('scanner') ||
      s.contains('photocopier') ||
      s.contains('laminating')) {
    return Icons.print_rounded;
  }
  if (s.contains('cable') || s.contains('hdmi') || s.contains('vga')) {
    return Icons.cable_rounded;
  }
  if (s.contains('extension') || s.contains('power') || s.contains('charger')) {
    return Icons.power_rounded;
  }
  if (s.contains('router') ||
      s.contains('switch') ||
      s.contains('network') ||
      s.contains('wi-fi')) {
    return Icons.router_rounded;
  }
  if (s.contains('science') ||
      s.contains('microscope') ||
      s.contains('lab') ||
      s.contains('thermometer') ||
      s.contains('calculator')) {
    return Icons.science_rounded;
  }
  if (s.contains('tripod')) return Icons.camera_alt_rounded;
  if (s.contains('flash') ||
      s.contains('drive') ||
      s.contains('usb') ||
      s.contains('dvd')) {
    return Icons.usb_rounded;
  }
  if (s.contains('information technology')) return Icons.computer_rounded;
  if (s.contains('audio')) return Icons.surround_sound_rounded;
  if (s.contains('office')) return Icons.print_rounded;
  if (s.contains('electrical')) return Icons.electrical_services_rounded;
  if (s.contains('general')) return Icons.inventory_2_rounded;

  return Icons.devices_other_rounded;
}

/// Renders the equipment's main profile photo (`equipment.imageUrl`) clipped to
/// [borderRadius], gracefully falling back to the category [equipmentIcon] when
/// no photo is uploaded or if the image fails to load.
class EquipmentVisual extends StatelessWidget {
  final Equipment equipment;
  final double iconSize;
  final Color iconColor;
  final BorderRadius? borderRadius;

  const EquipmentVisual({
    super.key,
    required this.equipment,
    required this.iconSize,
    required this.iconColor,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final fallback = Center(
      child: Icon(
        equipmentIcon('${equipment.category} ${equipment.name}'),
        color: iconColor,
        size: iconSize,
      ),
    );

    final url = equipment.imageUrl;
    if (url == null || url.isEmpty) {
      return fallback;
    }

    final img = Image.network(
      url,
      headers: ApiConfig.mediaHeaders,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (_, __, ___) => fallback,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return fallback;
      },
    );

    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius!,
        child: img,
      );
    }
    return img;
  }
}
