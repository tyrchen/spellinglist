# Vocabulary Quiz Generator

An intelligent iOS educational app that helps students efficiently learn and retain vocabulary through automated quiz generation from uploaded documents. My wife did it after I taught her how to generate iPhone app using claude code (with some of my help).

English | [简体中文](./README-zh.md)

![screenshot](./docs/images/screenshot.jpg)

## Features

### Smart Content Extraction

- Upload PDF or image files containing vocabulary lists
- OCR technology extracts text from documents
- Intelligent parsing recognizes word-definition pairs in multiple formats:
  - "word - definition" or "word: definition"
  - Numbered lists (1. word - definition)
  - Multi-line format (word on one line, definition on next)
  - Custom separator support

### Interactive Quiz System

- Automatically generates multiple-choice questions
- Randomized answer options to prevent position memorization
- Progress tracking with visual progress bar
- Real-time score display
- Swipe-to-delete vocabulary sets

### Gamified Learning Experience

- Instant visual feedback (green for correct, red for incorrect)
- System sound effects for correct/incorrect answers
- Haptic feedback for enhanced engagement
- Trophy display on quiz completion
- Performance percentage display

### Second-Chance Learning

- Automatically tracks incorrectly answered words
- Optional second-chance rounds focus on missed vocabulary
- Helps reinforce weak areas through targeted practice

### Data Persistence

- SwiftData integration for local storage
- Vocabulary sets saved automatically
- Track statistics for each word (times correct/incorrect)
- View accuracy percentage per vocabulary set

### Customization & Settings

- Adjustable number of answer options (2-6)
- Toggle sound effects on/off
- Toggle haptic feedback on/off
- Dark mode support
- Accessibility features

## Technical Architecture

### Technologies Used

- **SwiftUI**: Modern declarative UI framework
- **SwiftData**: Data persistence and management
- **Vision Framework**: OCR text recognition from images
- **PDFKit**: PDF text extraction and rendering
- **AVFoundation**: Audio feedback system
- **UIKit Integration**: Document picker and photo picker

### Project Structure

```
spellinglist/
├── Models.swift              # Data models (VocabularyWord, VocabularySet, QuizSession)
├── OCRService.swift          # OCR and text extraction service
├── VocabularyParser.swift    # Text parsing logic for word-definition pairs
├── FileUploadView.swift      # Document/image upload interface
├── HomeView.swift            # Main screen with vocabulary sets list
├── QuizView.swift            # Quiz interface with gamification
├── SettingsView.swift        # App settings and preferences
├── ContentView.swift         # Root view
└── spellinglistApp.swift     # App entry point
```

### Key Components

#### Models

- **VocabularyWord**: Individual word with definition and statistics
- **VocabularySet**: Collection of words from a single document
- **QuizQuestion**: Question structure with options and correct answer
- **QuizSession**: Observable object managing quiz state and logic

#### Services

- **OCRService**: Handles text extraction from images and PDFs using Vision framework
- **VocabularyParser**: Smart parsing with pattern recognition for various formats

## How to Use

1. **Add Vocabulary**
   - Tap the "+" button in the top right
   - Choose to upload from Photos or select a PDF file
   - Review the extracted words
   - Edit or delete any incorrectly parsed entries
   - Save the vocabulary set

2. **Take a Quiz**
   - Tap on any vocabulary set from the home screen
   - Read the word and select the correct definition
   - Receive instant feedback on your answer
   - Progress through all questions

3. **Practice Missed Words**
   - After completing a quiz, review your score
   - If you missed any words, tap "Practice Missed Words"
   - Complete a second-chance round with only the words you got wrong

4. **Track Progress**
   - View accuracy percentages on the home screen
   - See total attempts for each vocabulary set
   - Monitor improvement over time

## Requirements

- iOS 17.0 or later
- Xcode 15.0 or later
- Swift 5.9 or later

## Building the Project

1. Open `spellinglist.xcodeproj` in Xcode
2. Select your target device or simulator
3. Press Cmd+R to build and run

## Future Enhancements

- [ ] Synonym/antonym integration
- [ ] Progress analytics dashboard for parents and teachers
- [ ] Multiplayer or challenge mode for classroom engagement
- [ ] Cloud sync across devices
- [ ] Export quiz results
- [ ] Custom quiz modes (reverse, matching, fill-in-the-blank)
- [ ] Spaced repetition algorithm
- [ ] Voice pronunciation for words
- [ ] Dark mode theme customization

## Privacy

- All data is stored locally on device using SwiftData
- No user data is transmitted to external servers
- OCR processing happens on-device using Apple's Vision framework
- No account or login required

## License

Copyright © 2025. All rights reserved.

## Support

For issues or feature requests, please contact the developer or open an issue on GitHub.
