# Fix: Remove Test Files from Main Target

Since the test files are causing build errors, let's remove them for now:

## In Xcode:

1. **Select the "Tests" folder** in the project navigator (the folder shown in your screenshot)

2. **Right-click** on the Tests folder

3. **Select "Delete"**

4. **Choose "Move to Trash"** (not just remove references)

5. **Clean Build Folder**: Press `Cmd+Shift+K`

6. **Build again**: Press `Cmd+B`

This will remove all the test files that are causing the "No such module 'XCTest'" error.

## Alternative: If you want to keep the tests for later

1. Select the Tests folder
2. In the right panel (File Inspector)
3. Under "Target Membership", uncheck "pinyingpracticev2"
4. The folder should turn red/gray indicating it's not part of the build

The tests are meant for unit testing and should only be in the test target, not the main app target.