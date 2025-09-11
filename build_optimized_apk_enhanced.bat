@echo off
REM Performance-optimized build script for Finance Tracker
REM This script builds the app with all performance optimizations enabled

echo Building Finance Tracker with performance optimizations...

REM Clean previous builds
echo Cleaning previous builds...
flutter clean

REM Get dependencies
echo Getting dependencies...
flutter pub get

REM Build optimized APK for release
echo Building optimized release APK...
flutter build apk --release ^
  --shrink ^
  --obfuscate ^
  --split-debug-info=build/app/outputs/symbols ^
  --target-platform android-arm,android-arm64,android-x64 ^
  --analyze-size

echo.
echo Build completed successfully!
echo.
echo Optimizations applied:
echo - Code shrinking enabled
echo - Code obfuscation enabled  
echo - Debug info separated for smaller APK size
echo - Multi-architecture support
echo - Size analysis enabled
echo.
echo APK location: build\app\outputs\flutter-apk\app-release.apk
echo.
pause
