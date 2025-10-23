void main() {
  print('Testing CurrencyParser...');
  
  // Test casos simples
  print('25000 -> ${parseFormattedCurrency('25000')}'); // Debería ser 25000.0
  print('25.000 -> ${parseFormattedCurrency('25.000')}'); // Debería ser 25000.0  
  print('1.500.000 -> ${parseFormattedCurrency('1.500.000')}'); // Debería ser 1500000.0
  print('100.50 -> ${parseFormattedCurrency('100.50')}'); // Debería ser 100.50
  print('1.234.567.89 -> ${parseFormattedCurrency('1.234.567.89')}'); // Debería ser 1234567.89
  print('empty -> ${parseFormattedCurrency('')}'); // Debería ser null
  print('abc -> ${parseFormattedCurrency('abc')}'); // Debería ser null
}

/// Parsea un texto que puede contener separadores de miles (puntos)
/// Ejemplo: "25.000" -> 25000.0, "1.500.000" -> 1500000.0
double? parseFormattedCurrency(String text) {
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