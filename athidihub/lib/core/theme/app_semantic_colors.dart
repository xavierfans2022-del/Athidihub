import 'package:flutter/material.dart';
import 'package:athidihub/core/theme/app_colors.dart';

class AppSemanticColors extends ThemeExtension<AppSemanticColors> {
  final Color success;
  final Color successBg;
  final Color warning;
  final Color warningBg;
  final Color error;
  final Color errorBg;
  final Color info;
  final Color infoBg;

  const AppSemanticColors({
    required this.success,
    required this.successBg,
    required this.warning,
    required this.warningBg,
    required this.error,
    required this.errorBg,
    required this.info,
    required this.infoBg,
  });

  static const dark = AppSemanticColors(
    success: AppColors.success,
    successBg: AppColors.successBg,
    warning: AppColors.warning,
    warningBg: AppColors.warningBg,
    error: AppColors.error,
    errorBg: AppColors.errorBg,
    info: AppColors.info,
    infoBg: AppColors.infoBg,
  );

  static const light = AppSemanticColors(
    success: AppColors.success,
    successBg: AppColors.successBgLight,
    warning: AppColors.warning,
    warningBg: AppColors.warningBgLight,
    error: AppColors.error,
    errorBg: AppColors.errorBgLight,
    info: AppColors.info,
    infoBg: AppColors.infoBgLight,
  );

  @override
  AppSemanticColors copyWith({
    Color? success,
    Color? successBg,
    Color? warning,
    Color? warningBg,
    Color? error,
    Color? errorBg,
    Color? info,
    Color? infoBg,
  }) {
    return AppSemanticColors(
      success: success ?? this.success,
      successBg: successBg ?? this.successBg,
      warning: warning ?? this.warning,
      warningBg: warningBg ?? this.warningBg,
      error: error ?? this.error,
      errorBg: errorBg ?? this.errorBg,
      info: info ?? this.info,
      infoBg: infoBg ?? this.infoBg,
    );
  }

  @override
  AppSemanticColors lerp(ThemeExtension<AppSemanticColors>? other, double t) {
    if (other is! AppSemanticColors) {
      return this;
    }
    return AppSemanticColors(
      success: Color.lerp(success, other.success, t) ?? success,
      successBg: Color.lerp(successBg, other.successBg, t) ?? successBg,
      warning: Color.lerp(warning, other.warning, t) ?? warning,
      warningBg: Color.lerp(warningBg, other.warningBg, t) ?? warningBg,
      error: Color.lerp(error, other.error, t) ?? error,
      errorBg: Color.lerp(errorBg, other.errorBg, t) ?? errorBg,
      info: Color.lerp(info, other.info, t) ?? info,
      infoBg: Color.lerp(infoBg, other.infoBg, t) ?? infoBg,
    );
  }
}
