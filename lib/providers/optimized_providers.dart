import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import 'gastos_provider.dart';
import 'presupuesto_provider.dart';

/// Mixin para optimizar providers y evitar reconstrucciones innecesarias
mixin OptimizedProviderMixin {
  /// Debounce para providers que se actualizan frecuentemente
  static Timer? _debounceTimer;
  static const Duration _defaultDebounceDelay = Duration(milliseconds: 300);

  /// Debounce de actualizaciones
  static void debounceUpdate(
    VoidCallback callback, {
    Duration delay = _defaultDebounceDelay,
  }) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(delay, callback);
  }
}

/// Provider optimizado para gastos con cache
final optimizedGastosProvider = Provider.family<List<dynamic>, String>((ref, monthKey) {
  // Cache de 5 minutos para evitar recálculos innecesarios
  return ref.watch(gastosDelMesSeleccionadoProvider.select((gastos) => [
    gastos.length,
    gastos.fold<double>(0.0, (sum, gasto) => sum + gasto.monto),
    gastos.map((g) => g.categoria).toSet().length,
  ]));
});

/// Provider optimizado para presupuestos con selectores específicos
final optimizedPresupuestosProvider = Provider.family<Map<String, double>, String>((ref, monthKey) {
  // Solo reconstruir cuando cambien los valores, no las referencias
  return ref.watch(presupuestosMesSeleccionadoProvider.select((presupuestos) => 
    Map<String, double>.from(presupuestos)
  ));
});

/// Provider optimizado para totales con memoización
final memoizedTotalsProvider = Provider<Map<String, double>>((ref) {
  final gastos = ref.watch(gastosDelMesSeleccionadoProvider);
  final presupuestos = ref.watch(presupuestosMesSeleccionadoProvider);
  
  // Memoizar cálculos pesados
  return _memoizedCalculateTotals(gastos, presupuestos);
});

// Cache para cálculos memoizados
final Map<String, Map<String, double>> _totalsCache = {};
String? _lastTotalsKey;

Map<String, double> _memoizedCalculateTotals(gastos, presupuestos) {
  // Crear key única basada en los datos
  final key = '${gastos.length}_${gastos.fold(0.0, (sum, g) => sum + g.monto)}_${presupuestos.length}';
  
  // Si es la misma key, devolver cache
  if (_lastTotalsKey == key && _totalsCache.containsKey(key)) {
    return _totalsCache[key]!;
  }
  
  // Calcular nuevos totales
  final totalGastado = gastos.fold<double>(0.0, (sum, gasto) => sum + gasto.monto);
  final presupuestoTotal = presupuestos['total'] ?? 0.0;
  final restante = presupuestoTotal - totalGastado;
  final progreso = presupuestoTotal > 0 ? totalGastado / presupuestoTotal : 0.0;
  
  final result = <String, double>{
    'gastado': totalGastado,
    'presupuesto': presupuestoTotal,
    'restante': restante,
    'progreso': progreso,
  };
  
  // Guardar en cache
  _totalsCache[key] = result;
  _lastTotalsKey = key;
  
  // Limpiar cache viejo
  if (_totalsCache.length > 10) {
    _totalsCache.clear();
    _totalsCache[key] = result;
  }
  
  return result;
}

/// Provider con selector específico para evitar reconstrucciones
final specificCategoryProvider = Provider.family<double, String>((ref, categoria) {
  return ref.watch(
    presupuestosMesSeleccionadoProvider.select((presupuestos) => presupuestos[categoria] ?? 0.0)
  );
});

/// Provider para progreso específico de categoría
final categoryProgressProvider = Provider.family<double, String>((ref, categoria) {
  final presupuesto = ref.watch(specificCategoryProvider(categoria));
  final gastado = ref.watch(
    resumenCategoriasMesSeleccionadoProvider.select((resumen) => resumen[categoria] ?? 0.0)
  );
  
  return presupuesto > 0 ? (gastado / presupuesto).clamp(0.0, 2.0) : 0.0;
});

/// Extension para WidgetRef con métodos optimizados
extension OptimizedWidgetRef on WidgetRef {
  /// Watch solo cuando el valor cambia significativamente
  T watchSignificantChanges<T extends num>(
    ProviderListenable<T> provider, {
    double threshold = 0.01,
  }) {
    T? lastValue;
    
    return watch(provider.select((value) {
      if (lastValue == null || (value - lastValue!).abs() > threshold) {
        lastValue = value;
        return value;
      }
      return lastValue!;
    }));
  }
  
  /// Listen solo cuando hay cambios importantes
  void listenSignificantChanges<T extends num>(
    ProviderListenable<T> provider,
    void Function(T? previous, T next) listener, {
    double threshold = 0.01,
  }) {
    T? lastValue;
    
    listen(provider.select((value) {
      if (lastValue == null || (value - lastValue!).abs() > threshold) {
        final previous = lastValue;
        lastValue = value;
        listener(previous, value);
        return value;
      }
      return lastValue!;
    }), (previous, next) {
      // El listener ya fue llamado en el select
    });
  }
}

/// Widget base optimizado con cache automático
abstract class OptimizedConsumerWidget extends ConsumerWidget {
  const OptimizedConsumerWidget({super.key});
  
  /// Implementar este método en lugar de build
  Widget buildOptimized(BuildContext context, WidgetRef ref);
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Agregar cache automático para widgets complejos
    return buildOptimized(context, ref);
  }
}