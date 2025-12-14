# Timeline Biography App

A beautiful Flutter application for visualizing and organizing your life story through multiple timeline views with advanced features and production-ready architecture.

## 🌟 Features

### Core Timeline Features
- **Multiple Timeline Views**: Chronological, Clustered, Map-based, and Story views
- **Advanced Data Management**: Comprehensive event and context management with Riverpod state management
- **Responsive Navigation**: Bottom navigation with drawer support and floating action buttons
- **Configuration Controls**: Extensive settings for customizing timeline display and behavior
- **Error Handling**: Robust error handling with fallback mechanisms and user-friendly error messages

### Timeline Views
1. **Chronological View**: Traditional timeline with events sorted by date
2. **Clustered View**: Events grouped by time periods (months, years, themes)
3. **Map View**: Geographic visualization of events with location data (web-ready with fallback)
4. **Story View**: Narrative presentation of events in a story format

### Technical Features
- **Modular Architecture**: Clean separation of concerns with feature-based organization
- **State Management**: Riverpod for reactive state management with providers and notifiers
- **Template System**: Context-aware rendering with template support
- **Data Service**: Comprehensive data layer with CRUD operations, filtering, and search
- **Integration Service**: Coordinates all timeline features with caching and optimization
- **Navigation System**: Enhanced navigation with provider-based state management

## 🏗️ Architecture

The app follows **clean architecture** principles with feature-based organization:

```
lib/
├── app/                          # App-level configuration
│   ├── app.dart                  # Main app widget
│   └── navigation/               # Navigation system
│       └── main_navigation.dart  # Core navigation components
├── core/                         # Core utilities and templates
│   └── templates/                # Template management system
├── features/                     # Feature modules
│   ├── timeline/                 # Timeline feature
│   │   ├── renderers/            # Timeline view renderers
│   │   ├── screens/              # Timeline screens
│   │   ├── services/             # Timeline services
│   │   └── providers/            # Riverpod providers
│   ├── stories/                  # Stories feature
│   ├── media/                    # Media feature
│   └── settings/                 # Settings feature
├── shared/                       # Shared models and utilities
│   ├── models/                   # Data models
│   └── widgets/                  # Shared widgets
└── main.dart                     # App entry point
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
git clone https://github.com/YOUR_USERNAME/timeline-biography-app.git
cd timeline-biography-app
```

2. Install dependencies:
```bash
flutter pub get
```

3. Generate code (for data models with JSON serialization):
```bash
flutter packages pub run build_runner build --delete-conflicting-outputs
```

4. Run the app:
```bash
flutter run
```

### Platform Support

- **Android**: Full support
- **iOS**: Full support  
- **Web**: Supported (Map view has fallback UI)
- **Desktop**: Supported (requires additional configuration)

## 🧪 Testing

The project includes comprehensive testing:

```bash
# Run all tests
flutter test

# Run tests with coverage
flutter test --coverage

# Run specific test files
flutter test test/timeline_visualization_test.dart
```

### Test Coverage
- Timeline renderer tests
- Data service tests
- Integration tests
- Property-based tests for data models

## 📱 Key Components

### Timeline Engine
- **Renderer System**: Modular renderers with factory pattern
- **Data Management**: Riverpod-based state management
- **Configuration**: Extensive settings and customization
- **Error Handling**: Robust error handling with fallbacks

### Data Layer
- **Timeline Data Service**: CRUD operations, filtering, search
- **Integration Service**: Caching, optimization, event coordination
- **State Management**: Riverpod providers and notifiers

### Navigation System
- **Bottom Navigation**: Tab-based navigation
- **Drawer Navigation**: Enhanced navigation with menu
- **Floating Actions**: Context-sensitive action buttons

## 🔧 Development

### Code Generation

The project uses code generation for data models:

```bash
# Watch mode for development
flutter packages pub run build_runner watch --delete-conflicting-outputs

# One-time generation
flutter packages pub run build_runner build --delete-conflicting-outputs
```

### Building for Production

#### Android
```bash
flutter build apk --release
flutter build appbundle --release
```

#### iOS
```bash
flutter build ios --release
```

#### Web
```bash
flutter build web --release
```

## ⚙️ Configuration

### Timeline Settings
- View mode preferences
- Date range filtering
- Event type filtering
- Context selection
- Privacy settings

### Map Configuration
For map view functionality on web, configure Google Maps API:
1. Get Google Maps API key
2. Add to `web/index.html` or platform-specific configuration
3. The app includes fallback UI for web when API is not configured

## 🚀 Performance Optimizations

### Renderer Caching
- Intelligent caching of timeline renderers
- Memory-efficient renderer management
- Automatic cleanup and disposal

### State Management
- Efficient Riverpod providers
- Selective rebuilding and updates
- Stream-based reactive updates

### Memory Management
- Proper disposal of controllers and renderers
- Stream controller management
- Widget lifecycle optimization

## 🔧 Troubleshooting

### Common Issues

#### Map View Not Working on Web
- Ensure Google Maps API key is configured
- Check browser console for API errors
- The app provides fallback UI when API is unavailable

#### Build Errors
- Run `flutter clean` and `flutter pub get`
- Regenerate code with build_runner
- Check for missing dependencies

#### Performance Issues
- Check for memory leaks in renderers
- Verify proper disposal of resources
- Monitor state management efficiency

## 📋 Current Implementation Status

### ✅ Completed Features
- [x] Core timeline engine with multiple view modes
- [x] Timeline renderer system with factory pattern
- [x] Data service with CRUD operations
- [x] Integration service with caching
- [x] Navigation system with bottom tabs and drawer
- [x] Configuration controls and settings
- [x] Error handling and fallback mechanisms
- [x] State management with Riverpod
- [x] Template system for context-aware rendering
- [x] Web compatibility with map view fallback

### 🚧 Features in Progress
- [ ] Stories feature implementation
- [ ] Media library functionality
- [ ] Advanced settings and preferences
- [ ] Export/import functionality

### 📅 Planned Features
- [ ] Social timeline sharing
- [ ] Advanced visualization modes
- [ ] Offline-first sync engine
- [ ] Advanced privacy controls

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes with proper tests
4. Run tests and ensure they pass
5. Submit a pull request

### Code Style
- Follow Dart/Flutter official style guide
- Use meaningful variable and function names
- Add documentation for public APIs
- Include type annotations
- Write tests for new functionality

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

### Modern UI/UX
- **Glassmorphism Design**: Beautiful frosted glass effects with dynamic depth
- **Dark Mode**: Deep, rich dark theme with gradient backgrounds
- **Interactive Elements**: Animated cards, pulsing loaders, and smooth transitions

## 📞 Support

For support and questions:
- Create an issue in the repository
- Check the troubleshooting section
- Review the API documentation

---

Built with ❤️ for preserving memories and telling life stories.