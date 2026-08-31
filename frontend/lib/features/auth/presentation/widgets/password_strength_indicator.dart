import 'package:flutter/material.dart';
import 'package:vertice/core/constants/app_colors.dart';

enum PasswordStrength { none, weak, medium, strong }

class PasswordStrengthIndicator extends StatelessWidget {
  final String password;

  const PasswordStrengthIndicator({
    super.key,
    required this.password,
  });

  PasswordStrength _calculateStrength() {
    if (password.isEmpty) return PasswordStrength.none;
    if (password.length < 6) return PasswordStrength.weak;

    bool hasLetters = RegExp(r'[a-zA-Z]').hasMatch(password);
    bool hasDigits = RegExp(r'[0-9]').hasMatch(password);
    bool hasSpecial = RegExp(r'[!@#\$&*~%^()_+=|<>?{}\[\]:;,.-]').hasMatch(password);

    int score = 0;
    if (password.length >= 8) score++;
    if (hasLetters && hasDigits) score++;
    if (hasSpecial) score++;

    if (score >= 2) return PasswordStrength.strong;
    if (score == 1 || password.length >= 6) return PasswordStrength.medium;
    return PasswordStrength.weak;
  }

  @override
  Widget build(BuildContext context) {
    if (password.isEmpty) return const SizedBox.shrink();

    final strength = _calculateStrength();

    Color segment1Color = AppColors.surfaceBorder;
    Color segment2Color = AppColors.surfaceBorder;
    Color segment3Color = AppColors.surfaceBorder;
    String label = 'DÉBIL';
    Color labelColor = AppColors.error;

    switch (strength) {
      case PasswordStrength.none:
        break;
      case PasswordStrength.weak:
        segment1Color = AppColors.error;
        label = 'NIVEL: CRIPTOGRAFÍA DÉBIL';
        labelColor = AppColors.error;
        break;
      case PasswordStrength.medium:
        segment1Color = AppColors.gold;
        segment2Color = AppColors.gold;
        label = 'NIVEL: PROTECCIÓN MEDIA';
        labelColor = AppColors.gold;
        break;
      case PasswordStrength.strong:
        segment1Color = AppColors.cyan;
        segment2Color = AppColors.cyan;
        segment3Color = AppColors.cyan;
        label = 'NIVEL: ENCRIPTACIÓN SEGURA';
        labelColor = AppColors.cyan;
        break;
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _buildSegment(segment1Color),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _buildSegment(segment2Color),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _buildSegment(segment3Color),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: labelColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                  fontFamily: 'monospace',
                ),
              ),
              const Text(
                'REQ: 6+ CARACTERES',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 9,
                  letterSpacing: 1.0,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSegment(Color color) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      height: 3.5,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
        boxShadow: color != AppColors.surfaceBorder
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.4),
                  blurRadius: 6,
                  spreadRadius: 0.5,
                ),
              ]
            : [],
      ),
    );
  }
}
