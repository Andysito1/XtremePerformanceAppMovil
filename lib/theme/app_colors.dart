import 'package:flutter/material.dart';

/// Paleta de marca de Xtreme Performance: rojo corporativo + un oscuro
/// grafito con tinte azulado (evita el gris plano usado anteriormente).
class AppColors {
  AppColors._();

  static const Color dark = Color(0xFF1B2430);
  static const Color darkElevated = Color(0xFF242F3F);
  static const Color darkSoft = Color(0xFF2E3A4D);

  static const Color red = Color(0xFFE53935);
  static const Color redDark = Color(0xFFB71C1C);

  static const Color bg = Color(0xFFF3F5F9);

  static const LinearGradient darkGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [dark, darkSoft],
  );

  static const LinearGradient redGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [red, redDark],
  );
}
