import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:investorapp_eminates/features/auth/providers/auth_provider.dart';
import 'package:investorapp_eminates/features/onboarding/providers/walkthrough_provider.dart';

class IntroWalkthroughScreen extends ConsumerStatefulWidget {
  const IntroWalkthroughScreen({super.key});

  @override
  ConsumerState<IntroWalkthroughScreen> createState() => _IntroWalkthroughScreenState();
}

class _IntroWalkthroughScreenState extends ConsumerState<IntroWalkthroughScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, dynamic>> _slides = [
    {
      'title': 'Welcome to Eminates',
      'subtitle': 'Smart Investments, High Returns',
      'description': 'Experience the future of investing with our premium platform. Secure, transparent, and built for your growth.',
      'image': 'assets/intro_1.png', // Placeholder, using Icons instead if missing
      'icon': Icons.trending_up,
      'color': const Color(0xFF1E88E5), // Blue
    },
    {
      'title': 'Tailored Plans',
      'subtitle': 'Choose What Suits You',
      'description': 'Explore a variety of investment plans designed to meet your financial goals. Flexible terms, competitive returns.',
      'image': 'assets/intro_2.png',
      'icon': Icons.dashboard_customize,
      'color': const Color(0xFF43A047), // Green
      'action': 'View Plans',
    },
    {
      'title': 'About Eminates',
      'subtitle': 'Trusted & Transparent',
      'description': 'We are committed to delivering value. Our expert team ensures your investments are managed with the highest standards.',
      'image': 'assets/intro_3.png',
      'icon': Icons.business,
      'color': const Color(0xFF8E24AA), // Purple
    },
    {
      'title': 'Get Started',
      'subtitle': 'Your Journey Begins Now',
      'description': 'Ready to grow your wealth? Create your first investment request in just a few taps.',
      'image': 'assets/intro_4.png',
      'icon': Icons.rocket_launch,
      'color': const Color(0xFFE53935), // Red
      'action': 'Add Investment Request',
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentPage = index;
    });
  }

  Future<void> _finishWalkthrough(String? nextRoute) async {
    // User requested not to change shared preference state
    // await ref.read(walkthroughProvider.notifier).markAsSeen(); 
    
    if (!mounted) return;
    
    if (nextRoute != null) {
      context.go(nextRoute); 
    } else {
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/dashboard');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final walkthroughAsync = ref.watch(walkthroughProvider);
    final hasSeenBefore = walkthroughAsync.valueOrNull ?? false;

    // Update slides text dynamically if seen before
    final displaySlides = List<Map<String, dynamic>>.from(_slides);
    if (hasSeenBefore) {
      displaySlides[0] = {
        ...displaySlides[0],
        'title': 'Welcome Back to Eminates',
      };
      displaySlides[3] = {
        ...displaySlides[3],
        'action_label': 'Proceed', // Custom key for button label
      };
    }

    final currentSlide = displaySlides[_currentPage];
    final color = currentSlide['color'] as Color;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background Gradient Animation
          Positioned.fill(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    color.withOpacity(0.1),
                    Colors.white,
                    color.withOpacity(0.05),
                  ],
                ),
              ),
            ),
          ),

          // Top Actions (Skip & Logout)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                         if (context.canPop()) {
                           context.pop();
                         } else {
                           context.go('/dashboard');
                         }
                      },
                      child: Text(
                        'SKIP',
                        style: GoogleFonts.outfit(
                          color: theme.primaryColor, 
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    Container(width: 1, height: 20, color: Colors.grey[400]),
                    IconButton(
                      onPressed: () {
                         ref.read(authRepositoryProvider).signOut();
                         if (context.mounted) context.go('/login'); 
                      },
                      icon: Icon(Icons.logout, size: 20, color: theme.colorScheme.error),
                      tooltip: 'Logout',
                    ),
                  ],
                ),
              ),
            ),
          ),

          // PageView
          PageView.builder(
            controller: _pageController,
            onPageChanged: _onPageChanged,
            itemCount: displaySlides.length,
            itemBuilder: (context, index) {
              return _buildSlide(displaySlides[index]);
            },
          ),

          // Bottom Controls
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: Column(
              children: [
                // Page Indicator
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(displaySlides.length, (index) {
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      height: 8,
                      width: _currentPage == index ? 24 : 8,
                      decoration: BoxDecoration(
                        color: _currentPage == index ? color : Colors.grey[300],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 32),

                // Navigation Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Back Button (Hidden on first page)
                    if (_currentPage > 0)
                      IconButton(
                        onPressed: () {
                          _pageController.previousPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        },
                        icon: const Icon(Icons.arrow_back),
                        color: Colors.grey[700],
                      )
                    else
                      const SizedBox(width: 48),

                    // Primary Action Button (Next or Finish)
                    ElevatedButton(
                         onPressed: () {
                          if (_currentPage < displaySlides.length - 1) {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          } else {
                            _finishWalkthrough(null);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: color,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 8,
                          shadowColor: color.withOpacity(0.5),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _currentPage == displaySlides.length - 1 
                                ? (displaySlides[_currentPage]['action_label'] ?? 'GET STARTED') 
                                : 'NEXT',
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            if (_currentPage < displaySlides.length - 1) ...[
                              const SizedBox(width: 8),
                              const Icon(Icons.arrow_forward, size: 18),
                            ]
                          ],
                        ),
                      )
                      .animate(target: _currentPage == displaySlides.length - 1 ? 1 : 0)
                      .shimmer(duration: 1.seconds, delay: 500.ms), 
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlide(Map<String, dynamic> slide) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon/Image Area
          Container(
            height: 250,
            width: 250,
            decoration: BoxDecoration(
              color: (slide['color'] as Color).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              slide['icon'],
              size: 100,
              color: slide['color'] as Color,
            ),
          )
          .animate()
          .scale(duration: 600.ms, curve: Curves.easeOutBack)
          .fadeIn(duration: 600.ms),

          const SizedBox(height: 48),

          // Text Content
          Text(
            slide['title'],
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0),

          const SizedBox(height: 12),

          Text(
            slide['subtitle'],
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: slide['color'] as Color,
            ),
          ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2, end: 0),

          const SizedBox(height: 16),

          Text(
            slide['description'],
            textAlign: TextAlign.center,
            style: GoogleFonts.roboto(
              fontSize: 16,
              height: 1.5,
              color: Colors.grey[600],
            ),
          ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2, end: 0),

          const SizedBox(height: 32),

            if (slide.containsKey('action'))
            OutlinedButton(
              onPressed: () {
                final action = slide['action'];
                if (action == 'View Plans') {
                  context.go('/dashboard');
                  // Post frame callback to push next screen so back button works for dashboard
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (context.mounted) context.push('/plans');
                  });
                } else if (action == 'Add Investment Request') {
                  context.go('/dashboard');
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (context.mounted) {
                       // Reset onboarding state if needed
                       context.push('/onboarding');
                    }
                  });
                }
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: slide['color'],
                side: BorderSide(color: slide['color']),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              child: Text(slide['action']),
            ).animate().fadeIn(delay: 600.ms).scale(),
        ],
      ),
    );
  }
}
