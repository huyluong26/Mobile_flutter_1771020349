import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

/// Hero header with gradient overlay and background image
class HeroHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? imageUrl;
  final double minHeight;

  const HeroHeader({
    Key? key,
    required this.title,
    required this.subtitle,
    this.imageUrl,
    this.minHeight = 250,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: minHeight,
      width: double.infinity,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(16),
            bottomRight: Radius.circular(16),
          ),
          image: imageUrl != null
              ? DecorationImage(
                  image: NetworkImage(imageUrl!),
                  fit: BoxFit.cover,
                  onError: (exception, stackTrace) {},
                )
              : null,
          gradient: imageUrl == null
              ? LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.primary.withOpacity(0.3),
                    AppColors.backgroundDark,
                  ],
                )
              : null,
        ),
        child: Container(
          // Gradient overlay
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(16),
            ),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.backgroundDark.withOpacity(0.2),
                AppColors.backgroundDark,
              ],
            ),
          ),
          // Content
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTypography.heading1),
              const SizedBox(height: 4),
              Text(subtitle, style: AppTypography.subtitle),
            ],
          ),
        ),
      ),
    );
  }
}

/// Divider with text in the middle
class DividerWithText extends StatelessWidget {
  final String text;

  const DividerWithText({Key? key, required this.text}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Container(height: 1, color: AppColors.borderDark)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            text,
            style: AppTypography.bodyMedium.copyWith(
              fontSize: 12,
              color: AppColors.textMuted,
              letterSpacing: 1.5,
            ),
          ),
        ),
        Expanded(child: Container(height: 1, color: AppColors.borderDark)),
      ],
    );
  }
}
