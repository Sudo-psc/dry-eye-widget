import 'package:flutter/material.dart';

import '../../ui/app_theme.dart';
import '../../utils/constants.dart';

/// Empty state ilustrado para painéis sem dados ainda.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.message,
    this.title,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String message;
  final String? title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.idleBall.withValues(alpha: 0.28),
                      AppColors.idleBall.withValues(alpha: 0.06),
                    ],
                  ),
                  border: Border.all(
                    color: AppColors.idleBall.withValues(alpha: 0.28),
                  ),
                ),
                child: Icon(icon, size: 34, color: AppColors.idleBall),
              ),
              if (title != null) ...[
                const SizedBox(height: 16),
                Text(
                  title!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
              const SizedBox(height: 10),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.45,
                  color: AppColors.textSecondary,
                ),
              ),
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: 18),
                FilledButton(
                  onPressed: onAction,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 44),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadii.sm),
                    ),
                  ),
                  child: Text(actionLabel!),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
