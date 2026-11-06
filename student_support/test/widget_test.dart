// Design-token tests for the CampusSupport app.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:student_support/core/theme/app_colors.dart';
import 'package:student_support/core/theme/app_spacing.dart';
import 'package:student_support/core/theme/app_radius.dart';
import 'package:student_support/core/theme/app_text_styles.dart';

void main() {
  testWidgets('AppSpacing values are correct', (WidgetTester tester) async {
    expect(AppSpacing.xs, 4);
    expect(AppSpacing.sm, 8);
    expect(AppSpacing.md, 16);
    expect(AppSpacing.lg, 24);
    expect(AppSpacing.xl, 32);
  });

  testWidgets('AppRadius values are correct', (WidgetTester tester) async {
    expect(AppRadius.sm, 8);
    expect(AppRadius.md, 16);
    expect(AppRadius.lg, 24);
  });

  testWidgets('AppColors primary is the ALU navy', (WidgetTester tester) async {
    expect(AppColors.primary, isA<Color>());
    expect(AppColors.primary, AppColors.aluNavy);
    expect(AppColors.secondary, AppColors.aluRed);
    expect(AppColors.accent, AppColors.aluGold);
  });

  testWidgets('AppTextStyles has heading style', (WidgetTester tester) async {
    expect(AppTextStyles.heading, isA<TextStyle>());
    expect(AppTextStyles.heading.fontSize, 24);
    expect(AppTextStyles.heading.fontWeight, FontWeight.w700);
  });

  testWidgets('AppTextStyles has body style', (WidgetTester tester) async {
    expect(AppTextStyles.body, isA<TextStyle>());
    expect(AppTextStyles.body.fontSize, 15);
  });

  testWidgets('AppTextStyles has caption style', (WidgetTester tester) async {
    expect(AppTextStyles.caption, isA<TextStyle>());
    expect(AppTextStyles.caption.fontSize, 12);
  });
}
