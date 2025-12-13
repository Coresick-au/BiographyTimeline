import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../../../shared/design_system/app_theme.dart';
import '../../../shared/design_system/app_icons.dart';
import '../../../shared/design_system/interaction_feedback.dart';
import '../services/onboarding_service.dart';

/// Onboarding widget with welcome flow, privacy policy, and feature overview
/// Provides guided introduction to Timeline Biography app
class OnboardingWidget extends ConsumerStatefulWidget {
  const OnboardingWidget({
    super.key,
    required this.onCompleted,
    this.allowSkip = true,
  });

  final VoidCallback onCompleted;
  final bool allowSkip;

  @override
  ConsumerState<OnboardingWidget> createState() => _OnboardingWidgetState();
}

class _OnboardingWidgetState extends ConsumerState<OnboardingWidget>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  int _currentPage = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializePageController();
    _loadOnboardingState();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
  }

  void _initializePageController() {
    _pageController = PageController();
    _pageController.addListener(() {
      final newPage = _pageController.page?.round() ?? 0;
      if (newPage != _currentPage) {
        setState(() {
          _currentPage = newPage;
        });
        _animatePageIn();
      }
    });
  }

  Future<void> _loadOnboardingState() async {
    final service = ref.read(onboardingServiceProvider);
    await service.initialize();
    
    setState(() {
      _isLoading = false;
    });
    
    _fadeController.forward();
  }

  void _animatePageIn() {
    _fadeController.reset();
    _slideController.reset();
    _fadeController.forward();
    _slideController.forward();
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    
    if (_isLoading) {
      return Scaffold(
        backgroundColor: theme.colors.background,
        body: Center(
          child: CircularProgressIndicator(
            color: theme.colors.primary,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: theme.colors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            if (widget.allowSkip && _currentPage < OnboardingContent.welcomeSteps.length - 1)
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextButton(
                    onPressed: _skipOnboarding,
                    child: Text(
                      'Skip',
                      style: theme.textStyles.labelLarge.copyWith(
                        color: theme.colors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ),
            
            // Page content
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: OnboardingContent.welcomeSteps.length,
                itemBuilder: (context, index) {
                  return _buildWelcomePage(
                    OnboardingContent.welcomeSteps[index],
                    index == OnboardingContent.welcomeSteps.length - 1,
                  );
                },
              ),
            ),
            
            // Bottom controls
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Page indicator
                  SmoothPageIndicator(
                    controller: _pageController,
                    count: OnboardingContent.welcomeSteps.length,
                    effect: WormEffect(
                      dotColor: theme.colors.surfaceVariant,
                      activeDotColor: theme.colors.primary,
                      dotHeight: 8,
                      dotWidth: 8,
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Action buttons
                  Row(
                    children: [
                      // Back button
                      if (_currentPage > 0)
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _previousPage,
                            child: Text('Back'),
                          ),
                        ),
                      
                      if (_currentPage > 0) const SizedBox(width: 16),
                      
                      // Next/Get Started button
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _nextPage,
                          child: Text(
                            _currentPage == OnboardingContent.welcomeSteps.length - 1
                                ? 'Get Started'
                                : 'Next',
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomePage(OnboardingStep step, bool isLast) {
    final theme = AppTheme.of(context);
    
    return AnimatedBuilder(
      animation: Listenable.merge([_fadeAnimation, _slideAnimation]),
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Illustration
                  Container(
                    width: 280,
                    height: 280,
                    decoration: BoxDecoration(
                      color: theme.colors.surfaceVariant,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Icon(
                        _getStepIcon(step.id),
                        size: 120,
                        color: theme.colors.primary,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 48),
                  
                  // Title
                  Text(
                    step.title,
                    style: theme.textStyles.headlineMedium,
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Description
                  Text(
                    step.description,
                    style: theme.textStyles.bodyLarge.copyWith(
                      color: theme.colors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Key points
                  ...step.keyPoints.map((point) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Icon(
                          AppIcons.checkCircle,
                          size: 20,
                          color: theme.colors.primary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            point,
                            style: theme.textStyles.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  )),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  IconData _getStepIcon(String stepId) {
    switch (stepId) {
      case 'welcome':
        return AppIcons.timeline;
      case 'privacy':
        return AppIcons.lock;
      default:
        return AppIcons.info;
    }
  }

  void _nextPage() async {
    InteractionFeedback.trigger();
    
    if (_currentPage < OnboardingContent.welcomeSteps.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      await _completeOnboarding();
    }
  }

  void _previousPage() {
    InteractionFeedback.trigger();
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _skipOnboarding() async {
    final service = ref.read(onboardingServiceProvider);
    await service.skipOnboarding();
    widget.onCompleted();
  }

  Future<void> _completeOnboarding() async {
    final service = ref.read(onboardingServiceProvider);
    
    // Mark all steps as complete
    await service.completeWelcome();
    await service.acceptPrivacyPolicy();
    await service.completeFeaturesOverview();
    await service.completeTutorial();
    
    widget.onCompleted();
  }
}

/// Widget for showcasing key features
class FeaturesOverviewWidget extends ConsumerWidget {
  const FeaturesOverviewWidget({
    super.key,
    required this.onCompleted,
  });

  final VoidCallback onCompleted;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = AppTheme.of(context);
    
    return Scaffold(
      backgroundColor: theme.colors.background,
      appBar: AppBar(
        title: Text('Discover Features'),
        actions: [
          TextButton(
            onPressed: onCompleted,
            child: Text('Done'),
          ),
        ],
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: _getCrossAxisCount(context),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.0,
        ),
        itemCount: OnboardingContent.features.length,
        itemBuilder: (context, index) {
          final feature = OnboardingContent.features[index];
          return FeatureCard(
            feature: feature,
            onTap: () => _showFeatureDetails(context, feature),
          );
        },
      ),
    );
  }

  int _getCrossAxisCount(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth > 800) return 3;
    if (screenWidth > 600) return 2;
    return 1;
  }

  void _showFeatureDetails(BuildContext context, FeatureHighlight feature) {
    showDialog(
      context: context,
      builder: (context) => FeatureDetailDialog(feature: feature),
    );
  }
}

/// Feature card for the overview grid
class FeatureCard extends StatelessWidget {
  const FeatureCard({
    super.key,
    required this.feature,
    required this.onTap,
  });

  final FeatureHighlight feature;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _getFeatureIcon(feature.id),
                size: 48,
                color: theme.colors.primary,
              ),
              const SizedBox(height: 12),
              Text(
                feature.title,
                style: theme.textStyles.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                feature.description,
                style: theme.textStyles.bodySmall.copyWith(
                  color: theme.colors.textSecondary,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getFeatureIcon(String featureId) {
    switch (featureId) {
      case 'timeline':
        return AppIcons.timeline;
      case 'events':
        return AppIcons.event;
      case 'search':
        return AppIcons.search;
      case 'export':
        return AppIcons.download;
      case 'ghost_camera':
        return AppIcons.camera;
      case 'offline':
        return AppIcons.offline;
      default:
        return AppIcons.info;
    }
  }
}

/// Dialog showing feature details
class FeatureDetailDialog extends StatelessWidget {
  const FeatureDetailDialog({
    super.key,
    required this.feature,
  });

  final FeatureHighlight feature;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    
    return AlertDialog(
      title: Text(feature.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getFeatureIcon(feature.id),
            size: 64,
            color: theme.colors.primary,
          ),
          const SizedBox(height: 16),
          Text(
            feature.description,
            style: theme.textStyles.bodyMedium,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Close'),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            // Navigate to feature
          },
          child: Text('Try It'),
        ),
      ],
    );
  }

  IconData _getFeatureIcon(String featureId) {
    switch (featureId) {
      case 'timeline':
        return AppIcons.timeline;
      case 'events':
        return AppIcons.event;
      case 'search':
        return AppIcons.search;
      case 'export':
        return AppIcons.download;
      case 'ghost_camera':
        return AppIcons.camera;
      case 'offline':
        return AppIcons.offline;
      default:
        return AppIcons.info;
    }
  }
}
