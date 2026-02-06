import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../data/mock/mock_data.dart';
import '../widgets/step_indicator.dart';
import 'auth/customer_auth_page.dart';

class OnboardingPage extends StatefulWidget {
  static const String routeName = '/onboarding';

  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _controller = PageController();
  int _index = 0;

  void _next() {
    if (_index < MockData.onboarding.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } else {
      Navigator.pushReplacementNamed(context, CustomerAuthPage.routeName);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
              child: Row(
                children: [
                  Container(
                    height: 40,
                    width: 40,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x12000000),
                          blurRadius: 10,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Image.asset('assets/images/logo.png'),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.pushReplacementNamed(
                      context,
                      CustomerAuthPage.routeName,
                    ),
                    child: const Text('Skip'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                onPageChanged: (value) => setState(() => _index = value),
                itemCount: MockData.onboarding.length,
                itemBuilder: (context, i) {
                  final step = MockData.onboarding[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Spacer(),
                        _IllustrationBadge(label: step.iconLabel),
                        const SizedBox(height: 28),
                        Text(
                          step.title,
                          style: Theme.of(context).textTheme.titleLarge,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          step.description,
                          style: Theme.of(context).textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                        const Spacer(),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: Row(
                children: [
                  StepIndicator(
                    count: MockData.onboarding.length,
                    index: _index,
                  ),
                  const Spacer(),
                  SizedBox(
                    height: 44,
                    child: ElevatedButton(
                      onPressed: _next,
                      child: Text(_index == MockData.onboarding.length - 1
                          ? 'Get Started'
                          : 'Next'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IllustrationBadge extends StatelessWidget {
  final String label;

  const _IllustrationBadge({required this.label});

  IconData _icon() {
    switch (label) {
      case 'grid':
        return Icons.grid_view_rounded;
      case 'chat':
        return Icons.chat_bubble_outline;
      case 'map':
        return Icons.map_outlined;
      default:
        return Icons.handyman_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      width: 200,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.splashStart, AppColors.splashEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 16,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Center(
        child: Icon(_icon(), size: 92, color: Colors.white),
      ),
    );
  }
}
