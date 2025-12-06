# LinguaLens

An iOS app that uses OCR and AI translation to instantly translate text from images into multiple languages.

## Overview

LinguaLens allows users to capture or upload images containing text, extract the text using Optical Character Recognition (OCR), and translate it into their preferred language using AI. All translations can be saved and accessed later with full image history.

## Features

- **Camera & Photo Library Integration** - Capture images or choose from your library
- **Intelligent OCR** - Automatic text extraction with language detection (11+ languages supported)
- **AI-Powered Translation** - Leverages Groq API with Llama 3.1 for accurate translations
- **Cloud Storage** - Save translations with images to Supabase
- **Translation History** - Browse and manage previous translations
- **Multi-Language Support** - English, Spanish, French, German, Italian, Portuguese, Chinese, Japanese, Korean, Arabic, Russian
- **User Authentication** - Secure sign up/login with username or email
- **Personalization** - Set default translation language preferences
- **Copy to Clipboard** - Easy text copying for sharing
- **Full-Screen Image Viewer** - Zoom and inspect captured images

## Technology Stack

- **SwiftUI** - Modern declarative UI framework
- **Vision Framework** - Apple's OCR technology
- **Supabase** - Backend (authentication, database, storage)
- **Groq API** - AI translation service
- **Natural Language Framework** - Language detection

## Resources

### Tutorial
[Read the full tutorial on Medium](https://medium.com/@castroibon216/lingualens-tutorial-ed85e405ef55)

### Presentation
[View presentation slides](./presentation.pdf)

### Video Presentation
[Watch on YouTube](https://youtu.be/-JXxTHxnXds)

## Architecture

```
LinguaLens/
├── Services/
│   ├── OCRService.swift          # Text recognition from images
│   ├── TranslationService.swift  # AI translation integration
│   └── SupabaseManager.swift     # Backend & authentication
├── Views/
│   ├── EntryView.swift           # App entry & routing
│   ├── LoginView.swift           # Authentication UI
│   ├── HomeView.swift            # Main tab navigation
│   ├── CameraView.swift          # Image capture interface
│   ├── TranslationView.swift    # Translation interface
│   ├── HistoryView.swift         # Saved translations
│   ├── SettingsView.swift        # User preferences
│   └── SplashView.swift          # Launch screen
└── App/
    └── LinguaLensApp.swift       # App entry point    
```

## Usage

1. **Sign Up/Login** - Create an account or sign in
2. **Capture Image** - Take a photo or choose from library
3. **Extract Text** - App automatically recognizes text from image
4. **Translate** - Select target language and translate
5. **Save** - Optionally save translation to history
6. **Review** - Access saved translations anytime in History tab

## Requirements

- iOS 15.0+
- Xcode 14.0+
- Swift 5.5+
- Active internet connection for translation and cloud features

## Contact

For questions or support, please contact castroli@mail.gvsu.edu

Author: Ibon Castro Llorente  
[Linkedin](https://www.linkedin.com/in/ibon-castro/)