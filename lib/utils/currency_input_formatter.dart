import 'package:flutter/services.dart';

/// TextInputFormatter simplificado que agrega separadores de miles (puntos)
/// automáticamente mientras el usuario escribe cifras monetarias.
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

    // Solo permitir dígitos y un punto decimal
    String filtered = newValue.text.replaceAll(RegExp(r'[^\d.]'), '');
    
    // Si no hay contenido válido, limpiar
    if (filtered.isEmpty || filtered == '.') {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    // Manejar punto decimal
    if (decimalPlaces == 0) {
      // Sin decimales - remover todos los puntos
      filtered = filtered.replaceAll('.', '');
    } else {
      // Con decimales - solo un punto permitido
      List<String> parts = filtered.split('.');
      if (parts.length > 2) {
        // Múltiples puntos - mantener solo el primero
        filtered = parts[0] + '.' + parts.sublist(1).join('');
      }
      // Limitar decimales
      if (parts.length == 2 && parts[1].length > decimalPlaces) {
        filtered = parts[0] + '.' + parts[1].substring(0, decimalPlaces);
      }
    }

    // Formatear con separadores de miles
    String formatted = _addThousandsSeparators(filtered);

    // Cursor siempre al final para simplificar
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  /// Agrega separadores de miles de forma simple
  String _addThousandsSeparators(String input) {
    if (input.isEmpty) return input;

    // Separar parte entera y decimal
    List<String> parts = input.split('.');
    String integerPart = parts[0];
    String decimalPart = parts.length > 1 ? parts[1] : '';

    // Formatear parte entera con separadores
    String formattedInteger = '';
    for (int i = 0; i < integerPart.length; i++) {
      if (i > 0 && (integerPart.length - i) % 3 == 0) {
        formattedInteger += '.';
      }
      formattedInteger += integerPart[i];
    }

    // Combinar partes
    if (decimalPart.isNotEmpty) {
      return '$formattedInteger.$decimalPart';
    } else {
      return formattedInteger;
    }
  }
}

/// Factory method para crear formatter según el tipo de moneda
class CurrencyInputFormatterFactory {
  static CurrencyInputFormatter create({required int decimalPlaces}) {
    return CurrencyInputFormatter(decimalPlaces: decimalPlaces);
  }
  
  static CurrencyInputFormatter createForCOP() {
    return CurrencyInputFormatter(decimalPlaces: 0);
  }
  
  static CurrencyInputFormatter createForCLP() {
    return CurrencyInputFormatter(decimalPlaces: 0);
  }
  
  static CurrencyInputFormatter createForPYG() {
    return CurrencyInputFormatter(decimalPlaces: 0);
  }
  
  static CurrencyInputFormatter createDefault() {
    return CurrencyInputFormatter(decimalPlaces: 2);
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