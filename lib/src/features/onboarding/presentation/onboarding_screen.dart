import 'package:chargego/src/core/theme/app_theme.dart';
import 'package:chargego/src/core/widgets/premium_widgets.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingData> _pages = const [
    OnboardingData(
      title: 'Welcome to ChargeGO',
      description: 'Premium power bank rental, ready wherever your day moves.',
      image: Icons.electric_bolt_rounded,
    ),
    OnboardingData(
      title: 'Find a Station',
      description: 'Locate nearby ChargeGO points with live availability.',
      image: Icons.location_on_rounded,
    ),
    OnboardingData(
      title: 'Scan & Go',
      description: 'Scan the QR code, unlock your battery, and keep moving.',
      image: Icons.qr_code_scanner_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return PremiumScaffold(
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: _pages.length,
              onPageChanged: (int page) {
                setState(() {
                  _currentPage = page;
                });
              },
              itemBuilder: (context, index) {
                return OnboardingPage(data: _pages[index]);
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _pages.length,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      height: 8,
                      width: _currentPage == index ? 28 : 8,
                      decoration: BoxDecoration(
                        gradient: _currentPage == index
                            ? const LinearGradient(
                                colors: [
                                  ChargeGoColors.royal,
                                  ChargeGoColors.electric,
                                ],
                              )
                            : null,
                        color: _currentPage == index
                            ? null
                            : ChargeGoColors.sky.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: GradientButton(
                    label: _currentPage == _pages.length - 1
                        ? 'Get Started'
                        : 'Next',
                    icon: _currentPage == _pages.length - 1
                        ? Icons.arrow_forward_rounded
                        : Icons.navigate_next_rounded,
                    onPressed: () {
                      if (_currentPage == _pages.length - 1) {
                        context.go('/login');
                      } else {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }
                    },
                  ),
                ),
                if (_currentPage != _pages.length - 1)
                  TextButton(
                    onPressed: () => context.go('/login'),
                    child: const Text('Skip'),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class OnboardingData {
  const OnboardingData({
    required this.title,
    required this.description,
    required this.image,
  });

  final String title;
  final String description;
  final IconData image;
}

class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key, required this.data});

  final OnboardingData data;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 34, 28, 12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const BrandLogo(size: 132),
          const SizedBox(height: 32),
          PremiumCard(
            padding: const EdgeInsets.all(28),
            gradient: LinearGradient(
              colors: [
                Colors.white,
                ChargeGoColors.frost.withValues(alpha: 0.8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            child: Column(
              children: [
                Container(
                  width: 82,
                  height: 82,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [ChargeGoColors.royal, ChargeGoColors.electric],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Icon(data.image, size: 40, color: Colors.white),
                ),
                const SizedBox(height: 24),
                Text(
                  data.title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: ChargeGoColors.navy,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  data.description,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: ChargeGoColors.muted,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
