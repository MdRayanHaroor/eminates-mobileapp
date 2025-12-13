import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
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
    await ref.read(walkthroughProvider.notifier).markAsSeen();
    if (!mounted) return;
    
    if (nextRoute != null) {
      context.go(nextRoute); 
    } else {
      context.go('/dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentSlide = _slides[_currentPage];
    final color = currentSlide['color'] as Color;

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

          // Skip Button
          Positioned(
            top: 50,
            right: 20,
            child: TextButton(
              onPressed: () => _finishWalkthrough(null),
              child: Text(
                'SKIP',
                style: GoogleFonts.outfit(
                  color: Colors.grey[700],
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),

          // PageView
          PageView.builder(
            controller: _pageController,
            onPageChanged: _onPageChanged,
            itemCount: _slides.length,
            itemBuilder: (context, index) {
              return _buildSlide(_slides[index]);
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
                  children: List.generate(_slides.length, (index) {
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
                          if (_currentPage < _slides.length - 1) {
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
                              _currentPage == _slides.length - 1 ? 'GET STARTED' : 'NEXT',
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            if (_currentPage < _slides.length - 1) ...[
                              const SizedBox(width: 8),
                              const Icon(Icons.arrow_forward, size: 18),
                            ]
                          ],
                        ),
                      )
                      .animate(target: _currentPage == _slides.length - 1 ? 1 : 0)
                      .shimmer(duration: 1.seconds, delay: 500.ms), // Subtle shimmer on last button
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

          // Specific Action Buttons for Slide 2 and 4
          if (slide.containsKey('action'))
            OutlinedButton(
              onPressed: () {
                final action = slide['action'];
                if (action == 'View Plans') {
                  _finishWalkthrough('/plans');
                } else if (action == 'Add Investment Request') {
                  _finishWalkthrough('/onboarding'); // Verify if this maps to a valid route logic, or needs set state
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
