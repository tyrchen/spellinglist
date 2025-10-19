# Setup Instructions for Vocabulary Quiz App

## Adding New Files to Xcode Project

The following Swift files have been created and need to be added to your Xcode project:

1. **Models.swift** - Data models and quiz session logic
2. **OCRService.swift** - OCR and text extraction service
3. **VocabularyParser.swift** - Text parsing logic
4. **FileUploadView.swift** - File upload interface
5. **HomeView.swift** - Main home screen
6. **QuizView.swift** - Quiz interface with gamification
7. **SettingsView.swift** - App settings

### Steps to Add Files to Xcode:

1. Open `spellinglist.xcodeproj` in Xcode
2. In the Project Navigator (left sidebar), right-click on the `spellinglist` folder
3. Select "Add Files to spellinglist..."
4. Navigate to the `spellinglist` folder
5. Select all the new `.swift` files listed above
6. Make sure "Copy items if needed" is **unchecked** (files are already in the correct location)
7. Make sure "Add to targets: spellinglist" is **checked**
8. Click "Add"

### Alternative Method (Drag and Drop):

1. Open Finder and navigate to the `spellinglist` folder
2. Open `spellinglist.xcodeproj` in Xcode
3. Drag the new `.swift` files from Finder into the Project Navigator under the `spellinglist` group
4. In the dialog that appears:
   - **Uncheck** "Copy items if needed"
   - **Check** "Add to targets: spellinglist"
   - Click "Finish"

## Verification

After adding the files, build the project (Cmd+B) to ensure everything compiles correctly.

### Expected Files in Project:

```
spellinglist/
├── spellinglistApp.swift      ✓ (Already in project)
├── ContentView.swift           ✓ (Already in project, modified)
├── Models.swift                ← ADD THIS
├── OCRService.swift            ← ADD THIS
├── VocabularyParser.swift      ← ADD THIS
├── FileUploadView.swift        ← ADD THIS
├── HomeView.swift              ← ADD THIS
├── QuizView.swift              ← ADD THIS
├── SettingsView.swift          ← ADD THIS
└── Assets.xcassets             ✓ (Already in project)
```

## Build Issues

If you encounter any build errors after adding the files:

1. **Clean Build Folder**: Product → Clean Build Folder (Cmd+Shift+K)
2. **Rebuild**: Product → Build (Cmd+B)
3. Check that all files show in the Project Navigator without red text
4. Verify the target membership for each file in the File Inspector (right sidebar)

## Testing the App

Once the project builds successfully:

1. Select a simulator (iPhone 15 recommended)
2. Click the Run button or press Cmd+R
3. The app should launch showing an empty state screen
4. Tap the "+" button to upload a vocabulary list
5. Test with a PDF or image containing word-definition pairs

### Sample Test Format:

Create a test document with content like:

```
Abundant - Present in great quantity
Benevolent - Well-meaning and kindly
Candid - Truthful and straightforward
Diligent - Having care in one's work
```

Or in numbered format:

```
1. Abundant - Present in great quantity
2. Benevolent - Well-meaning and kindly
3. Candid - Truthful and straightforward
4. Diligent - Having care in one's work
```

## Features to Test

- [ ] Upload PDF file
- [ ] Upload image from Photos
- [ ] Review extracted words
- [ ] Start a quiz
- [ ] Answer questions
- [ ] Hear sound effects
- [ ] Complete quiz and see score
- [ ] Practice missed words (second chance round)
- [ ] View statistics on home screen
- [ ] Delete vocabulary sets
- [ ] Adjust settings

## Troubleshooting

### "No such module 'SwiftData'"
- Ensure deployment target is iOS 17.0 or later
- Check in Project Settings → General → Minimum Deployments

### Files appear in red in Project Navigator
- Files are not properly added to the project
- Try removing and re-adding them

### Build succeeds but app crashes on launch
- Check the console for error messages
- Verify SwiftData model container is set up correctly in spellinglistApp.swift

## Next Steps

After successfully building and testing:

1. Test with real vocabulary lists
2. Verify OCR accuracy with different fonts and layouts
3. Customize sound effects or add custom audio files
4. Adjust UI colors and styling to preference
5. Consider implementing additional features from the roadmap
