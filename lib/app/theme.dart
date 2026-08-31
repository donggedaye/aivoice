import 'package:flutter/material.dart';

/// 刻意選定的調色盤，不是 Material 的種子色推導。
///
/// 兩個色相、冷中性調：250（藍）承載介面與主要動作，25（紅）只用在錄音中與
/// 停止這種需要立刻辨認的狀態。錄音工具要能長時間盯著，所以不用暖色編輯風。
///
/// 每個值都由 `oklch()` 換算成 sRGB —— 同色相下只變亮度與彩度，色彩之間才會
/// 一致。白與黑都帶冷偏，不用純 #FFFFFF 配純 #000000。
///
/// 對比度（WCAG 2.1，實測值）：
///   onSurface        on surface           16.34:1   AA
///   onSurfaceVariant on surface            4.57:1   AA
///   primary          on surface            5.20:1   AA
///   onPrimary        on primary            5.35:1   AA
///   onError          on error              5.70:1   AA
///   onErrorContainer on errorContainer    11.01:1   AA
///   outline          on surface            3.17:1   非文字元件邊界達標
abstract final class AppPalette {
  static const surface = Color(0xFFF6F9FB); // oklch(98% 0.004 250)
  static const surfaceContainer = Color(0xFFEEF2F6); // oklch(96% 0.007 250)
  static const onSurface = Color(0xFF161B20); // oklch(22% 0.012 250)
  static const onSurfaceVariant = Color(0xFF69737D); // oklch(55% 0.02 250)
  static const outline = Color(0xFF878D93); // oklch(64% 0.012 250)
  static const outlineVariant = Color(0xFFD4D8DD); // oklch(88% 0.008 250)

  static const primary = Color(0xFF1F6CB0); // oklch(52% 0.13 250)
  static const onPrimary = Color(0xFFF9FCFF); // oklch(99% 0.005 250)
  static const secondary = Color(0xFF405870); // oklch(45% 0.05 250)
  static const onSecondary = Color(0xFFF9FCFF); // oklch(99% 0.005 250)

  static const error = Color(0xFFA74541); // oklch(52% 0.13 25)
  static const onError = Color(0xFFFFFAFA); // oklch(99% 0.005 25)
  static const errorContainer = Color(0xFFFFE4E1); // oklch(94% 0.03 25)
  static const onErrorContainer = Color(0xFF5C1717); // oklch(32% 0.1 25)
}

const ColorScheme _lightScheme = ColorScheme(
  brightness: Brightness.light,
  primary: AppPalette.primary,
  onPrimary: AppPalette.onPrimary,
  secondary: AppPalette.secondary,
  onSecondary: AppPalette.onSecondary,
  error: AppPalette.error,
  onError: AppPalette.onError,
  errorContainer: AppPalette.errorContainer,
  onErrorContainer: AppPalette.onErrorContainer,
  surface: AppPalette.surface,
  onSurface: AppPalette.onSurface,
  onSurfaceVariant: AppPalette.onSurfaceVariant,
  outline: AppPalette.outline,
  outlineVariant: AppPalette.outlineVariant,
  inverseSurface: AppPalette.onSurface,
  onInverseSurface: AppPalette.surface,
);

ThemeData buildAppTheme() {
  return ThemeData(
    useMaterial3: true,
    colorScheme: _lightScheme,
    scaffoldBackgroundColor: AppPalette.surface,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppPalette.surface,
      foregroundColor: AppPalette.onSurface,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
    cardTheme: const CardThemeData(
      color: AppPalette.surfaceContainer,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        // 卡片用整圈細邊界，不用左側色條 —— 色條留給真正的語意強調。
        side: BorderSide(color: AppPalette.outlineVariant),
      ),
    ),
    dividerTheme: const DividerThemeData(color: AppPalette.outlineVariant),
  );
}
