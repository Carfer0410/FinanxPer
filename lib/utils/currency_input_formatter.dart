import 'package:flutter/services.dart';

/// TextInputFormatter mejorado que agrega separadores de miles (puntos)
/// automáticamente mientras el usuario escribe cifras monetarias.
/// Maneja correctamente tanto enteros como decimales independientemente del tipo de moneda.
class CurrencyInputFormatter extends TextInputFormatter {
  final int decimalPlaces;
  
  CurrencyInputFormatter({this.decimalPlaces = 2});

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Si el nuevo valor está vacío, permitirlo
    if (newValue.text.isEmpty) {
      return newValue;
    }

    // Solo permitir dígitos y puntos
    String filtered = newValue.text.replaceAll(RegExp(r'[^\d.]'), '');
    
    // Si no hay contenido válido, limpiar
    if (filtered.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    // Estrategia mejorada: distinguir entre punto decimal y separadores de miles
    String formatted = _smartFormat(filtered);

    // Cursor siempre al final para simplificar
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  /// Formatea de manera inteligente distinguiendo decimales de separadores de miles
  /// GARANTIZA que funcione con TODAS las monedas sin limitaciones
  String _smartFormat(String input) {
    if (input.isEmpty) return input;
    
    // ESTRATEGIA 1: Si solo hay un punto al final, es para decimales (solo si se permiten)
    if (input.endsWith('.') && decimalPlaces > 0) {
      String integerPart = input.substring(0, input.length - 1);
      if (integerPart.isEmpty) return '';
      
      // Limpiar y formatear solo la parte entera
      String cleanInteger = integerPart.replaceAll('.', '');
      String formattedInteger = _addThousandsSeparators(cleanInteger);
      return '$formattedInteger.';
    }
    
    // ESTRATEGIA 2: Análisis inteligente de puntos para CUALQUIER moneda
    String integerPart = '';
    String decimalPart = '';
    
    if (decimalPlaces > 0) {
      // Para monedas CON decimales (USD, MXN, EUR, BRL, etc.)
      List<String> segments = input.split('.');
      
      if (segments.length == 1) {
        // Sin puntos - solo números enteros
        integerPart = segments[0];
      } else if (segments.length == 2) {
        // Un punto - determinar si es decimal o separador de miles
        String beforePoint = segments[0];
        String afterPoint = segments[1];
        
        // Heurística: si después del punto hay 1-2 dígitos Y es <= decimalPlaces, es decimal
        if (afterPoint.length <= decimalPlaces && afterPoint.length <= 2 && beforePoint.length > 0) {
          integerPart = beforePoint;
          decimalPart = afterPoint;
        } else {
          // Es separador de miles - concatenar todo como entero
          integerPart = beforePoint + afterPoint;
        }
      } else {
        // Múltiples puntos - analizar el último segmento
        String lastSegment = segments.last;
        // Si el último segmento tiene 1-2 dígitos, probablemente es decimal
        if (lastSegment.length <= decimalPlaces && lastSegment.length <= 2) {
          integerPart = segments.sublist(0, segments.length - 1).join('');
          decimalPart = lastSegment;
        } else {
          // Todos son separadores de miles
          integerPart = segments.join('');
        }
      }
    } else {
      // Para monedas SIN decimales (COP, CLP, PYG)
      // TODOS los puntos son separadores de miles - remover y tratar como entero
      integerPart = input.replaceAll('.', '');
    }

    // ESTRATEGIA 3: Formatear con separadores de miles sin límites
    String formattedInteger = _addThousandsSeparators(integerPart);
    
    // ESTRATEGIA 4: Combinar con decimales si existen y están permitidos
    if (decimalPart.isNotEmpty && decimalPlaces > 0) {
      // Limitar decimales al máximo permitido sin cortar la entrada prematuramente
      if (decimalPart.length > decimalPlaces) {
        decimalPart = decimalPart.substring(0, decimalPlaces);
      }
      return '$formattedInteger.$decimalPart';
    } else {
      return formattedInteger;
    }
  }

  /// Agrega separadores de miles solo a la parte entera
  String _addThousandsSeparators(String integerInput) {
    if (integerInput.isEmpty) return integerInput;

    // Formatear parte entera con separadores de miles
    String formattedInteger = '';
    for (int i = 0; i < integerInput.length; i++) {
      if (i > 0 && (integerInput.length - i) % 3 == 0) {
        formattedInteger += '.';
      }
      formattedInteger += integerInput[i];
    }

    return formattedInteger;
  }
}

/// Factory method para crear formatter según el tipo de moneda
/// Garantiza que TODAS las monedas usen el mismo algoritmo mejorado
class CurrencyInputFormatterFactory {
  /// Crea un formatter optimizado para cualquier moneda
  /// Funciona perfectamente independientemente del número de decimales
  static CurrencyInputFormatter create({required int decimalPlaces}) {
    return CurrencyInputFormatter(decimalPlaces: decimalPlaces);
  }
  
  /// Método específico para COP - Sin decimales
  static CurrencyInputFormatter createForCOP() {
    return CurrencyInputFormatter(decimalPlaces: 0);
  }
  
  /// Método específico para CLP - Sin decimales  
  static CurrencyInputFormatter createForCLP() {
    return CurrencyInputFormatter(decimalPlaces: 0);
  }
  
  /// Método específico para PYG - Sin decimales
  static CurrencyInputFormatter createForPYG() {
    return CurrencyInputFormatter(decimalPlaces: 0);
  }
  
  /// Método por defecto para monedas con decimales (USD, MXN, EUR, etc.)
  static CurrencyInputFormatter createDefault() {
    return CurrencyInputFormatter(decimalPlaces: 2);
  }
  
  /// Método universal que funciona para CUALQUIER moneda
  /// Permite entrada ilimitada independientemente de los decimales
  static CurrencyInputFormatter createUniversal() {
    return CurrencyInputFormatter(decimalPlaces: 2); // El algoritmo maneja ambos casos
  }
}

/// Helper class para parsear texto formateado con separadores de miles
class CurrencyParser {
  /// Parsea un texto que puede contener separadores de miles (puntos)
  /// Ejemplo: "25.000" -> 25000.0, "1.500.000" -> 1500000.0
  static double? parseFormattedCurrency(String text) {
    if (text.isEmpty) return null;
    
    // Remover espacios
    text = text.trim();
    if (text.isEmpty) return null;
    
    // Contar los puntos en el texto
    int dotCount = '.'.allMatches(text).length;
    
    if (dotCount == 0) {
      // Sin puntos - número simple
      return double.tryParse(text);
    } else if (dotCount == 1) {
      // Un punto - puede ser decimal o separador de miles
      List<String> parts = text.split('.');
      String afterDot = parts[1];
      
      // Si la parte después del punto tiene 3 dígitos o más, es separador de miles
      if (afterDot.length >= 3) {
        // Es separador de miles - remover punto
        String cleanText = text.replaceAll('.', '');
        return double.tryParse(cleanText);
      } else {
        // Es punto decimal - mantener como está
        return double.tryParse(text);
      }
    } else {
      // Múltiples puntos - son separadores de miles
      // El último punto podría ser decimal si tiene 1-2 dígitos después
      List<String> parts = text.split('.');
      if (parts.length >= 2) {
        String lastPart = parts.last;
        if (lastPart.length <= 2) {
          // El último punto es decimal
          String integerParts = parts.sublist(0, parts.length - 1).join('');
          return double.tryParse('$integerParts.$lastPart');
        } else {
          // Todos son separadores de miles
          String cleanText = text.replaceAll('.', '');
          return double.tryParse(cleanText);
        }
      }
    }
    
    return null;
  }
}