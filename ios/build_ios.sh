#!/bin/bash

# iOS Build Script for RPS Stationery
# This script automates the iOS build process for production

set -e

echo "🚀 Starting iOS Build Process..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if we're on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    print_error "This script must be run on macOS for iOS development"
    exit 1
fi

# Check if Xcode is installed
if ! command -v xcodebuild &> /dev/null; then
    print_error "Xcode is not installed. Please install Xcode from the App Store"
    exit 1
fi

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    print_error "Flutter is not installed. Please install Flutter first"
    exit 1
fi

print_status "Cleaning project..."
flutter clean

print_status "Getting Flutter dependencies..."
flutter pub get

print_status "Installing CocoaPods dependencies..."
cd ios
pod install
cd ..

print_status "Checking iOS configuration..."
flutter doctor

print_status "Building iOS app for release..."
flutter build ios --release

print_success "iOS build completed successfully!"

print_status "Build artifacts location:"
echo "📱 App: build/ios/iphoneos/Runner.app"
echo "📦 Archive: build/ios/iphoneos/"

print_status "Next steps:"
echo "1. Open ios/Runner.xcworkspace in Xcode"
echo "2. Select your development team in Signing & Capabilities"
echo "3. Archive the app (Product > Archive)"
echo "4. Upload to App Store Connect"

print_success "iOS build process completed! 🎉"
