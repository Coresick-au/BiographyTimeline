import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service managing onboarding flow and user preferences
/// Tracks which onboarding steps have been completed
class OnboardingService {
  static OnboardingService? _instance;
  static OnboardingService get instance => _instance ??= OnboardingService._();
  
  OnboardingService._();

  static const String _onboardingCompleteKey = 'onboarding_complete';
  static const String _welcomeSeenKey = 'welcome_seen';
  static const String _privacyAcceptedKey = 'privacy_accepted';
  static const String _featuresShownKey = 'features_shown';
  static const String _tutorialCompletedKey = 'tutorial_completed';

  SharedPreferences? _prefs;
  final StreamController<OnboardingState> _stateController = 
      StreamController<OnboardingState>.broadcast();

  // =========================================================================
  // PUBLIC API
  // =========================================================================

  /// Initialize onboarding service
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    _notifyStateChange();
  }

  /// Get current onboarding state
  OnboardingState get currentState {
    if (_prefs == null) return OnboardingState.notStarted;
    
    final complete = _prefs!.getBool(_onboardingCompleteKey) ?? false;
    if (complete) return OnboardingState.completed;
    
    final welcome = _prefs!.getBool(_welcomeSeenKey) ?? false;
    if (!welcome) return OnboardingState.welcome;
    
    final privacy = _prefs!.getBool(_privacyAcceptedKey) ?? false;
    if (!privacy) return OnboardingState.privacy;
    
    final features = _prefs!.getBool(_featuresShownKey) ?? false;
    if (!features) return OnboardingState.features;
    
    final tutorial = _prefs!.getBool(_tutorialCompletedKey) ?? false;
    if (!tutorial) return OnboardingState.tutorial;
    
    return OnboardingState.completed;
  }

  /// Mark welcome step as complete
  Future<void> completeWelcome() async {
    await _prefs?.setBool(_welcomeSeenKey, true);
    _notifyStateChange();
  }

  /// Accept privacy policy
  Future<void> acceptPrivacyPolicy() async {
    await _prefs?.setBool(_privacyAcceptedKey, true);
    _notifyStateChange();
  }

  /// Mark features overview as complete
  Future<void> completeFeaturesOverview() async {
    await _prefs?.setBool(_featuresShownKey, true);
    _notifyStateChange();
  }

  /// Mark tutorial as complete
  Future<void> completeTutorial() async {
    await _prefs?.setBool(_tutorialCompletedKey, true);
    await _prefs?.setBool(_onboardingCompleteKey, true);
    _notifyStateChange();
  }

  /// Skip onboarding (for returning users)
  Future<void> skipOnboarding() async {
    await _prefs?.setBool(_onboardingCompleteKey, true);
    _notifyStateChange();
  }

  /// Reset onboarding (for testing or re-onboarding)
  Future<void> resetOnboarding() async {
    await _prefs?.clear();
    _notifyStateChange();
  }

  /// Check if specific feature hint should be shown
  Future<bool> shouldShowFeatureHint(String featureId) async {
    final key = 'hint_shown_$featureId';
    return !(_prefs?.getBool(key) ?? false);
  }

  /// Mark feature hint as shown
  Future<void> markFeatureHintShown(String featureId) async {
    final key = 'hint_shown_$featureId';
    await _prefs?.setBool(key, true);
  }

  /// Stream of onboarding state changes
  Stream<OnboardingState> get stateStream => _stateController.stream;

  // =========================================================================
  // PRIVATE METHODS
  // =========================================================================

  void _notifyStateChange() {
    _stateController.add(currentState);
  }

  // =========================================================================
  // DISPOSE
  // =========================================================================

  Future<void> dispose() async {
    await _stateController.close();
  }
}

// =========================================================================
// DATA MODELS
// =========================================================================

enum OnboardingState {
  notStarted,
  welcome,
  privacy,
  features,
  tutorial,
  completed,
}

class OnboardingStep {
  final String id;
  final String title;
  final String description;
  final String imagePath;
  final List<String> keyPoints;
  final bool isRequired;

  const OnboardingStep({
    required this.id,
    required this.title,
    required this.description,
    required this.imagePath,
    required this.keyPoints,
    this.isRequired = true,
  });
}

class FeatureHighlight {
  final String id;
  final String title;
  final String description;
  final String iconPath;
  final String route;

  const FeatureHighlight({
    required this.id,
    required this.title,
    required this.description,
    required this.iconPath,
    required this.route,
  });
}

// =========================================================================
// ONBOARDING CONTENT
// =========================================================================

class OnboardingContent {
  static const List<OnboardingStep> welcomeSteps = [
    OnboardingStep(
      id: 'welcome',
      title: 'Welcome to Timeline Biography',
      description: 'Transform your photo collections into rich, interactive timelines that tell your story.',
      imagePath: 'assets/images/onboarding/welcome.png',
      keyPoints: [
        'Create beautiful timelines from your photos',
        'Add stories, events, and memories',
        'Share with family and friends',
      ],
    ),
    OnboardingStep(
      id: 'privacy',
      title: 'Your Privacy Matters',
      description: 'All your data stays private and under your control.',
      imagePath: 'assets/images/onboarding/privacy.png',
      keyPoints: [
        'All processing happens on your device',
        'No cloud storage required',
        'You own your data completely',
      ],
    ),
  ];

  static const List<FeatureHighlight> features = [
    FeatureHighlight(
      id: 'timeline',
      title: 'Interactive Timeline',
      description: 'Navigate through your life story with an intuitive timeline view.',
      iconPath: 'assets/icons/timeline.svg',
      route: '/timeline',
    ),
    FeatureHighlight(
      id: 'events',
      title: 'Rich Events',
      description: 'Add detailed events with photos, videos, and stories.',
      iconPath: 'assets/icons/events.svg',
      route: '/events',
    ),
    FeatureHighlight(
      id: 'search',
      title: 'Smart Search',
      description: 'Find anything instantly with semantic search.',
      iconPath: 'assets/icons/search.svg',
      route: '/search',
    ),
    FeatureHighlight(
      id: 'export',
      title: 'Export & Share',
      description: 'Export your timeline as PDF, ZIP, or JSON.',
      iconPath: 'assets/icons/export.svg',
      route: '/export',
    ),
    FeatureHighlight(
      id: 'ghost_camera',
      title: 'Ghost Camera',
      description: 'Capture then vs now photos with overlay guidance.',
      iconPath: 'assets/icons/camera.svg',
      route: '/ghost_camera',
    ),
    FeatureHighlight(
      id: 'offline',
      title: 'Offline First',
      description: 'Works perfectly without internet connection.',
      iconPath: 'assets/icons/offline.svg',
      route: '/offline',
    ),
  ];

  static const List<TutorialStep> tutorialSteps = [
    TutorialStep(
      id: 'create_timeline',
      title: 'Create Your First Timeline',
      description: 'Let\'s start by creating a timeline for your memories.',
      targetRoute: '/timelines/create',
      hint: 'Tap the "+" button to create a new timeline',
    ),
    TutorialStep(
      id: 'add_photos',
      title: 'Add Photos',
      description: 'Import photos from your device to build your timeline.',
      targetRoute: '/timeline/import',
      hint: 'Select photos from your gallery',
    ),
    TutorialStep(
      id: 'create_event',
      title: 'Create an Event',
      description: 'Add an event with photos and a story.',
      targetRoute: '/events/create',
      hint: 'Add details to make your story come alive',
    ),
    TutorialStep(
      id: 'explore',
      title: 'Explore Your Timeline',
      description: 'Navigate through your timeline and discover features.',
      targetRoute: '/timeline',
      hint: 'Try scrolling, zooming, and tapping events',
    ),
  ];
}

class TutorialStep {
  final String id;
  final String title;
  final String description;
  final String targetRoute;
  final String hint;

  const TutorialStep({
    required this.id,
    required this.title,
    required this.description,
    required this.targetRoute,
    required this.hint,
  });
}

// =========================================================================
// PROVIDERS
// =========================================================================

final onboardingServiceProvider = Provider<OnboardingService>((ref) {
  return OnboardingService.instance;
});

final onboardingStateProvider = StreamProvider<OnboardingState>((ref) {
  final service = ref.watch(onboardingServiceProvider);
  return service.stateStream;
});
