import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ErrorSnackbar {
  static void _show({
    required BuildContext context,
    required String message,
    required Color color,
    required IconData icon,
  }) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: color,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          margin: const EdgeInsets.all(AppSpacing.md),
          duration: const Duration(seconds: 4),
        ),
      );
  }

  static void show({
    required BuildContext context,
    required String message,
  }) {
    _show(
      context: context,
      message: message,
      color: AppColors.danger,
      icon: Icons.error_outline,
    );
  }

  static void showSuccess({
    required BuildContext context,
    required String message,
  }) {
    _show(
      context: context,
      message: message,
      color: AppColors.success,
      icon: Icons.check_circle_outline,
    );
  }
}
