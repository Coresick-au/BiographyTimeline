# Users Timeline

A collaborative digital historiography platform that transforms personal photo collections into rich, interactive timelines with narrative storytelling capabilities.

## 🌟 Features

- **Automated Timeline Creation**: Extracts EXIF data from photos to build chronological timelines without manual date entry
- **Intelligent Event Clustering**: Groups photos by temporal and spatial proximity into meaningful events
- **Rich Storytelling**: Scrollytelling interface for creating narrative content with embedded media
- **Polymorphic Context System**: Support for personal biographies, pet growth tracking, home renovations, and business projects
- **Social Timeline Merging**: Connect with others to view shared history through "River Visualization"
- **Privacy-First Design**: Granular privacy controls with end-to-end encryption for sensitive content
- **Offline-First Architecture**: Full functionality without internet connectivity with seamless sync

## 🏗️ Architecture

The app follows a **feature-based architecture** with offline-first design principles:

```
lib/
├── features/
│   ├── timeline/     # Timeline visualization and management
│   ├── stories/      # Rich story creation and scrollytelling
│   ├── context/      # Polymorphic context management
│   ├── media/        # Photo import and EXIF processing
│   └── demo/         # Demo and examples
├── shared/           # Cross-feature shared code
├── core/             # Shared utilities and base classes
└── app/              # App-level configuration
```

## 🚀 Getting Started

### Prerequisites

- Flutter 3.x or later
- Dart SDK
- Android Studio / VS Code
- iOS development setup (for iOS builds)

### Installation

1. Clone the repository:
```bash
git clone https://github.com/YOUR_USERNAME/users-timeline-app.git
cd users-timeline-app
```

2. Install dependencies:
```bash
flutter pub get
```

3. Generate code (for data models):
```bash
flutter packages pub run build_runner build
```

4. Run the app:
```bash
flutter run
```

## 🧪 Testing

The project includes comprehensive property-based testing:

```bash
# Run all tests
flutter test

# Run property-based tests specifically
flutter test test/property_tests/

# Run with coverage
flutter test --coverage
```

### Property-Based Testing

The app uses property-based testing to verify correctness across all possible inputs:

- **EXIF Processing**: Validates metadata extraction for any image
- **Event Clustering**: Tests temporal and spatial grouping algorithms
- **Story Editor**: Verifies rich text editing and media embedding
- **Scrollytelling**: Tests synchronization of narrative and media
- **Context Management**: Validates polymorphic rendering system

## 📱 Key Components

### Timeline Engine
- Polymorphic timeline system supporting multiple contexts
- Intelligent photo clustering with configurable thresholds
- Fuzzy date support for uncertain timestamps

### Story Editor
- Rich text editing with Flutter Quill
- Media embedding (photos, videos, audio)
- Auto-save with version control
- Scrollytelling with dynamic backgrounds

### Context System
- Person, Pet, Project, Business timeline types
- Context-specific UI themes and widgets
- Polymorphic custom attributes (JSON storage)

## 🔧 Development

### Code Generation

The project uses code generation for data models:

```bash
# Watch mode for development
flutter packages pub run build_runner watch

# One-time generation
flutter packages pub run build_runner build
```

### Project Structure

- **Feature-based architecture** with clear separation of concerns
- **Repository pattern** for data access abstraction
- **Riverpod** for state management
- **Property-based testing** for correctness validation

## 📋 Roadmap

- [x] Core timeline engine with polymorphic contexts
- [x] Photo import and EXIF processing
- [x] Event clustering algorithms
- [x] Rich story editor with scrollytelling
- [x] Context management system
- [ ] Social features and timeline merging
- [ ] Privacy and security framework
- [ ] Offline-first sync engine
- [ ] Advanced visualization modes
- [ ] Ghost Camera for progress comparison

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- Property-based testing community for correctness insights
- Digital historiography researchers for domain expertise