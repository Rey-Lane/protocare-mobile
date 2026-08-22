# Environment Configuration

This folder contains configuration files for different build environments.

## Files

- **Debug.xcconfig** - Local development configuration (points to your localhost)
- **Staging.xcconfig** - Staging/test environment
- **Release.xcconfig** - Production environment

## Setup Instructions

To use these configuration files in Xcode:

1. Open your project in Xcode
2. Select the project in the navigator
3. Go to **Build Settings**
4. Search for "Configuration"
5. Under "Use xcconfig files", select:
   - Debug → Config/Debug.xcconfig
   - Release → Config/Release.xcconfig
   - (Optional) Create Staging scheme → Config/Staging.xcconfig

## Alternative: Manual Configuration

If you prefer not to use xcconfig files, you can simply edit `Utilities/AppEnvironment.swift`:

```swift
static var current: AppEnvironment {
    // Change this line to switch environments:
    return .local(ip: "192.168.1.71")  // Your local IP
    // return .staging
    // return .production
}
```

## Changing Your Local IP

If your local IP changes, update it in:
- **Debug.xcconfig** (if using xcconfig files)
- Or `Utilities/AppEnvironment.swift` line 35 (fallback value)

## How It Works

The `AppEnvironment.current` property reads the `API_BASE_URL` from Info.plist, which is populated by the active xcconfig file. If the xcconfig isn't set up, it falls back to the hardcoded local IP.
