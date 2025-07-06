# PinyinPractice V2 - Xcode Project Setup Instructions

## Creating the New Project

1. **Open Xcode** and create a new project:
   - Choose **iOS** → **App**
   - Product Name: `PinyinPracticeV2`
   - Team: Select your team
   - Organization Identifier: Your identifier (e.g., `com.yourname`)
   - Interface: **SwiftUI**
   - Language: **Swift**
   - Use Core Data: **NO**
   - Include Tests: Optional

2. **Project Settings**:
   - Minimum Deployments: **iOS 17.0** (or higher)
   - Supported Destinations: iPhone, iPad

## Adding Files to the Project

1. **Delete Default Files**:
   - Delete the default `ContentView.swift` (we'll replace it)
   - Delete the default `PinyinPracticeV2App.swift` (we'll replace it)

2. **Add All Files**:
   - Right-click on the project navigator
   - Select "Add Files to PinyinPracticeV2..."
   - Navigate to this folder and select the `PinyinPracticeV2` folder
   - **IMPORTANT**: 
     - UNCHECK "Copy items if needed" (files are already in place)
     - CHECK "Create groups" (not folder references)
     - CHECK your app target
   - Click "Add"

3. **Verify File Structure**:
   Your project navigator should show:
   ```
   PinyinPracticeV2
   ├── pinyingpracticev2App.swift
   ├── ContentView.swift
   ├── DependencyInjection/
   ├── Models/
   ├── Views/
   │   ├── Screens/
   │   └── Components/
   ├── ViewModels/
   ├── Services/
   ├── Utilities/
   ├── Resources/
   │   ├── Assets.xcassets
   │   └── Data/
   └── Preview Content/
   ```

## Build Settings

1. **Add Build Phases for Resources**:
   - Select your project → Select target → Build Phases
   - Expand "Copy Bundle Resources"
   - Make sure all `.json` files are included
   - If not, click "+" and add them

2. **Info.plist Settings**:
   Add these keys if needed:
   - `UILaunchScreen`: Dictionary with background color
   - `UISupportedInterfaceOrientations`: Portrait orientations
   - `UIRequiresFullScreen`: YES (if iPad support needed)

## Running the Project

1. **Clean Build Folder**: Product → Clean Build Folder (⇧⌘K)
2. **Build**: Product → Build (⌘B)
3. **Run**: Select a simulator and run (⌘R)

## Troubleshooting

### If you get "Cannot find type" errors:
- Make sure all files are added to the correct target
- Check file inspector → Target Membership

### If you get "No such module" errors:
- Clean build folder and rebuild
- Check that all files are in the correct groups

### If resources aren't loading:
- Verify JSON files are in "Copy Bundle Resources"
- Check file paths in VocabularyLoader.swift

## Project Organization

- **Models**: Data structures and types
- **Views**: All UI components
  - **Screens**: Full-screen views
  - **Components**: Reusable UI components
- **ViewModels**: Business logic for views
- **Services**: Data management and business logic
- **Utilities**: Helper functions and extensions
- **DependencyInjection**: DI container setup
- **Resources**: Assets and data files

## Notes

- The app uses dependency injection via DIContainer
- All services are initialized through the DI container
- The app follows MVVM architecture
- UserDefaults is used for persistence