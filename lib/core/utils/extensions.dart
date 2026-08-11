import 'package:flutter/material.dart';

extension StringExtensions on String {
  String get capitalize =>
      isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';

  String get titleCase => split(' ').map((w) => w.capitalize).join(' ');

  bool get isValidBarcode => RegExp(r'^\d{8,14}$').hasMatch(trim());
}

extension DoubleExtensions on double {
  /// Format nutrient value: show 1 decimal unless it's a whole number
  String toNutrientString() {
    if (this == truncateToDouble()) return toInt().toString();
    return toStringAsFixed(1);
  }

  /// Scale a per-100g value to a given gram amount
  double scaleToGrams(double grams) => (this * grams) / 100.0;
}

extension NullableDoubleExtensions on double? {
  String toNutrientStringOrDash() {
    if (this == null) return '—';
    return this!.toNutrientString();
  }
}

extension ContextExtensions on BuildContext {
  ThemeData get theme => Theme.of(this);
  ColorScheme get colorScheme => Theme.of(this).colorScheme;
  TextTheme get textTheme => Theme.of(this).textTheme;
  MediaQueryData get mediaQuery => MediaQuery.of(this);
  double get screenWidth => MediaQuery.of(this).size.width;
  double get screenHeight => MediaQuery.of(this).size.height;
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  void showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade700 : null,
      ),
    );
  }
}

extension DateTimeExtensions on DateTime {
  String toRelativeString() {
    final now = DateTime.now();
    final diff = now.difference(this);
    if (diff.inDays > 365) return '${(diff.inDays / 365).floor()}y ago';
    if (diff.inDays > 30) return '${(diff.inDays / 30).floor()}mo ago';
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    return 'Just now';
  }

  String toDisplayDate() {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${day} ${months[month - 1]} $year';
  }
}
