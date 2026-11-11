import 'package:flutter/material.dart';

/// Colores de VeraGo (sección 15.1 del documento).
/// Se definen una sola vez aquí y toda la app los usa,
/// así un cambio de color se hace en un solo lugar.
class VgColores {
  /// Azul del Golfo de México: color principal.
  static const azulGolfo = Color(0xFF0B3C5D);

  /// Terracota de las fachadas coloniales: acentos y botones de acción.
  static const terracota = Color(0xFFB8492F);

  /// Verde palma del Zócalo: estados positivos ("Abierto", "Sello obtenido").
  static const verdePalma = Color(0xFF2E7D5B);

  /// Blanco cálido de los muros encalados: fondo.
  static const arena = Color(0xFFF7F2EA);

  /// Texto principal.
  static const tinta = Color(0xFF1E2A32);
}

/// Tema visual: le dice a Flutter qué colores y letras usar en todos
/// los widgets (botones, barras, tarjetas) sin repetirlo en cada pantalla.
class VgTema {
  static ThemeData get claro {
    final esquema = ColorScheme.fromSeed(
      seedColor: VgColores.azulGolfo,
      primary: VgColores.azulGolfo,
      secondary: VgColores.terracota,
      tertiary: VgColores.verdePalma,
      surface: VgColores.arena,
      onSurface: VgColores.tinta,
    );

    // Títulos con letra serif (transmite historia); el resto con la
    // letra normal del sistema (legible y moderna).
    const titulos = TextStyle(
      fontFamily: 'serif',
      fontFamilyFallback: ['Georgia'],
      color: VgColores.tinta,
      fontWeight: FontWeight.w700,
    );

    return ThemeData(
      colorScheme: esquema,
      scaffoldBackgroundColor: VgColores.arena,
      textTheme: const TextTheme(
        headlineMedium: titulos,
        headlineSmall: titulos,
        titleLarge: titulos,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: VgColores.arena,
        foregroundColor: VgColores.tinta,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: 'serif',
          fontFamilyFallback: ['Georgia'],
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: VgColores.tinta,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: VgColores.azulGolfo.withValues(alpha: 0.12),
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: VgColores.terracota,
          foregroundColor: Colors.white,
          minimumSize: const Size(48, 48), // botones grandes (accesibilidad)
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: VgColores.tinta.withValues(alpha: 0.08)),
        ),
      ),
    );
  }
}
