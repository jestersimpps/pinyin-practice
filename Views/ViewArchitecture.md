# View Architecture

## Overview
The view architecture has been refactored to promote reusability, consistency, and maintainability. Views are now organized into two main categories:

### 1. Screens
Main application screens that compose multiple components:
- `SetupViewRefactored` - Main menu for selecting practice options
- `PracticeViewRefactored` - Practice screen where users input pinyin
- `SettingsViewRefactored` - Settings management screen

### 2. Components
Reusable UI components organized by functionality:

#### Navigation Components
- `NavigationHeader` - Consistent header with title, subtitle, and action buttons
- `CircularIconButton` - Reusable circular button for icons

#### Button Components
- `PrimaryButton` - Main action buttons with consistent styling
- `SecondaryButton` - Secondary actions with outlined style

#### Card Components
- `SelectableCard` - Generic card for selection UI (levels, modes, themes)
- `InfoCard` - Display statistics and information
- `ToggleCard` - Settings toggles with title and subtitle
- `CharacterCard` - Display Chinese characters during practice
- `StatBubble` - Wrapper around InfoCard for backwards compatibility

#### Layout Components
- `SectionHeader` - Consistent section headers with icon and title
- `ProgressBar` - Animated progress indicator

#### Input Components
- `PinyinInputField` - Specialized text field for pinyin input
- `FeedbackMessage` - Display feedback after user input

## Benefits

1. **Reduced Code Duplication** - Common UI patterns are defined once
2. **Consistent Design** - All similar elements use the same components
3. **Easier Maintenance** - Changes to UI elements only need to be made in one place
4. **Better Testability** - Smaller, focused components are easier to test
5. **Improved Readability** - Main views focus on business logic rather than UI details

## Migration Guide

To use the new architecture:

1. Import the refactored views instead of the original ones
2. Use the component library for any new UI elements
3. Follow the established patterns for consistency

Example:
```swift
// Old way
struct MyView: View {
    var body: some View {
        Button(action: {}) {
            Text("Start")
                .font(.headline)
                .foregroundColor(.white)
                .padding()
                .background(Color.blue)
                .cornerRadius(12)
        }
    }
}

// New way
struct MyView: View {
    var body: some View {
        PrimaryButton(
            title: "Start",
            action: {}
        )
    }
}
```