// Performance utility functions for the Finance Tracker app
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'app_constants.dart';

class PerformanceUtils {
  PerformanceUtils._();

  // Cached formatters for better performance
  static final Map<String, NumberFormat> _currencyFormatters = {};
  static final Map<String, DateFormat> _dateFormatters = {};
  static final Map<String, NumberFormat> _numberFormatters = {};

  // Get or create cached currency formatter
  static NumberFormat _getCurrencyFormatter(String currency, {int? decimalDigits}) {
    final locale = AppConstants.currencyLocales[currency] ?? 'en_US';
    final symbol = AppConstants.currencySymbols[currency] ?? '\$';
    final key = '$currency-$locale-${decimalDigits ?? 2}';

    return _currencyFormatters.putIfAbsent(key, () {
      if (currency == 'IDR' || currency == 'JPY') {
        return NumberFormat.currency(
          locale: locale,
          symbol: symbol,
          decimalDigits: 0,
        );
      } else {
        return NumberFormat.currency(
          locale: locale,
          symbol: symbol,
          decimalDigits: decimalDigits ?? 2,
        );
      }
    });
  }

  // Get or create cached date formatter
  static DateFormat _getDateFormatter(String pattern) {
    return _dateFormatters.putIfAbsent(pattern, () => DateFormat(pattern));
  }

  // Performance-optimized currency formatting
  static String formatCurrency(double amount, String currency) {
    final formatter = _getCurrencyFormatter(currency);
    return formatter.format(amount);
  }

  // Performance-optimized number formatting with thousand separators
  static String formatNumber(double number) {
    final formatter = _numberFormatters.putIfAbsent('number', () => NumberFormat('#,###'));
    return formatter.format(number.toInt());
  }

  // Performance-optimized date formatting
  static String formatDateTime(String? timestamp, {String pattern = 'dd/MM/yyyy - HH:mm'}) {
    if (timestamp == null) return 'Unknown';
    
    try {
      final dateTime = DateTime.parse(timestamp);
      final formatter = _getDateFormatter(pattern);
      return formatter.format(dateTime);
    } catch (e) {
      return 'Invalid date';
    }
  }

  // Performance-optimized time ago calculation
  static String getTimeAgo(String? timestamp) {
    if (timestamp == null) return '';
    
    try {
      final dateTime = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(dateTime);
      
      if (difference.inMinutes < 1) {
        return 'Just now';
      } else if (difference.inHours < 1) {
        return '${difference.inMinutes}m ago';
      } else if (difference.inDays < 1) {
        return '${difference.inHours}h ago';
      } else if (difference.inDays < 7) {
        return '${difference.inDays}d ago';
      } else if (difference.inDays < 30) {
        final weeks = (difference.inDays / 7).floor();
        return '${weeks}w ago';
      } else if (difference.inDays < 365) {
        final months = (difference.inDays / 30).floor();
        return '${months}mo ago';
      } else {
        final years = (difference.inDays / 365).floor();
        return '${years}y ago';
      }
    } catch (e) {
      return '';
    }
  }

  // Debounce utility for text input
  static Timer? _debounceTimer;
  static void debounce(VoidCallback callback, {Duration delay = const Duration(milliseconds: 500)}) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(delay, callback);
  }

  // Memory-efficient list operations
  static List<T> efficientWhere<T>(List<T> list, bool Function(T) test, {int? limit}) {
    if (limit == null) return list.where(test).toList();
    
    final result = <T>[];
    for (final item in list) {
      if (test(item)) {
        result.add(item);
        if (result.length >= limit) break;
      }
    }
    return result;
  }

  // Performance-optimized string operations
  static String truncateString(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength - 3)}...';
  }

  // Clear cached formatters when memory is needed
  static void clearFormatterCache() {
    _currencyFormatters.clear();
    _dateFormatters.clear();
    _numberFormatters.clear();
  }

  // Widget key generation for performance
  static ValueKey<String> generateWidgetKey(String prefix, dynamic id) {
    return ValueKey('$prefix-$id');
  }

  // Performance-optimized color blending
  static Color blendColors(Color color1, Color color2, double factor) {
    return Color.lerp(color1, color2, factor) ?? color1;
  }

  // Efficient asset type validation
  static bool isValidAssetType(String type) {
    return AppConstants.assetTypes.contains(type);
  }

  // Efficient currency validation
  static bool isValidCurrency(String currency) {
    return AppConstants.currencies.contains(currency);
  }
}

// Performance-optimized custom widgets
class PerformanceWidgets {
  PerformanceWidgets._();

  // Optimized ListTile with const constructor where possible
  static Widget buildOptimizedListTile({
    required String title,
    String? subtitle,
    Widget? leading,
    Widget? trailing,
    VoidCallback? onTap,
    bool enabled = true,
    Key? key,
  }) {
    return ListTile(
      key: key,
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle) : null,
      leading: leading,
      trailing: trailing,
      onTap: enabled ? onTap : null,
      enabled: enabled,
    );
  }

  // Optimized Card widget with performance considerations
  static Widget buildOptimizedCard({
    required Widget child,
    Color? borderColor,
    double elevation = AppConstants.elevationStandard,
    EdgeInsets? margin,
    EdgeInsets? padding,
    Key? key,
  }) {
    return Card(
      key: key,
      elevation: elevation,
      margin: margin ?? AppConstants.smallPadding,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        side: BorderSide(
          color: borderColor ?? Colors.transparent,
          width: borderColor != null ? 1 : 0,
        ),
      ),
      child: padding != null ? Padding(padding: padding, child: child) : child,
    );
  }

  // Optimized text field with performance considerations
  static Widget buildOptimizedTextField({
    required TextEditingController controller,
    String? labelText,
    String? hintText,
    Widget? prefixIcon,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
    int? maxLines = 1,
    bool enabled = true,
    Key? key,
  }) {
    return TextFormField(
      key: key,
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        border: const OutlineInputBorder(),
      ),
      keyboardType: keyboardType,
      validator: validator,
      onChanged: onChanged,
      maxLines: maxLines,
      enabled: enabled,
      // Performance optimization: disable spell check for performance
      enableSuggestions: false,
      autocorrect: false,
    );
  }
}
