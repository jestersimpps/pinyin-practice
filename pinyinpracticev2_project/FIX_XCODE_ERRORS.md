# Fixing Xcode Build Errors

## Issue: Test files are in the wrong target

### Solution:

1. **Remove Test Files from Main Target:**
   - In Xcode, select each test file (files ending in `Tests.swift`)
   - In the File Inspector (right panel), under "Target Membership"
   - Uncheck "pinyingpracticev2" (main app target)
   - Check "pinyingpracticev2Tests" (test target)

   Files to move:
   - `InputValidatorTests.swift`
   - `ChapterIdentifierTests.swift`
   - `WordLoaderTests.swift`
   - `StorageServiceTests.swift`

2. **Alternative: Delete Test Files (if not needed yet):**
   - Select all test files
   - Right-click > Delete
   - Choose "Move to Trash"

3. **If you see other import errors, add missing files:**

## Common Missing Files

If you see errors about missing types, here are the files you might need to add: