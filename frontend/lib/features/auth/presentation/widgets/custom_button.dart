import 'package:flutter/material.dart';
import 'package:vertice/core/constants/app_colors.dart';
import 'package:vertice/core/utils/responsive.dart';

enum ButtonVariant { primary, secondary, outline, ghost }

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final ButtonVariant variant;
  final IconData? icon;
  final double? width;
  final double? height;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.variant = ButtonVariant.primary,
    this.icon,
    this.width = double.infinity,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final bool isEnabled = onPressed != null && !isLoading;
    final isTabletOrLarger = !Responsive.isMobile(context);
    final effectiveHeight = height ?? (isTabletOrLarger ? 56.0 : 52.0);
    final fontSize = isTabletOrLarger ? 14.0 : 13.0;
    final iconSize = isTabletOrLarger ? 20.0 : 18.0;

    Color backgroundColor;
    Color textColor;
    BorderSide borderSide;
    List<BoxShadow> boxShadow = [];

    switch (variant) {
      case ButtonVariant.primary:
        backgroundColor = isEnabled ? AppColors.cyan : AppColors.cyanDim.withValues(alpha: 0.5);
        textColor = const Color(0xFF050B14);
        borderSide = BorderSide.none;
        if (isEnabled) {
          boxShadow = [
            BoxShadow(
              color: AppColors.cyan.withValues(alpha: 0.35),
              blurRadius: 16,
              spreadRadius: 0,
              offset: const Offset(0, 4),
            ),
          ];
        }
        break;

      case ButtonVariant.secondary:
        backgroundColor = AppColors.surfaceElevated;
        textColor = AppColors.textPrimary;
        borderSide = const BorderSide(color: AppColors.surfaceBorder, width: 1);
        break;

      case ButtonVariant.outline:
        backgroundColor = AppColors.gold.withValues(alpha: 0.05);
        textColor = AppColors.gold;
        borderSide = const BorderSide(color: AppColors.gold, width: 1.2);
        if (isEnabled) {
          boxShadow = [
            BoxShadow(
              color: AppColors.gold.withValues(alpha: 0.2),
              blurRadius: 14,
              offset: const Offset(0, 2),
            ),
          ];
        }
        break;

      case ButtonVariant.ghost:
        backgroundColor = Colors.transparent;
        textColor = AppColors.textSecondary;
        borderSide = BorderSide.none;
        break;
    }

    return Container(
      width: width,
      height: effectiveHeight,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(10),
        border: borderSide != BorderSide.none
            ? Border.fromBorderSide(borderSide)
            : null,
        boxShadow: boxShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: isEnabled ? onPressed : null,
          splashColor: variant == ButtonVariant.primary
              ? Colors.white.withValues(alpha: 0.2)
              : (variant == ButtonVariant.outline
                  ? AppColors.gold.withValues(alpha: 0.25)
                  : AppColors.cyan.withValues(alpha: 0.15)),
          highlightColor: Colors.transparent,
          child: Center(
            child: isLoading
                ? SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        variant == ButtonVariant.primary
                            ? const Color(0xFF050B14)
                            : (variant == ButtonVariant.outline
                                ? AppColors.gold
                                : AppColors.cyan),
                      ),
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (icon != null) ...[
                          Icon(
                            icon,
                            size: iconSize,
                            color: textColor,
                          ),
                          const SizedBox(width: 8),
                        ],
                        Flexible(
                          child: Text(
                            text,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: textColor,
                              fontSize: fontSize,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
