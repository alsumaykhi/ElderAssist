import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../brand/elder_assist_brand_assets.dart';
import '../theme/app_theme.dart';

/// Bond mark from [ElderAssistBrandAssets.symbol] (two circles + coral heart).
class ElderAssistSymbol extends StatelessWidget {
  const ElderAssistSymbol({
    super.key,
    required this.size,
  });

  final double size;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      ElderAssistBrandAssets.symbol,
      width: size,
      height: size,
      semanticsLabel: 'ElderAssist symbol',
    );
  }
}

/// "Elder" + "Assist" styled per brand kit (Fraunces; Assist in sage).
class ElderAssistWordmarkText extends StatelessWidget {
  const ElderAssistWordmarkText({
    super.key,
    required this.fontSize,
    this.textAlign = TextAlign.center,
    this.height = 1.15,
  });

  final double fontSize;
  final TextAlign textAlign;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: 'Elder',
            style: GoogleFonts.fraunces(
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
              height: height,
              letterSpacing: -0.5,
            ),
          ),
          TextSpan(
            text: 'Assist',
            style: GoogleFonts.fraunces(
              fontSize: fontSize,
              fontWeight: FontWeight.w500,
              color: AppTheme.brandPrimary,
              height: height,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
      textAlign: textAlign,
    );
  }
}

/// Splash / welcome: symbol + wordmark + supporting line.
class ElderAssistSplashHero extends StatelessWidget {
  const ElderAssistSplashHero({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const ElderAssistSymbol(size: 120),
        const SizedBox(height: AppTheme.space7),
        const ElderAssistWordmarkText(fontSize: 40),
        const SizedBox(height: AppTheme.space5),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.space5),
          child: Text(
            'Care has two sides, we hold both.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 18,
              color: AppTheme.textSecondary,
              height: 1.45,
            ),
          ),
        ),
      ],
    );
  }
}

/// Compact brand for [AppBar] (symbol + wordmark).
class ElderAssistAppBarTitle extends StatelessWidget {
  const ElderAssistAppBarTitle({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const ElderAssistSymbol(size: 28),
        const SizedBox(width: 10),
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: const ElderAssistWordmarkText(
              fontSize: 22,
              textAlign: TextAlign.start,
            ),
          ),
        ),
      ],
    );
  }
}
