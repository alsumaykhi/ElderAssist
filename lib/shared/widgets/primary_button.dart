import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Large, full-width primary call-to-action button for ElderAssist.
///
/// API is backwards-compatible with the original `PrimaryButton`:
/// `label`, `onPressed`, `icon` all behave the same way.
/// Adds:
///  - [isLoading] : shows an inline spinner instead of the icon
///  - [variant]   : [PrimaryButtonVariant.solid] (default) or
///                  [PrimaryButtonVariant.tonal] for a softer secondary action
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.isLoading = false,
    this.variant = PrimaryButtonVariant.solid,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final PrimaryButtonVariant variant;

  bool get _disabled => onPressed == null || isLoading;

  @override
  Widget build(BuildContext context) {
    final child = _buildChild();

    switch (variant) {
      case PrimaryButtonVariant.solid:
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _disabled ? null : onPressed,
            child: child,
          ),
        );
      case PrimaryButtonVariant.tonal:
        return SizedBox(
          width: double.infinity,
          child: FilledButton.tonal(
            onPressed: _disabled ? null : onPressed,
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.brandPrimarySoft,
              foregroundColor: AppTheme.brandPrimaryDark,
              minimumSize: const Size(double.infinity, 60),
              padding:
                  const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
              textStyle: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w600,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
            ),
            child: child,
          ),
        );
    }
  }

  Widget _buildChild() {
    if (isLoading) {
      return const SizedBox(
        height: 24,
        width: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          valueColor: AlwaysStoppedAnimation(Colors.white),
        ),
      );
    }
    if (icon == null) {
      return Text(label);
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 24),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

enum PrimaryButtonVariant { solid, tonal }
