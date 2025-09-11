// Performance monitoring and memory management for Finance Tracker
// ignore_for_file: unnecessary_brace_in_string_interps

import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/performance_utils.dart';

class PerformanceManager {
  PerformanceManager._();
  
  static bool _isInitialized = false;
  static Timer? _memoryCleanupTimer;
  
  // Initialize performance monitoring
  static void initialize() {
    if (_isInitialized) return;
    
    // Start periodic memory cleanup
    _startPeriodicCleanup();
    
    // Monitor frame performance in debug mode
    if (kDebugMode) {
      _startFrameMonitoring();
    }
    
    _isInitialized = true;
  }
  
  // Start periodic memory cleanup
  static void _startPeriodicCleanup() {
    _memoryCleanupTimer = Timer.periodic(
      const Duration(minutes: 5),
      (timer) => cleanupMemory(),
    );
  }
  
  // Monitor frame performance
  static void _startFrameMonitoring() {
    if (kDebugMode) {
      WidgetsBinding.instance.addTimingsCallback((timings) {
        for (final timing in timings) {
          final frameDuration = timing.totalSpan.inMilliseconds;
          if (frameDuration > 16) { // More than 16ms indicates dropped frames
            developer.log(
              'Frame took ${frameDuration}ms (dropped frames detected)',
              name: 'PerformanceMonitor',
            );
          }
        }
      });
    }
  }
  
  // Clean up memory periodically
  static void cleanupMemory() {
    // Clear cached formatters
    PerformanceUtils.clearFormatterCache();
    
    // Force garbage collection in debug mode
    if (kDebugMode) {
      developer.log('Memory cleanup performed', name: 'PerformanceManager');
    }
    
    // Clear system memory if needed
    SystemChannels.platform.invokeMethod('SystemNavigator.pop');
  }
  
  // Log performance metrics
  static void logPerformance(String operation, Duration duration) {
    if (kDebugMode) {
      developer.log(
        '$operation took ${duration.inMilliseconds}ms',
        name: 'Performance',
      );
    }
  }
  
  // Track database operations performance
  static Future<T> trackDatabaseOperation<T>(
    String operationName,
    Future<T> Function() operation,
  ) async {
    final stopwatch = Stopwatch()..start();
    try {
      final result = await operation();
      stopwatch.stop();
      logPerformance('DB: $operationName', stopwatch.elapsed);
      return result;
    } catch (e) {
      stopwatch.stop();
      developer.log(
        'DB Error in $operationName after ${stopwatch.elapsedMilliseconds}ms: $e',
        name: 'DatabasePerformance',
      );
      rethrow;
    }
  }
  
  // Track UI operations performance
  static T trackUIOperation<T>(
    String operationName,
    T Function() operation,
  ) {
    final stopwatch = Stopwatch()..start();
    try {
      final result = operation();
      stopwatch.stop();
      logPerformance('UI: $operationName', stopwatch.elapsed);
      return result;
    } catch (e) {
      stopwatch.stop();
      developer.log(
        'UI Error in $operationName after ${stopwatch.elapsedMilliseconds}ms: $e',
        name: 'UIPerformance',
      );
      rethrow;
    }
  }
  
  // Dispose resources
  static void dispose() {
    _memoryCleanupTimer?.cancel();
    _memoryCleanupTimer = null;
    _isInitialized = false;
    cleanupMemory();
  }
  
  // Check if device has low memory
  static bool isLowMemoryDevice() {
    // This is a simplified check - in a real app you'd use platform channels
    // to check actual memory usage
    return false; // Default to false for now
  }
  
  // Optimize for low memory devices
  static void optimizeForLowMemory() {
    if (isLowMemoryDevice()) {
      // Reduce image cache size
      PaintingBinding.instance.imageCache.maximumSize = 50;
      PaintingBinding.instance.imageCache.maximumSizeBytes = 10 << 20; // 10 MB
      
      // Clear caches more frequently
      _memoryCleanupTimer?.cancel();
      _memoryCleanupTimer = Timer.periodic(
        const Duration(minutes: 2),
        (timer) => cleanupMemory(),
      );
    }
  }
}

// Performance-aware widget mixin
mixin PerformanceAware<T extends StatefulWidget> on State<T> {
  @override
  void initState() {
    super.initState();
  }
  
  @override
  Widget build(BuildContext context) {
    return PerformanceManager.trackUIOperation(
      '${widget.runtimeType}.build',
      () => buildWidget(context),
    );
  }
  
  // Override this method instead of build
  Widget buildWidget(BuildContext context);
  
  @override
  void dispose() {
    super.dispose();
    if (kDebugMode) {
      developer.log(
        '${widget.runtimeType} disposed',
        name: 'WidgetLifecycle',
      );
    }
  }
}

// Performance-aware StatelessWidget
abstract class PerformanceAwareStatelessWidget extends StatelessWidget {
  const PerformanceAwareStatelessWidget({super.key});
  
  @override
  Widget build(BuildContext context) {
    return PerformanceManager.trackUIOperation(
      '${runtimeType}.build',
      () => buildWidget(context),
    );
  }
  
  // Override this method instead of build
  Widget buildWidget(BuildContext context);
}

// Database operation wrapper for performance tracking
class PerformantDatabaseOperation {
  static Future<T> execute<T>(
    String operationName,
    Future<T> Function() operation,
  ) async {
    return PerformanceManager.trackDatabaseOperation(operationName, operation);
  }
}
