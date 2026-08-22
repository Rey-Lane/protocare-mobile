# Setup Test Target in Xcode

The test files are created and ready. Follow these steps to add them to your Xcode project:

## Step 1: Create Test Target

1. Open `Protocare.xcodeproj` in Xcode
2. Select the project in the navigator (top item)
3. Click the **+** button at the bottom of the Targets list
4. Select **iOS** → **Unit Testing Bundle**
5. Configure:
   - **Product Name**: ProtocareTests
   - **Team**: Your team (or None)
   - **Organization**: Your name
   - **Language**: Swift
   - **Include UI Tests**: Unchecked
6. Click **Finish**

## Step 2: Add Test Files

1. In the Project navigator, find the new `ProtocareTests` folder
2. Delete the auto-generated `ProtocareTests.swift` file
3. Right-click on ProtocareTests folder → **Add Files to "Protocare"**
4. Navigate to and select all files in:
   - `ProtocareTests/Mocks/`
   - `ProtocareTests/Utils/`
   - `ProtocareTests/Extensions/`
   - `ProtocareTests/ViewModels/`
5. Ensure **"Copy items if needed"** is checked
6. Ensure **"Add to targets"** has **ProtocareTests** selected
7. Click **Add**

## Step 3: Configure Target Dependencies

1. Select the **ProtocareTests** target
2. Go to **Build Phases** tab
3. Expand **Target Dependencies**
4. Click **+** and add **Protocare** target

## Step 4: Import App Module

1. Select **ProtocareTests** target
2. Go to **Build Settings** tab
3. Search for **"Test Host"**
4. Set it to: `$(BUILT_PRODUCTS_DIR)/Protocare.app/Protocare`
5. Search for **"Bundle Loader"**
6. Set it to: `$(TEST_HOST)`

## Step 5: Run Tests

### In Xcode:
- Press **Cmd+U** to run all tests
- Or go to **Product** → **Test**

### From Command Line:
```bash
cd /Users/alex/Pets/protocare_mobile/Protocare
xcodebuild -scheme Protocare -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 17' test
```

## Test Files Created

✅ **Mocks/**:
- MockAuthAPI.swift - Configurable API mock
- MockAuthStore.swift - Auth state mock

✅ **Utils/**:
- TestFixtures.swift - Sample test data

✅ **Extensions/**:
- StringValidationTests.swift - Email validation
- DoubleFormattingTests.swift - Number formatting
- ActionItemEnrichmentTests.swift - Substance resolution

✅ **ViewModels/**:
- LoginViewModelTests.swift - Login flow tests

## Troubleshooting

**"No such module 'Protocare'" error:**
- Make sure @testable import is used in test files
- Clean build folder (Cmd+Shift+K) and rebuild

**Tests not appearing in Test Navigator:**
- Cmd+U to build and discover tests
- Check that test files are added to ProtocareTests target

**Build errors:**
- Ensure Protocare target builds successfully first
- Check that all test files have "Target Membership" set to ProtocareTests
