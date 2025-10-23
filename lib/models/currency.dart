import 'package:hive/hive.dart';

part 'currency.g.dart';

@HiveType(typeId: 3)
class Currency extends HiveObject {
  @HiveField(0)
  final String code; // USD, MXN, COP, etc.
  
  @HiveField(1)
  final String symbol; // $, $, $, etc.
  
  @HiveField(2)
  final String name; // Dólar estadounidense, Peso mexicano, etc.
  
  @HiveField(3)
  final String country; // Estados Unidos, México, Colombia, etc.
  
  @HiveField(4)
  final String flag; // Emoji de bandera
  
  @HiveField(5)
  final int decimalPlaces; // Número de decimales (generalmente 2)

  Currency({
    required this.code,
    required this.symbol,
    required this.name,
    required this.country,
    required this.flag,
    this.decimalPlaces = 2,
  });

  // Límites inteligentes de presupuesto basados en el valor de la moneda
  double get maxBudgetTotal {
    switch (code) {
      // Monedas de alto valor (cercanas al USD)
      case 'USD': return 50000;    // $50,000 USD
      case 'PEN': return 200000;   // S/200,000 (≈$53,000 USD)
      case 'BRL': return 300000;   // R$300,000 (≈$60,000 USD)
      case 'BOB': return 350000;   // Bs.350,000 (≈$50,000 USD)
      case 'GTQ': return 400000;   // Q400,000 (≈$52,000 USD)
      case 'HNL': return 1200000;  // L1,200,000 (≈$48,000 USD)
      case 'NIO': return 1800000;  // C$1,800,000 (≈$49,000 USD)
      case 'PAB': return 50000;    // B/.50,000 (≈$50,000 USD)
      
      // Monedas de valor medio
      case 'MXN': return 1000000;  // $1,000,000 MXN (≈$50,000 USD)
      case 'DOP': return 3000000;  // RD$3,000,000 (≈$50,000 USD)
      case 'CUP': return 1200000;  // $1,200,000 CUP (≈$50,000 USD)
      case 'HTG': return 6500000;  // G6,500,000 (≈$50,000 USD)
      case 'UYU': return 2000000;  // $U2,000,000 (≈$50,000 USD)
      case 'ARS': return 50000000; // $50,000,000 ARS (≈$50,000 USD)
      case 'CRC': return 25000000; // ₡25,000,000 (≈$50,000 USD)
      
      // Monedas de valor bajo (requieren números más altos)
      case 'COP': return 200000000; // $200,000,000 COP (≈$50,000 USD)
      case 'CLP': return 45000000;  // $45,000,000 CLP (≈$50,000 USD)
      case 'PYG': return 350000000; // ₲350,000,000 (≈$50,000 USD)
      case 'VES': return 1800000000; // Bs.1,800,000,000 (≈$50,000 USD)
      
      default: return 100000; // Valor por defecto
    }
  }

  double get maxBudgetCategory {
    return maxBudgetTotal * 0.4; // 40% del presupuesto total máximo
  }

  int get budgetDivisions {
    // Más divisiones para monedas de valor bajo, menos para monedas de valor alto
    switch (code) {
      case 'USD':
      case 'PAB':
      case 'PEN':
      case 'BRL':
      case 'BOB':
      case 'GTQ': return 500;
      
      case 'MXN':
      case 'DOP':
      case 'CUP':
      case 'UYU':
      case 'HNL':
      case 'NIO':
      case 'HTG': return 1000;
      
      case 'CRC':
      case 'ARS':
      case 'CLP': return 2000;
      
      case 'COP':
      case 'PYG':
      case 'VES': return 5000;
      
      default: return 1000;
    }
  }

  // Método para formatear valores con esta moneda
  String formatAmount(double amount) {
    // Formatear el número con decimales según la moneda
    String formattedNumber = amount.toStringAsFixed(decimalPlaces);
    
    // Separar parte entera y decimal
    List<String> parts = formattedNumber.split('.');
    String integerPart = parts[0];
    String decimalPart = parts.length > 1 ? parts[1] : '';
    
    // Agregar separadores de miles (puntos) a la parte entera
    String formattedInteger = _addThousandsSeparators(integerPart);
    
    // Construir el resultado final
    String result = formattedInteger;
    if (decimalPlaces > 0 && decimalPart.isNotEmpty) {
      result += '.$decimalPart';
    }
    
    return '$symbol$result';
  }
  
  // Método auxiliar para agregar separadores de miles
  String _addThousandsSeparators(String number) {
    if (number.length <= 3) return number;
    
    String result = '';
    int count = 0;
    
    // Procesar de derecha a izquierda
    for (int i = number.length - 1; i >= 0; i--) {
      if (count == 3) {
        result = '.$result';
        count = 0;
      }
      result = number[i] + result;
      count++;
    }
    
    return result;
  }

  @override
  String toString() => '$flag $name ($code)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Currency &&
          runtimeType == other.runtimeType &&
          code == other.code;

  @override
  int get hashCode => code.hashCode;
}

// Clase con todas las monedas disponibles
class AvailableCurrencies {
  static final List<Currency> all = [
    // Estados Unidos
    Currency(
      code: 'USD',
      symbol: '\$',
      name: 'Dólar estadounidense',
      country: 'Estados Unidos',
      flag: '🇺🇸',
    ),
    
    // México
    Currency(
      code: 'MXN',
      symbol: '\$',
      name: 'Peso mexicano',
      country: 'México',
      flag: '🇲🇽',
    ),
    
    // Colombia
    Currency(
      code: 'COP',
      symbol: '\$',
      name: 'Peso colombiano',
      country: 'Colombia',
      flag: '🇨🇴',
      decimalPlaces: 0, // Los pesos colombianos no usan decimales
    ),
    
    // Argentina
    Currency(
      code: 'ARS',
      symbol: '\$',
      name: 'Peso argentino',
      country: 'Argentina',
      flag: '🇦🇷',
    ),
    
    // Chile
    Currency(
      code: 'CLP',
      symbol: '\$',
      name: 'Peso chileno',
      country: 'Chile',
      flag: '🇨🇱',
      decimalPlaces: 0, // Los pesos chilenos no usan decimales
    ),
    
    // Perú
    Currency(
      code: 'PEN',
      symbol: 'S/',
      name: 'Sol peruano',
      country: 'Perú',
      flag: '🇵🇪',
    ),
    
    // Brasil
    Currency(
      code: 'BRL',
      symbol: 'R\$',
      name: 'Real brasileño',
      country: 'Brasil',
      flag: '🇧🇷',
    ),
    
    // Ecuador
    Currency(
      code: 'USD',
      symbol: '\$',
      name: 'Dólar estadounidense',
      country: 'Ecuador',
      flag: '🇪🇨',
    ),
    
    // Venezuela
    Currency(
      code: 'VES',
      symbol: 'Bs.',
      name: 'Bolívar venezolano',
      country: 'Venezuela',
      flag: '🇻🇪',
    ),
    
    // Uruguay
    Currency(
      code: 'UYU',
      symbol: '\$U',
      name: 'Peso uruguayo',
      country: 'Uruguay',
      flag: '🇺🇾',
    ),
    
    // Paraguay
    Currency(
      code: 'PYG',
      symbol: '₲',
      name: 'Guaraní paraguayo',
      country: 'Paraguay',
      flag: '🇵🇾',
      decimalPlaces: 0,
    ),
    
    // Bolivia
    Currency(
      code: 'BOB',
      symbol: 'Bs.',
      name: 'Boliviano',
      country: 'Bolivia',
      flag: '🇧🇴',
    ),
    
    // Guatemala
    Currency(
      code: 'GTQ',
      symbol: 'Q',
      name: 'Quetzal guatemalteco',
      country: 'Guatemala',
      flag: '🇬🇹',
    ),
    
    // Honduras
    Currency(
      code: 'HNL',
      symbol: 'L',
      name: 'Lempira hondureño',
      country: 'Honduras',
      flag: '🇭🇳',
    ),
    
    // El Salvador
    Currency(
      code: 'USD',
      symbol: '\$',
      name: 'Dólar estadounidense',
      country: 'El Salvador',
      flag: '🇸🇻',
    ),
    
    // Nicaragua
    Currency(
      code: 'NIO',
      symbol: 'C\$',
      name: 'Córdoba nicaragüense',
      country: 'Nicaragua',
      flag: '🇳🇮',
    ),
    
    // Costa Rica
    Currency(
      code: 'CRC',
      symbol: '₡',
      name: 'Colón costarricense',
      country: 'Costa Rica',
      flag: '🇨🇷',
    ),
    
    // Panamá
    Currency(
      code: 'PAB',
      symbol: 'B/.',
      name: 'Balboa panameño',
      country: 'Panamá',
      flag: '🇵🇦',
    ),
    
    // República Dominicana
    Currency(
      code: 'DOP',
      symbol: 'RD\$',
      name: 'Peso dominicano',
      country: 'República Dominicana',
      flag: '🇩🇴',
    ),
    
    // Cuba
    Currency(
      code: 'CUP',
      symbol: '\$',
      name: 'Peso cubano',
      country: 'Cuba',
      flag: '🇨🇺',
    ),
    
    // Haití
    Currency(
      code: 'HTG',
      symbol: 'G',
      name: 'Gourde haitiano',
      country: 'Haití',
      flag: '🇭🇹',
    ),
  ];

  // Método para obtener moneda por código
  static Currency? findByCode(String code) {
    try {
      return all.firstWhere((currency) => currency.code == code);
    } catch (e) {
      return null;
    }
  }

  // Método para obtener la moneda por defecto (USD)
  static Currency get defaultCurrency => all.first; // USD

  // Agrupar por regiones para mejor organización
  static Map<String, List<Currency>> get byRegion => {
    'Norteamérica': all.where((c) => 
        ['USD', 'MXN'].contains(c.code) && 
        ['Estados Unidos', 'México'].contains(c.country)
    ).toList(),
    
    'Centroamérica': all.where((c) => 
        ['GTQ', 'HNL', 'USD', 'NIO', 'CRC', 'PAB'].contains(c.code) &&
        ['Guatemala', 'Honduras', 'El Salvador', 'Nicaragua', 'Costa Rica', 'Panamá'].contains(c.country)
    ).toList(),
    
    'Sudamérica': all.where((c) => 
        ['COP', 'VES', 'BRL', 'PEN', 'USD', 'BOB', 'PYG', 'UYU', 'ARS', 'CLP'].contains(c.code) &&
        ['Colombia', 'Venezuela', 'Brasil', 'Perú', 'Ecuador', 'Bolivia', 'Paraguay', 'Uruguay', 'Argentina', 'Chile'].contains(c.country)
    ).toList(),
    
    'Caribe': all.where((c) => 
        ['DOP', 'CUP', 'HTG'].contains(c.code) &&
        ['República Dominicana', 'Cuba', 'Haití'].contains(c.country)
    ).toList(),
  };
}