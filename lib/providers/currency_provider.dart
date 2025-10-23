import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/currency.dart';

class CurrencyNotifier extends StateNotifier<Currency> {
  static const String _boxName = 'currency_config';
  static const String _currencyKey = 'selected_currency';
  late Box<String> _configBox;

  CurrencyNotifier() : super(AvailableCurrencies.defaultCurrency) {
    _initBox();
  }

  Future<void> _initBox() async {
    try {
      _configBox = await Hive.openBox<String>(_boxName);
      await _loadSavedCurrency();
    } catch (e) {
      print('Error inicializando box de moneda: $e');
    }
  }

  Future<void> _loadSavedCurrency() async {
    try {
      final savedCurrencyCode = _configBox.get(_currencyKey);
      if (savedCurrencyCode != null) {
        final currency = AvailableCurrencies.findByCode(savedCurrencyCode);
        if (currency != null) {
          state = currency;
          print('✅ Moneda cargada: ${currency.name} (${currency.code})');
        }
      }
    } catch (e) {
      print('Error cargando moneda guardada: $e');
    }
  }

  Future<void> setCurrency(Currency currency) async {
    try {
      state = currency;
      await _configBox.put(_currencyKey, currency.code);
      print('✅ Moneda actualizada: ${currency.name} (${currency.code})');
      
      // Forzar notificación de cambio para que todos los providers se actualicen
      // Esto es necesario para asegurar reactividad completa
      state = Currency(
        code: currency.code,
        symbol: currency.symbol,
        name: currency.name,
        country: currency.country,
        flag: currency.flag,
        decimalPlaces: currency.decimalPlaces,
      );
    } catch (e) {
      print('Error guardando moneda: $e');
    }
  }

  // Método para formatear amounts con la moneda actual
  String formatAmount(double amount) {
    return state.formatAmount(amount);
  }

  // Método para obtener el símbolo de la moneda actual
  String get currentSymbol => state.symbol;

  // Método para obtener el código de la moneda actual
  String get currentCode => state.code;

  // Método para obtener información completa de la moneda actual
  Currency get currentCurrency => state;
}

// Provider para el notifier de monedas
final currencyProvider = StateNotifierProvider<CurrencyNotifier, Currency>((ref) {
  return CurrencyNotifier();
});

// Provider para formatear amounts fácilmente
final currencyFormatterProvider = Provider<String Function(double)>((ref) {
  final currency = ref.watch(currencyProvider);
  return (amount) => currency.formatAmount(amount);
});

// Provider para obtener el símbolo de moneda actual
final currencySymbolProvider = Provider<String>((ref) {
  final currency = ref.watch(currencyProvider);
  return currency.symbol;
});

// Provider para obtener todas las monedas disponibles
final availableCurrenciesProvider = Provider<List<Currency>>((ref) {
  return AvailableCurrencies.all;
});

// Provider para obtener monedas agrupadas por región
final currenciesByRegionProvider = Provider<Map<String, List<Currency>>>((ref) {
  return AvailableCurrencies.byRegion;
});