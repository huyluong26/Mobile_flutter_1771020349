import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

/// Reusable text field with icon prefix
class AppTextField extends StatelessWidget {
  final String label;
  final String placeholder;
  final IconData icon;
  final bool obscureText;
  final TextEditingController? controller;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;

  const AppTextField({
    Key? key,
    required this.label,
    required this.placeholder,
    required this.icon,
    this.obscureText = false,
    this.controller,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.labelMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          validator: validator,
          onChanged: onChanged,
          style: AppTypography.bodyLarge,
          decoration: InputDecoration(
            hintText: placeholder,
            prefixIcon: Container(
              padding: const EdgeInsets.only(left: 16, right: 12),
              child: Icon(icon, color: AppColors.textMuted, size: 24),
            ),
            prefixIconConstraints: const BoxConstraints(
              minWidth: 56,
              minHeight: 56,
            ),
          ),
        ),
      ],
    );
  }
}

/// Password text field with toggle visibility
class AppPasswordField extends StatefulWidget {
  final String label;
  final String placeholder;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;

  const AppPasswordField({
    Key? key,
    this.label = 'Mật khẩu',
    this.placeholder = 'Nhập mật khẩu của bạn',
    this.controller,
    this.validator,
    this.onChanged,
  }) : super(key: key);

  @override
  State<AppPasswordField> createState() => _AppPasswordFieldState();
}

class _AppPasswordFieldState extends State<AppPasswordField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: AppTypography.labelMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: widget.controller,
          obscureText: _obscureText,
          validator: widget.validator,
          onChanged: widget.onChanged,
          style: AppTypography.bodyLarge,
          decoration: InputDecoration(
            hintText: widget.placeholder,
            prefixIcon: Container(
              padding: const EdgeInsets.only(left: 16, right: 12),
              child: const Icon(
                Icons.lock_outlined,
                color: AppColors.textMuted,
                size: 24,
              ),
            ),
            prefixIconConstraints: const BoxConstraints(
              minWidth: 56,
              minHeight: 56,
            ),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureText ? Icons.visibility_off : Icons.visibility,
                color: AppColors.textMuted,
              ),
              onPressed: () {
                setState(() {
                  _obscureText = !_obscureText;
                });
              },
            ),
          ),
        ),
      ],
    );
  }
}
