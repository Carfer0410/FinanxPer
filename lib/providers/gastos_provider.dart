import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import '../models/gasto.dart';
import '../models/currency.dart';
import 'currency_provider.dart';
import 'date_provider.dart';
import 'app_state_provider.dart';

// Provider para manejar el estado de gastos
final gastosProvider = StateNotifierProvider<GastosNotifier, List<Gasto>>((ref) {
  return GastosNotifier(ref);
});

class GastosNotifier extends StateNotifier<List<Gasto>> {
  final Ref ref;
  
  // Constructor: inicializa con datos de Hive o lista vacía
  GastosNotifier(this.ref) : super([]) {
    _cargarGastos();
  }

  // Caja de Hive para persistencia
  Box<Gasto> get _gastosBox => Hive.box<Gasto>('gastos');

  // Obtener notificador de estado global
  AppStateNotifier get _appState => ref.read(appStateProvider.notifier);

  // Cargar gastos desde Hive al inicializar
  void _cargarGastos() {
    state = _gastosBox.values.toList();
  }

  // Generar un ID único secuencial
  int _generarNuevoId() {
    if (_gastosBox.isEmpty) {
      return 1; // Comenzar desde 1
    }
    
    // Encontrar el ID más alto y sumar 1
    final ids = _gastosBox.keys.cast<int>();
    final maxId = ids.reduce((max, current) => current > max ? current : max);
    
    // Verificar que el ID esté en el rango válido de Hive (0 - 0xFFFFFFFF)
    final nuevoId = maxId + 1;
    if (nuevoId > 0xFFFFFFFF) {
      throw Exception('Se ha alcanzado el límite máximo de IDs de gastos');
    }
    
    return nuevoId;
  }

  // Agregar un nuevo gasto
  Future<void> addGasto(Gasto gasto) async {
    try {
      _appState.notifySaving('Agregando gasto...');

      // Generar un nuevo ID si no tiene uno válido
      if (gasto.id <= 0) {
        gasto.id = _generarNuevoId();
      }

      // Asignar la moneda actual si no tiene una
      if (gasto.currencyCode == null) {
        final currentCurrency = ref.read(currencyProvider);
        gasto.currencyCode = currentCurrency.code;
      }

      // Agregar a la lista en memoria
      state = [...state, gasto];

      // Guardar en Hive usando el ID como key
      await _gastosBox.put(gasto.id, gasto);

      _appState.notifySaved();
      _appState.notifyDataUpdate(
        DataUpdateType.gastoAdded, 
        'Gasto de ${gasto.categoria} agregado exitosamente'
      );
    } catch (e) {
      _appState.notifyError('Error al agregar gasto: $e');
      rethrow;
    }
  }

  // Remover gasto por índice
  Future<void> removeGasto(int index) async {
    if (index >= 0 && index < state.length) {
      try {
        _appState.notifySaving('Eliminando gasto...');

        final gasto = state[index];

        // Remover de la lista en memoria
        state = List.from(state)..removeAt(index);

        // Remover de Hive usando la key (ID del gasto)
        await _gastosBox.delete(gasto.id);

        _appState.notifySaved();
        _appState.notifyDataUpdate(
          DataUpdateType.gastoDeleted, 
          'Gasto eliminado exitosamente'
        );
      } catch (e) {
        _appState.notifyError('Error al eliminar gasto: $e');
        rethrow;
      }
    }
  }

  // Remover gasto por ID
  Future<void> removeGastoById(int id) async {
    final index = state.indexWhere((gasto) => gasto.id == id);
    if (index != -1) {
      await removeGasto(index);
    }
  }

  // Obtener resumen de gastos por categoría para el mes actual
  Map<String, double> getResumenCategorias() {
    final gastosMes = getGastosMesActual();
    final resumen = <String, double>{};

    for (final gasto in gastosMes) {
      resumen[gasto.categoria] = (resumen[gasto.categoria] ?? 0) + gasto.monto;
    }

    return resumen;
  }

  // Obtener total gastado en el mes actual
  double getTotalGastado() {
    final gastosMes = getGastosMesActual();
    return gastosMes.fold(0.0, (total, gasto) => total + gasto.monto);
  }

  // Obtener gastos del mes actual
  List<Gasto> getGastosMesActual() {
    final ahora = DateTime.now();
    final formatoMes = DateFormat('yyyy-MM');

    return state.where((gasto) {
      return formatoMes.format(gasto.fecha) == formatoMes.format(ahora);
    }).toList();
  }

  // ===== NUEVOS MÉTODOS PARA MANEJO POR MES SELECCIONADO =====

  /// Obtener gastos de un mes específico usando clave "YYYY-MM"
  List<Gasto> getGastosPorMes(String monthKey) {
    return state.where((gasto) => gasto.belongsToMonth(monthKey)).toList();
  }

  /// Obtener total gastado en un mes específico
  double getTotalGastadoPorMes(String monthKey) {
    final gastosMes = getGastosPorMes(monthKey);
    return gastosMes.fold(0.0, (total, gasto) => total + gasto.monto);
  }

  /// Obtener resumen de gastos por categorías de un mes específico
  Map<String, double> getResumenCategoriasPorMes(String monthKey) {
    final gastosMes = getGastosPorMes(monthKey);
    final Map<String, double> resumen = {};
    
    for (final gasto in gastosMes) {
      resumen[gasto.categoria] = (resumen[gasto.categoria] ?? 0.0) + gasto.monto;
    }
    
    return resumen;
  }

  /// Obtener gastos recientes de un mes específico (últimos 5)
  List<Gasto> getGastosRecientesPorMes(String monthKey) {
    final gastosMes = getGastosPorMes(monthKey);
    gastosMes.sort((a, b) => b.fecha.compareTo(a.fecha));
    return gastosMes.take(5).toList();
  }

  /// Obtener lista de todos los meses que tienen gastos
  List<String> getMesesConGastos() {
    final Set<String> meses = {};
    for (final gasto in state) {
      meses.add(gasto.getMonthKey());
    }
    final listaOrdenada = meses.toList();
    listaOrdenada.sort((a, b) => b.compareTo(a)); // Más reciente primero
    return listaOrdenada;
  }

  /// Verificar si un mes tiene gastos
  bool mestieneGastos(String monthKey) {
    return state.any((gasto) => gasto.belongsToMonth(monthKey));
  }

  // Limpiar todos los gastos (útil para testing)
  Future<void> clearAll() async {
    try {
      _appState.notifySaving('Eliminando todos los gastos...');
      
      state = [];
      await _gastosBox.clear();
      
      _appState.notifySaved();
      _appState.notifyDataUpdate(
        DataUpdateType.dataCleared, 
        'Todos los gastos han sido eliminados'
      );
    } catch (e) {
      _appState.notifyError('Error al eliminar gastos: $e');
      rethrow;
    }
  }

  // Método para reiniciar completamente la app (eliminar TODOS los datos)
  Future<void> reiniciarTodosDatos() async {
    try {
      _appState.notifySaving('Reiniciando todos los datos...');
      
      print('🔄 Iniciando reinicio de datos...');
      
      // Limpiar gastos del estado y caja
      state = [];
      await _gastosBox.clear();
      print('✅ Gastos eliminados');
      
      // Intentar limpiar las otras cajas de forma más segura
      await _limpiarCajasAdicionales();
      
      _appState.notifySaved();
      _appState.notifyDataUpdate(
        DataUpdateType.dataCleared, 
        'Todos los datos han sido reiniciados'
      );
      
      print('✅ Todos los datos han sido eliminados correctamente');
    } catch (e) {
      _appState.notifyError('Error al reiniciar datos: $e');
      print('❌ Error al eliminar datos: $e');
      rethrow; // Re-lanzar el error para que se maneje en la UI
    }
  }

  // Método auxiliar para limpiar otras cajas de forma segura
  Future<void> _limpiarCajasAdicionales() async {
    final List<String> cajasParaLimpiar = ['presupuestos', 'presupuestos_config'];
    
    for (final nombreCaja in cajasParaLimpiar) {
      try {
        if (Hive.isBoxOpen(nombreCaja)) {
          final caja = Hive.box(nombreCaja);
          await caja.clear();
          print('✅ Caja "$nombreCaja" eliminada');
        } else {
          print('ℹ️ Caja "$nombreCaja" no está abierta');
        }
      } catch (e) {
        print('⚠️ Error limpiando caja "$nombreCaja": $e');
        // Continuar con las demás cajas aunque una falle
      }
    }
  }

  // Método para migrar IDs corruptos (para usuarios con problemas existentes)
  Future<void> migrarIdsCorruptos() async {
    try {
      _appState.notifySaving('Migrando datos corruptos...');
      
      final gastosExistentes = _gastosBox.values.toList();
      
      // Limpiar la base de datos
      await _gastosBox.clear();
      
      // Volver a agregar todos los gastos con IDs secuenciales
      int nuevoId = 1;
      for (final gasto in gastosExistentes) {
        gasto.id = nuevoId++;
        await _gastosBox.put(gasto.id, gasto);
      }
      
      // Actualizar el estado
      _cargarGastos();
      
      _appState.notifySaved();
      _appState.notifyDataUpdate(
        DataUpdateType.dataMigrated, 
        'Datos migrados exitosamente'
      );
    } catch (e) {
      _appState.notifyError('Error en migración: $e');
      // En caso de error, simplemente limpiar todo
      await clearAll();
    }
  }
}

// Provider para formatear gastos con la moneda correcta
final gastosFormateadosProvider = Provider.family<String, Gasto>((ref, gasto) {
  // Si el gasto tiene una moneda específica, usarla
  if (gasto.currencyCode != null) {
    final currency = AvailableCurrencies.findByCode(gasto.currencyCode!);
    if (currency != null) {
      return currency.formatAmount(gasto.monto);
    }
  }
  
  // Si no, usar la moneda actual
  final currentCurrency = ref.watch(currencyProvider);
  return currentCurrency.formatAmount(gasto.monto);
});

// Provider para obtener el total de gastos formateado
final totalGastosProvider = Provider<String>((ref) {
  final gastos = ref.watch(gastosProvider);
  final currentCurrency = ref.watch(currencyProvider);
  
  final total = gastos.fold<double>(0.0, (sum, gasto) => sum + gasto.monto);
  return currentCurrency.formatAmount(total);
});

// Provider para obtener gastos del mes actual formateados
final gastosDelMesProvider = Provider<String>((ref) {
  final gastos = ref.watch(gastosProvider);
  final currentCurrency = ref.watch(currencyProvider);
  final now = DateTime.now();
  
  final gastosDelMes = gastos.where((gasto) => 
    gasto.fecha.year == now.year && gasto.fecha.month == now.month
  );
  
  final total = gastosDelMes.fold<double>(0.0, (sum, gasto) => sum + gasto.monto);
  return currentCurrency.formatAmount(total);
});

// Provider para obtener gastos por categoría formateados
final gastosPorCategoriaProvider = Provider<Map<String, String>>((ref) {
  final gastos = ref.watch(gastosProvider);
  final currentCurrency = ref.watch(currencyProvider);
  
  final Map<String, double> totales = {};
  
  for (final gasto in gastos) {
    totales[gasto.categoria] = (totales[gasto.categoria] ?? 0) + gasto.monto;
  }
  
  return totales.map((categoria, total) => 
    MapEntry(categoria, currentCurrency.formatAmount(total))
  );
});

// ===== NUEVOS PROVIDERS PARA MES SELECCIONADO =====

/// Provider para gastos del mes seleccionado
final gastosDelMesSeleccionadoProvider = Provider<List<Gasto>>((ref) {
  final gastos = ref.watch(gastosProvider);
  final monthKey = ref.watch(currentMonthKeyProvider);
  
  // Filtrar gastos por el mes seleccionado
  return gastos.where((gasto) {
    final gastoKey = '${gasto.fecha.year}-${gasto.fecha.month.toString().padLeft(2, '0')}';
    return gastoKey == monthKey;
  }).toList();
});

/// Provider para total gastado del mes seleccionado
final totalGastadoMesSeleccionadoProvider = Provider<double>((ref) {
  final gastosDelMes = ref.watch(gastosDelMesSeleccionadoProvider);
  return gastosDelMes.fold<double>(0.0, (sum, gasto) => sum + gasto.monto);
});

/// Provider para total gastado formateado del mes seleccionado
final totalGastadoMesSeleccionadoFormateadoProvider = Provider<String>((ref) {
  final total = ref.watch(totalGastadoMesSeleccionadoProvider);
  final currentCurrency = ref.watch(currencyProvider);
  return currentCurrency.formatAmount(total);
});

/// Provider para resumen de categorías del mes seleccionado
final resumenCategoriasMesSeleccionadoProvider = Provider<Map<String, double>>((ref) {
  final gastosDelMes = ref.watch(gastosDelMesSeleccionadoProvider);
  
  final Map<String, double> resumen = {};
  for (final gasto in gastosDelMes) {
    resumen[gasto.categoria] = (resumen[gasto.categoria] ?? 0.0) + gasto.monto;
  }
  return resumen;
});

/// Provider para gastos recientes del mes seleccionado
final gastosRecientesMesSeleccionadoProvider = Provider<List<Gasto>>((ref) {
  final gastosDelMes = ref.watch(gastosDelMesSeleccionadoProvider);
  
  // Ordenar por fecha descendente y tomar los más recientes
  final gastosOrdenados = List<Gasto>.from(gastosDelMes)
    ..sort((a, b) => b.fecha.compareTo(a.fecha));
  
  return gastosOrdenados.take(10).toList();
});

/// Provider para verificar si el mes seleccionado tiene gastos
final mesSeleccionadoTieneGastosProvider = Provider<bool>((ref) {
  final gastosDelMes = ref.watch(gastosDelMesSeleccionadoProvider);
  return gastosDelMes.isNotEmpty;
});