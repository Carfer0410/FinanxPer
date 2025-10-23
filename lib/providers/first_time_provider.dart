import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

class FirstTimeNotifier extends StateNotifier<bool> {
  static const String _boxName = 'app_config';
  static const String _firstTimeKey = 'is_first_time';
  late Box<bool> _configBox;

  FirstTimeNotifier() : super(true) {
    _initBox();
  }

  Future<void> _initBox() async {
    try {
      _configBox = await Hive.openBox<bool>(_boxName);
      final isFirstTime = _configBox.get(_firstTimeKey, defaultValue: true) ?? true;
      state = isFirstTime;
    } catch (e) {
      print('Error inicializando box de configuración de app: $e');
    }
  }

  Future<void> markAsNotFirstTime() async {
    try {
      state = false;
      await _configBox.put(_firstTimeKey, false);
      print('✅ Marcado como no primera vez');
    } catch (e) {
      print('Error marcando como no primera vez: $e');
    }
  }

  // Método para resetear (útil para testing o reinstalación)
  Future<void> resetFirstTime() async {
    try {
      state = true;
      await _configBox.put(_firstTimeKey, true);
      print('✅ Reseteado a primera vez');
    } catch (e) {
      print('Error reseteando primera vez: $e');
    }
  }
}

// Provider para manejar si es la primera vez que se abre la app
final firstTimeProvider = StateNotifierProvider<FirstTimeNotifier, bool>((ref) {
  return FirstTimeNotifier();
});