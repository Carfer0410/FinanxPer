import 'package:flutter/material.dart';

/// Sistema de colores único y moderno para FinanxPer
/// Inspirado en tonos de prosperidad, confianza y modernidad
class FinanxperColors {
  // Colores primarios - Verde esmeralda elegante
  static const Color primary = Color(0xFF00B894);          // Verde esmeralda brillante
  static const Color primaryDark = Color(0xFF00A085);      // Verde esmeralda oscuro
  static const Color primaryLight = Color(0xFF26D0CE);     // Verde agua luminoso
  
  // Colores secundarios - Azul profundo sofisticado
  static const Color secondary = Color(0xFF0984E3);        // Azul océano
  static const Color secondaryDark = Color(0xFF0652DD);    // Azul profundo
  static const Color secondaryLight = Color(0xFF74B9FF);   // Azul cielo
  
  // Colores de acento - Violeta moderno
  static const Color accent = Color(0xFF6C5CE7);           // Violeta vibrante
  static const Color accentLight = Color(0xFFA29BFE);      // Violeta suave
  
  // Colores funcionales
  static const Color success = Color(0xFF00B894);          // Verde éxito
  static const Color warning = Color(0xFFFFB03A);          // Ámbar elegante
  static const Color error = Color(0xFFE84393);            // Rosa coral
  static const Color info = Color(0xFF0984E3);             // Azul información
  
  // Colores neutros modernos
  static const Color surface = Color(0xFFFDFCFF);          // Blanco perla
  static const Color surfaceDark = Color(0xFF2D3436);      // Gris carbón
  static const Color background = Color(0xFFF8F9FA);       // Gris muy claro
  static const Color backgroundDark = Color(0xFF636E72);   // Gris medio
  
  // Colores de texto
  static const Color textPrimary = Color(0xFF2D3436);      // Gris oscuro elegante
  static const Color textSecondary = Color(0xFF636E72);    // Gris medio
  static const Color textLight = Color(0xFFB2BEC3);        // Gris claro
  static const Color textOnPrimary = Color(0xFFFFFFFF);    // Blanco puro
  
  // Gradientes únicos
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryLight],
  );
  
  static const LinearGradient secondaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [secondary, secondaryLight],
  );
  
  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accent, accentLight],
  );
  
  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, secondary, accent],
    stops: [0.0, 0.5, 1.0],
  );
  
  // Sombras elegantes
  static const List<BoxShadow> softShadow = [
    BoxShadow(
      color: Color(0x1A000000),
      blurRadius: 10,
      offset: Offset(0, 4),
    ),
  ];
  
  static const List<BoxShadow> mediumShadow = [
    BoxShadow(
      color: Color(0x26000000),
      blurRadius: 20,
      offset: Offset(0, 8),
    ),
  ];
  
  static const List<BoxShadow> strongShadow = [
    BoxShadow(
      color: Color(0x33000000),
      blurRadius: 30,
      offset: Offset(0, 12),
    ),
  ];
}

/// Tema personalizado de FinanxPer
class FinanxperTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      
      // Esquema de colores
      colorScheme: const ColorScheme.light(
        primary: FinanxperColors.primary,
        primaryContainer: FinanxperColors.primaryLight,
        onPrimary: FinanxperColors.textOnPrimary,
        onPrimaryContainer: FinanxperColors.textPrimary,
        
        secondary: FinanxperColors.secondary,
        secondaryContainer: FinanxperColors.secondaryLight,
        onSecondary: FinanxperColors.textOnPrimary,
        onSecondaryContainer: FinanxperColors.textPrimary,
        
        tertiary: FinanxperColors.accent,
        tertiaryContainer: FinanxperColors.accentLight,
        onTertiary: FinanxperColors.textOnPrimary,
        onTertiaryContainer: FinanxperColors.textPrimary,
        
        error: FinanxperColors.error,
        onError: FinanxperColors.textOnPrimary,
        
        surface: FinanxperColors.surface,
        onSurface: FinanxperColors.textPrimary,
        onSurfaceVariant: FinanxperColors.textSecondary,
        
        background: FinanxperColors.background,
        onBackground: FinanxperColors.textPrimary,
        
        outline: FinanxperColors.textLight,
        outlineVariant: FinanxperColors.backgroundDark,
      ),
      
      // AppBar personalizada
      appBarTheme: const AppBarTheme(
        backgroundColor: FinanxperColors.primary,
        foregroundColor: FinanxperColors.textOnPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: FinanxperColors.textOnPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
        iconTheme: IconThemeData(
          color: FinanxperColors.textOnPrimary,
          size: 24,
        ),
      ),
      
      // Botones elevados
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: FinanxperColors.primary,
          foregroundColor: FinanxperColors.textOnPrimary,
          elevation: 4,
          shadowColor: FinanxperColors.primary.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
      
      // Botones de texto
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: FinanxperColors.primary,
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
      
      // Botones con contorno
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: FinanxperColors.primary,
          side: const BorderSide(color: FinanxperColors.primary, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
      
      // Tarjetas
      cardTheme: CardTheme(
        color: FinanxperColors.surface,
        elevation: 4,
        shadowColor: FinanxperColors.textSecondary.withOpacity(0.2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      ),
      
      // Campos de entrada
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: FinanxperColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: FinanxperColors.textLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: FinanxperColors.textLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: FinanxperColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: FinanxperColors.error, width: 2),
        ),
        labelStyle: const TextStyle(
          color: FinanxperColors.textSecondary,
          fontSize: 16,
        ),
        hintStyle: const TextStyle(
          color: FinanxperColors.textLight,
          fontSize: 16,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      
      // Iconos
      iconTheme: const IconThemeData(
        color: FinanxperColors.primary,
        size: 24,
      ),
      
      // Bottom Navigation Bar
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: FinanxperColors.surface,
        selectedItemColor: FinanxperColors.primary,
        unselectedItemColor: FinanxperColors.textLight,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
      
      // FloatingActionButton
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: FinanxperColors.accent,
        foregroundColor: FinanxperColors.textOnPrimary,
        elevation: 6,
        shape: CircleBorder(),
      ),
      
      // Diálogos
      dialogTheme: DialogTheme(
        backgroundColor: FinanxperColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 8,
        titleTextStyle: const TextStyle(
          color: FinanxperColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        contentTextStyle: const TextStyle(
          color: FinanxperColors.textSecondary,
          fontSize: 16,
        ),
      ),
      
      // Tipografía
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          color: FinanxperColors.textPrimary,
          fontSize: 32,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
        ),
        displayMedium: TextStyle(
          color: FinanxperColors.textPrimary,
          fontSize: 28,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.25,
        ),
        displaySmall: TextStyle(
          color: FinanxperColors.textPrimary,
          fontSize: 24,
          fontWeight: FontWeight.w600,
        ),
        headlineLarge: TextStyle(
          color: FinanxperColors.textPrimary,
          fontSize: 22,
          fontWeight: FontWeight.w600,
        ),
        headlineMedium: TextStyle(
          color: FinanxperColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        headlineSmall: TextStyle(
          color: FinanxperColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        titleLarge: TextStyle(
          color: FinanxperColors.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: TextStyle(
          color: FinanxperColors.textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        titleSmall: TextStyle(
          color: FinanxperColors.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: TextStyle(
          color: FinanxperColors.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w400,
        ),
        bodyMedium: TextStyle(
          color: FinanxperColors.textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        bodySmall: TextStyle(
          color: FinanxperColors.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
        labelLarge: TextStyle(
          color: FinanxperColors.textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        labelMedium: TextStyle(
          color: FinanxperColors.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        labelSmall: TextStyle(
          color: FinanxperColors.textLight,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Extensiones útiles para colores
extension FinanxperColorExtensions on Color {
  /// Crea una versión con opacidad personalizada
  Color withOpacity(double opacity) {
    return Color.fromRGBO(red, green, blue, opacity);
  }
  
  /// Crea una versión más clara del color
  Color lighten([double amount = 0.1]) {
    final hsl = HSLColor.fromColor(this);
    final lightness = (hsl.lightness + amount).clamp(0.0, 1.0);
    return hsl.withLightness(lightness).toColor();
  }
  
  /// Crea una versión más oscura del color
  Color darken([double amount = 0.1]) {
    final hsl = HSLColor.fromColor(this);
    final lightness = (hsl.lightness - amount).clamp(0.0, 1.0);
    return hsl.withLightness(lightness).toColor();
  }
}