import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_palette.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';

class PremiumTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? hintText;
  final String? Function(String?)? validator;
  final bool obscureText;
  final TextInputType? keyboardType;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final int? maxLines;
  final String? labelText;
  final bool readOnly;
  final VoidCallback? onTap;
  final void Function(String)? onChanged;
  final void Function(String)? onFieldSubmitted;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;

  const PremiumTextField({
    super.key,
    this.controller,
    this.hintText,
    this.validator,
    this.obscureText = false,
    this.keyboardType,
    this.prefixIcon,
    this.suffixIcon,
    this.maxLines = 1,
    this.labelText,
    this.readOnly = false,
    this.onTap,
    this.onChanged,
    this.onFieldSubmitted,
    this.textInputAction,
    this.autofillHints,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.darkTextPrimary : context.palette.textPrimary;
    final hintColor = isDark ? AppColors.darkTextHint : context.palette.textHint;
    final borderColor = isDark ? AppColors.darkBorder : context.palette.border;
    final focusColor = isDark ? AppColors.primaryLight : AppColors.primary;

    OutlineInputBorder outline(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: BorderSide(color: color, width: width),
        );

    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      autofillHints: autofillHints,
      maxLines: obscureText ? 1 : maxLines,
      readOnly: readOnly,
      onTap: onTap,
      onChanged: onChanged,
      onFieldSubmitted: onFieldSubmitted,
      validator: validator,
      style: context.text.body.copyWith(color: textColor),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: context.text.body.copyWith(color: hintColor),
        prefixIcon: prefixIcon,
        prefixIconColor: hintColor,
        suffixIcon: suffixIcon,
        suffixIconColor: hintColor,
        label: labelText != null
            ? Text(labelText!, style: context.text.caption)
            : null,
        border: outline(borderColor),
        enabledBorder: outline(borderColor),
        focusedBorder: outline(focusColor, 2),
        errorBorder: outline(AppColors.error),
        focusedErrorBorder: outline(AppColors.error, 2),
        filled: true,
        fillColor: isDark ? AppColors.darkSurfaceVariant : context.palette.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
      ),
    );
  }
}
