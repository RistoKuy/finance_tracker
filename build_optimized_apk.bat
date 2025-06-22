@echo off
echo Building optimized APK for Finance Tracker...
echo.

REM Clean the project first
echo Cleaning previous builds...
flutter clean

REM Get dependencies
echo Getting dependencies...
flutter pub get

REM Build the release APK with optimization flags
echo Building optimized release APK...
flutter build apk --release --split-per-abi --obfuscate --split-debug-info=./debug-info

echo.
echo Build completed! The optimized APK can be found in:
echo build\app\outputs\flutter-apk\
echo.
echo The following APKs were created:
echo - app-armeabi-v7a-release.apk (for older 32-bit devices)
echo - app-arm64-v8a-release.apk (for modern 64-bit devices)
echo - app-x86_64-release.apk (for x86_64 devices)
echo.
echo Install the appropriate APK based on your device architecture.
echo For most modern phones, use the arm64-v8a version.
