import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'asset.dart';
import 'database/asset_database.dart';
import 'constants/app_constants.dart';
import 'constants/date_format_manager.dart';
import 'utils/performance_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize performance monitoring
  PerformanceManager.initialize();
  
  // Initialize date format manager
  await DateFormatManager.initialize();
  
  // Performance optimizations
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  
  // Initialize the database when the app starts
  await AssetDatabase.instance.database;
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // Remove the debug banner
      title: AppConstants.appTitle,
      theme: ThemeData.dark(
        useMaterial3: true,
      ).copyWith(
        colorScheme: const ColorScheme.dark(
          primary: AppConstants.primaryTeal,
          secondary: AppConstants.accentTeal,
        ),
      ),
      // Go directly to AssetMenu without loading screen
      home: const AssetMenu(key: AppConstants.assetMenuKey),
      // Performance optimizations
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(1.0)),
          child: child!,
        );
      },
    );
  }
}

class MainMenu extends StatefulWidget {
  const MainMenu({super.key});

  @override
  State<MainMenu> createState() => _MainMenuState();
}

class _MainMenuState extends State<MainMenu> {
  @override
  void initState() {
    super.initState();
    // Navigate to AssetMenu after 2 seconds using const duration
    Timer(AppConstants.splashDuration, () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const AssetMenu(key: AppConstants.assetMenuKey)),
        );
      }
    });
  }

  // Function to show exit confirmation dialog
  Future<bool> _showExitConfirmDialog() async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            AppWidgets.warningIcon,
            AppWidgets.smallHorizontalSpacing,
            Text(AppConstants.exitConfirmTitle),
          ],
        ),
        content: const Text(
          AppConstants.exitConfirmMessage,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              'Cancel',
              style: AppConstants.boldTextStyle,
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.redDanger,
              foregroundColor: AppConstants.whiteColor,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Exit',
              style: AppConstants.boldTextStyle,
            ),
          ),
        ],
      ),
    ) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          final shouldExit = await _showExitConfirmDialog();
          if (shouldExit && context.mounted) {
            Navigator.of(context).pop();
          }
        }
      },
      child: Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppWidgets.appIcon,
            AppWidgets.largeSpacing,
            Text(
              AppConstants.appTitle,
              style: AppConstants.appTitleStyle,
            ),
            AppWidgets.extraLargeSpacing,
            AppWidgets.loadingIndicator,
          ],
        ),
      ),
      ),
    );
  }
}
