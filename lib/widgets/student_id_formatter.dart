import 'package:flutter/services.dart';

/// Formats raw input into the TMC Student ID pattern `00-000000`
/// (2 digits, an automatic dash, then up to 6 digits).
String formatStudentId(String input) {
  final digits = input.replaceAll(RegExp(r'\D'), '');
  if (digits.isEmpty) return '';
  final capped = digits.length > 8 ? digits.substring(0, 8) : digits;
  if (capped.length <= 2) {
    return capped;
  }
  return '${capped.substring(0, 2)}-${capped.substring(2)}';
}

/// Validates that a Student ID matches `00-000000`.
String? validateStudentId(String? value) {
  final trimmed = value?.trim() ?? '';
  if (trimmed.isEmpty) {
    return 'Student ID is required (00-000000)';
  }
  if (!RegExp(r'^\d{2}-\d{6}$').hasMatch(trimmed)) {
    return 'Student ID must follow 00-000000 format';
  }
  return null;
}

/// Live input formatter that only accepts digits and automatically inserts
/// a hyphen after the first 2 digits (`00-000000`).
class StudentIdInputFormatter extends TextInputFormatter {
  const StudentIdInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final capped = digits.length > 8 ? digits.substring(0, 8) : digits;

    // When the user types the 2nd digit forward, show `00-` immediately; when
    // backspacing over the hyphen from `00-`, let them erase the 2nd digit.
    final isDeleting = newValue.text.length < oldValue.text.length;
    final String formatted;
    if (capped.isEmpty) {
      formatted = '';
    } else if (capped.length < 2) {
      formatted = capped;
    } else if (capped.length == 2) {
      formatted = isDeleting ? capped : '$capped-';
    } else {
      formatted = '${capped.substring(0, 2)}-${capped.substring(2)}';
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
