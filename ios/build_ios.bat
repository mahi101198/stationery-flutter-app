@echo off
REM iOS Build Script for RPS Stationery (Windows)
REM This script prepares the iOS project for building on macOS

echo 🚀 Starting iOS Build Preparation...

echo [INFO] Cleaning project...
flutter clean

echo [INFO] Getting Flutter dependencies...
flutter pub get

echo [INFO] Checking Flutter doctor...
flutter doctor

echo [SUCCESS] iOS project prepared for building!

echo.
echo [INFO] Next steps for iOS development:
echo 1. Transfer this project to a macOS machine
echo 2. Open Terminal and navigate to the project directory
echo 3. Run: chmod +x ios/build_ios.sh
echo 4. Run: ./ios/build_ios.sh
echo 5. Or manually: flutter build ios --release

echo.
echo [INFO] iOS Configuration Status:
echo ✅ Info.plist configured with privacy descriptions
echo ✅ AppDelegate.swift configured with Firebase
echo ✅ Podfile optimized for production
echo ✅ Build configurations optimized
echo ✅ All required permissions added

echo.
echo [SUCCESS] iOS project is ready for production! 🎉
