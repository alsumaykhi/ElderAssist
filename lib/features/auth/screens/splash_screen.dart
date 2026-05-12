import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/elder_assist_logo.dart';
import '../../../shared/widgets/primary_button.dart';
import 'phone_input_screen.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  static const String routePath = '/';
  static const String routeName = 'splash';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppTheme.space7,
            AppTheme.space8,
            AppTheme.space7,
            AppTheme.space8,
          ),
          child: Column(
            children: [
              const Spacer(flex: 2),
              const _BrandHero(),
              const Spacer(flex: 3),
              PrimaryButton(
                label: 'Get started',
                icon: Icons.arrow_forward,
                onPressed: () => context.go(PhoneInputScreen.routePath),
              ),
              const SizedBox(height: AppTheme.space5),
              const Text(
                'By continuing you agree to our terms of use.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.textTertiary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BrandHero extends StatefulWidget {
  const _BrandHero();

  @override
  State<_BrandHero> createState() => _BrandHeroState();
}

class _BrandHeroState extends State<_BrandHero>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: const ElderAssistSplashHero(),
      ),
    );
  }
}
