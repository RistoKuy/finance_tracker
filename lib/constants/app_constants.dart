// Performance-optimized constants for the Finance Tracker app
// Using const constructors to prevent unnecessary rebuilds

import 'package:flutter/material.dart';

class AppConstants {
  // Private constructor to prevent instantiation
  AppConstants._();

  // App Colors - const for performance
  static const Color primaryTeal = Colors.teal;
  static const Color accentTeal = Colors.tealAccent;
  static const Color purpleColor = Colors.purple;
  static const Color orangeWarning = Colors.orange;
  static const Color redDanger = Colors.red;
  static const Color greenSuccess = Colors.green;
  static const Color blueInfo = Colors.blue;
  static const Color amberWarning = Colors.amber;
  static const Color whiteColor = Colors.white;

  // Text Styles - const for performance
  static const TextStyle appTitleStyle = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: whiteColor,
  );

  static const TextStyle boldTextStyle = TextStyle(
    fontWeight: FontWeight.bold,
  );

  static const TextStyle currencySymbolStyle = TextStyle(
    fontSize: 16,
  );

  static const TextStyle labelTextStyle = TextStyle(
    fontWeight: FontWeight.w500,
  );

  // Padding and Margins - const for performance
  static const EdgeInsets standardPadding = EdgeInsets.all(16.0);
  static const EdgeInsets smallPadding = EdgeInsets.all(8.0);
  static const EdgeInsets dialogPadding = EdgeInsets.symmetric(horizontal: 12, vertical: 15);
  static const EdgeInsets listItemPadding = EdgeInsets.symmetric(horizontal: 16, vertical: 10);
  static const EdgeInsets bottomPadding = EdgeInsets.only(bottom: 80);

  // Sizes - const for performance
  static const double iconSizeLarge = 80.0;
  static const double iconSizeStandard = 24.0;
  static const double spacingSmall = 8.0;
  static const double spacingMedium = 16.0;
  static const double spacingLarge = 24.0;
  static const double spacingXLarge = 48.0;
  static const double borderRadius = 12.0;
  static const double elevationStandard = 3.0;

  // Asset type configurations - immutable for performance
  static const Map<String, Color> typeColors = {
    'Transactional': blueInfo,
    'Savings': greenSuccess,
    'Investment': amberWarning,
  };

  static const Map<String, IconData> typeIcons = {
    'Transactional': Icons.account_balance_wallet,
    'Savings': Icons.savings,
    'Investment': Icons.trending_up,
  };

  // Change type configurations - immutable for performance
  static const Map<String, Color> changeColors = {
    'CREATE': greenSuccess,
    'UPDATE': blueInfo,
    'DELETE': redDanger,
    'BULK_DELETE': Colors.redAccent,
  };

  static const Map<String, IconData> changeIcons = {
    'CREATE': Icons.add_circle,
    'UPDATE': Icons.edit,
    'DELETE': Icons.delete,
    'BULK_DELETE': Icons.delete_sweep,
  };

  // Currency configurations - immutable for performance
  static const Map<String, String> currencySymbols = {
    'USD': '\$',
    'EUR': '€',
    'JPY': '¥',
    'IDR': 'Rp',
  };

  static const Map<String, String> currencyLocales = {
    'USD': 'en_US',
    'EUR': 'de_DE',
    'JPY': 'ja_JP',
    'IDR': 'id_ID',
  };

  // Durations - const for performance
  static const Duration splashDuration = Duration(seconds: 2);
  static const Duration animationDuration = Duration(milliseconds: 300);
  
  // Filter configurations
  static const List<String> filterOptions = ['ALL', 'CREATE', 'UPDATE', 'DELETE', 'BULK_DELETE'];
  
  static const Map<String, String> filterLabels = {
    'ALL': 'All Changes',
    'CREATE': 'Created',
    'UPDATE': 'Updated',
    'DELETE': 'Deleted',
    'BULK_DELETE': 'Bulk Deleted',
  };

  // Asset types
  static const List<String> assetTypes = ['Transactional', 'Savings', 'Investment'];
  static const List<String> currencies = ['USD', 'EUR', 'JPY', 'IDR'];

  // Date format configurations
  static const String europeanDateFormat = 'dd/MM/yyyy - HH:mm';
  static const String americanDateFormat = 'MMM d, yyyy - h:mm a';
  static const String defaultDateFormat = europeanDateFormat;
  
  static const Map<String, String> dateFormatLabels = {
    europeanDateFormat: 'European Format (24-hour)',
    americanDateFormat: 'American Format (12-hour)',
  };

  // Widget keys for performance optimization
  static const Key mainMenuKey = ValueKey('mainMenu');
  static const Key assetMenuKey = ValueKey('assetMenu');
  static const Key historyScreenKey = ValueKey('historyScreen');

  // App strings - const for performance
  static const String appTitle = 'Finance Tracker';
  static const String exitConfirmTitle = 'Exit App';
  static const String exitConfirmMessage = 'Are you sure you want to exit the Finance Tracker app?';
  static const String exitConfirmMessageWithSave = 'Are you sure you want to exit the Finance Tracker app?\n\nYour data will be saved automatically.';
}

// Performance-optimized widgets as separate classes
class AppWidgets {
  AppWidgets._();

  // Reusable const widgets to prevent rebuilds
  static const Widget loadingIndicator = Center(
    child: CircularProgressIndicator(
      color: AppConstants.whiteColor,
    ),
  );

  static const Widget standardLoadingIndicator = Center(
    child: CircularProgressIndicator(),
  );

  static const SizedBox smallSpacing = SizedBox(height: AppConstants.spacingSmall);
  static const SizedBox mediumSpacing = SizedBox(height: AppConstants.spacingMedium);
  static const SizedBox largeSpacing = SizedBox(height: AppConstants.spacingLarge);
  static const SizedBox extraLargeSpacing = SizedBox(height: AppConstants.spacingXLarge);

  static const SizedBox smallHorizontalSpacing = SizedBox(width: AppConstants.spacingSmall);
  static const SizedBox mediumHorizontalSpacing = SizedBox(width: AppConstants.spacingMedium);

  // App Icon widget - const for performance
  static const Widget appIcon = Icon(
    Icons.account_balance,
    size: AppConstants.iconSizeLarge,
    color: AppConstants.whiteColor,
  );

  // Standard divider
  static const Divider standardDivider = Divider(height: 1);

  // Warning icon for dialogs
  static const Icon warningIcon = Icon(
    Icons.warning_amber,
    color: AppConstants.orangeWarning,
  );
  
  // Settings icon
  static const Icon settingsIcon = Icon(
    Icons.settings,
    color: AppConstants.whiteColor,
  );
}
