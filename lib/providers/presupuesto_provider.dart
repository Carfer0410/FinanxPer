import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:convert';
import 'gastos_provider.dart'; // Importar para acceder al gastosProvider
import 'currency_provider.dart';
import 'date_provider.dart';
import 'app_state_provider.dart';

// Provider para manejar el estado de presupuestos
final presupuestoProvider = StateNotifierProvider<PresupuestoNotifier, Map<String, double>>((ref) {
  return PresupuestoNotifier(ref);
});

// Provider combinado para calcular progreso de gastos vs presupuestos
final progresoGastosProvider = Provider<Map<String, double>>((ref) {
  final gastos = ref.watch(gastosProvider);
  final presupuestos = ref.watch(presupuestoProvider);

  final Map<String, double> progreso = {};

  // Calcular gastos por categoría en el mes actual
  final gastosPorCategoria = <String, double>{};
  final ahora = DateTime.now();
  final mesActual = '${ahora.year}-${ahora.month.toString().padLeft(2, '0')}';

  for (final gasto in gastos) {
    final mesGasto = '${gasto.fecha.year}-${gasto.fecha.month.toString().padLeft(2, '0')}';
    if (mesGasto == mesActual) {
      gastosPorCategoria[gasto.categoria] = (gastosPorCategoria[gasto.categoria] ?? 0) + gasto.monto;
    }
  }

  // Calcular progreso para cada categoría
  for (final categoria in presupuestos.keys) {
    final presupuesto = presupuestos[categoria] ?? 0.0;
    final gastado = gastosPorCategoria[categoria] ?? 0.0;

    if (presupuesto > 0) {
      progreso[categoria] = gastado / presupuesto;
    } else {
      progreso[categoria] = 0.0;
    }
  }

  return progreso;
});

class PresupuestoNotifier extends StateNotifier<Map<String, double>> {
  final Ref? ref;
  
  // Constructor: inicializa con datos de Hive o valores por defecto
  PresupuestoNotifier([this.ref]) : super({}) {
    _cargarPresupuestos();
  }

  // Caja de Hive para persistencia (usaremos una caja simple para el mapa)
  Box<String>? get _presupuestosBox {
    try {
      return Hive.box<String>('presupuestos_config');
    } catch (e) {
      // Si la caja no está abierta aún, devolver null
      return null;
    }
  }

  // Obtener notificador de estado global
  AppStateNotifier? get _appState => ref?.read(appStateProvider.notifier);

  // Cargar presupuestos desde Hive al inicializar
  void _cargarPresupuestos() {
    final box = _presupuestosBox;
    if (box == null) {
      // Si la caja no está abierta aún, usar valores por defecto
      _inicializarValoresPorDefecto();
      return;
    }

    final datosGuardados = box.get('presupuestos_map');

    if (datosGuardados != null) {
      try {
        // Convertir JSON string de vuelta a Map
        final Map<String, dynamic> datosJson = json.decode(datosGuardados);
        final Map<String, double> presupuestos = {};

        datosJson.forEach((key, value) {
          if (value is num) {
            presupuestos[key] = value.toDouble();
          }
        });

        state = presupuestos;
        
        // Migrar datos del mes actual si es necesario
        _migrarDatosMesActual();
      } catch (e) {
        // Si hay error, usar valores por defecto
        _inicializarValoresPorDefecto();
      }
    } else {
      // Si no hay datos guardados, inicializar con valores por defecto
      _inicializarValoresPorDefecto();
    }
  }

  // Migrar datos del formato viejo al formato consistente por mes
  void _migrarDatosMesActual() {
    final now = DateTime.now();
    final currentMonthKey = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    
    // Lista de categorías que podrían estar en formato viejo
    final categorias = ['total', 'Comida', 'Transporte', 'Entretenimiento', 'Vivienda', 
                       'Salud', 'Educación', 'Ropa', 'Tecnología', 'Otros'];
    
    bool datosModificados = false;
    final Map<String, double> nuevoState = Map<String, double>.from(state);
    
    for (final categoria in categorias) {
      final valorViejo = state[categoria];
      final claveNueva = '${currentMonthKey}_$categoria';
      final valorNuevo = state[claveNueva];
      
      // Si existe dato en formato viejo pero no en formato nuevo, migrar
      if (valorViejo != null && valorViejo > 0 && (valorNuevo == null || valorNuevo == 0)) {
        nuevoState[claveNueva] = valorViejo;
        nuevoState.remove(categoria); // Eliminar clave vieja
        datosModificados = true;
      }
    }
    
    if (datosModificados) {
      state = nuevoState;
      _guardarPresupuestos();
    }
  }

  // Inicializar con valores por defecto para todas las categorías
  void _inicializarValoresPorDefecto() {
    state = {
      'total': 0.0,
      'Comida': 0.0,
      'Transporte': 0.0,
      'Vivienda': 0.0,
      'Salud': 0.0,
      'Entretenimiento': 0.0,
      'Educación': 0.0,
      'Ropa': 0.0,
      'Tecnología': 0.0,
      'Otros': 0.0,
    };
    _guardarPresupuestos();
  }

  // Guardar presupuestos en Hive
  void _guardarPresupuestos() {
    final box = _presupuestosBox;
    if (box == null) return; // Si la caja no está abierta, no guardar

    final datosJson = json.encode(state);
    box.put('presupuestos_map', datosJson);
  }

  // Establecer presupuesto para una categoría específica
  Future<void> setPresupuesto(String key, double value) async {
    try {
      _appState?.notifySaving('Actualizando presupuesto...');
      
      state = {...state, key: value};
      _guardarPresupuestos();
      
      _appState?.notifySaved();
      _appState?.notifyDataUpdate(
        DataUpdateType.presupuestoUpdated, 
        'Presupuesto actualizado exitosamente'
      );
    } catch (e) {
      _appState?.notifyError('Error al actualizar presupuesto: $e');
      rethrow;
    }
  }

  // Establecer presupuesto para el mes actualmente seleccionado
  Future<void> setPresupuestoMesSeleccionado(String monthKey, String categoria, double value) async {
    // Siempre usar el método específico por mes para consistencia
    setPresupuestoPorMes(monthKey, categoria, value);
  }

  // Obtener presupuesto total
  double getPresupuestoTotal() {
    return state['total'] ?? 0.0;
  }

  // Establecer presupuesto total
  Future<void> setPresupuestoTotal(double value) async {
    await setPresupuesto('total', value);
  }

  // Resetear todos los presupuestos
  Future<void> resetPresupuestos() async {
    try {
      _appState?.notifySaving('Reiniciando presupuestos...');
      
      _inicializarValoresPorDefecto();
      
      _appState?.notifySaved();
      _appState?.notifyDataUpdate(
        DataUpdateType.dataCleared, 
        'Presupuestos reiniciados exitosamente'
      );
    } catch (e) {
      _appState?.notifyError('Error al reiniciar presupuestos: $e');
      rethrow;
    }
  }

  // Obtener presupuesto para una categoría específica
  double getPresupuestoCategoria(String categoria) {
    return state[categoria] ?? 0.0;
  }

  // ===== NUEVOS MÉTODOS PARA PRESUPUESTOS POR MES =====

  /// Obtener presupuesto de un mes específico
  Map<String, double> getPresupuestosPorMes(String monthKey) {
    final Map<String, double> presupuestosMes = {};
    
    // Buscar claves que coincidan con el mes
    for (final entry in state.entries) {
      if (entry.key.startsWith('${monthKey}_')) {
        final categoria = entry.key.substring(monthKey.length + 1);
        presupuestosMes[categoria] = entry.value;
      }
    }
    
    // Si no hay presupuestos para ese mes, devolver valores por defecto
    if (presupuestosMes.isEmpty) {
      return {
        'total': 0.0,
        'Comida': 0.0,
        'Transporte': 0.0,
        'Vivienda': 0.0,
        'Salud': 0.0,
        'Entretenimiento': 0.0,
        'Educación': 0.0,
        'Ropa': 0.0,
        'Tecnología': 0.0,
        'Otros': 0.0,
      };
    }
    
    return presupuestosMes;
  }

  /// Establecer presupuesto para un mes específico
  Future<void> setPresupuestoPorMes(String monthKey, String categoria, double value) async {
    try {
      _appState?.notifySaving('Actualizando presupuesto...');
      
      final key = '${monthKey}_$categoria';
      state = {...state, key: value};
      _guardarPresupuestos();
      
      _appState?.notifySaved();
      _appState?.notifyDataUpdate(
        DataUpdateType.presupuestoUpdated, 
        'Presupuesto de $categoria actualizado'
      );
    } catch (e) {
      _appState?.notifyError('Error al actualizar presupuesto: $e');
      rethrow;
    }
  }

  /// Copiar presupuestos de un mes a otro
  Future<void> copiarPresupuestosDeMes(String fromMonthKey, String toMonthKey) async {
    try {
      _appState?.notifySaving('Copiando presupuestos...');
      
      final presupuestosOrigen = getPresupuestosPorMes(fromMonthKey);
      
      for (final entry in presupuestosOrigen.entries) {
        if (entry.value > 0) { // Solo copiar presupuestos que tengan valor
          setPresupuestoPorMes(toMonthKey, entry.key, entry.value);
        }
      }
      
      _appState?.notifySaved();
      _appState?.notifyDataUpdate(
        DataUpdateType.presupuestoUpdated, 
        'Presupuestos copiados exitosamente'
      );
    } catch (e) {
      _appState?.notifyError('Error al copiar presupuestos: $e');
      rethrow;
    }
  }

  /// Obtener presupuesto total de un mes específico
  double getPresupuestoTotalPorMes(String monthKey) {
    return state['${monthKey}_total'] ?? 0.0;
  }

  /// Establecer presupuesto total para un mes específico
  Future<void> setPresupuestoTotalPorMes(String monthKey, double value) async {
    await setPresupuestoPorMes(monthKey, 'total', value);
  }

  /// Verificar si un mes tiene presupuestos configurados
  bool mesTienePresupuestos(String monthKey) {
    return state.keys.any((key) => key.startsWith('${monthKey}_'));
  }
}

// Provider para formatear presupuestos con la moneda actual
final presupuestosFormateadosProvider = Provider<Map<String, String>>((ref) {
  final presupuestos = ref.watch(presupuestoProvider);
  final currentCurrency = ref.watch(currencyProvider);
  
  return presupuestos.map((categoria, valor) => 
    MapEntry(categoria, currentCurrency.formatAmount(valor))
  );
});

// Provider para formatear presupuestos del mes seleccionado con la moneda actual
final presupuestosFormateadosMesSeleccionadoProvider = Provider<Map<String, String>>((ref) {
  final presupuestos = ref.watch(presupuestosMesSeleccionadoProvider);
  final currentCurrency = ref.watch(currencyProvider);
  
  return presupuestos.map((categoria, valor) => 
    MapEntry(categoria, currentCurrency.formatAmount(valor))
  );
});

// Provider para obtener el presupuesto total formateado
final presupuestoTotalFormateadoProvider = Provider<String>((ref) {
  final presupuestos = ref.watch(presupuestoProvider);
  final currentCurrency = ref.watch(currencyProvider);
  
  final total = presupuestos['total'] ?? 0.0;
  return currentCurrency.formatAmount(total);
});

// Provider para calcular el progreso de gastos vs presupuestos con formato
final progresoGastosFormateadoProvider = Provider<Map<String, Map<String, dynamic>>>((ref) {
  final gastos = ref.watch(gastosProvider);
  final presupuestos = ref.watch(presupuestoProvider);
  final currentCurrency = ref.watch(currencyProvider);

  final Map<String, Map<String, dynamic>> resultado = {};

  // Calcular gastos por categoría en el mes actual
  final gastosPorCategoria = <String, double>{};
  final ahora = DateTime.now();
  final mesActual = '${ahora.year}-${ahora.month.toString().padLeft(2, '0')}';

  for (final gasto in gastos) {
    final mesGasto = '${gasto.fecha.year}-${gasto.fecha.month.toString().padLeft(2, '0')}';
    if (mesGasto == mesActual) {
      gastosPorCategoria[gasto.categoria] = (gastosPorCategoria[gasto.categoria] ?? 0) + gasto.monto;
    }
  }

  // Calcular progreso para cada categoría
  for (final categoria in presupuestos.keys) {
    if (categoria == 'total') continue; // Saltar el total
    
    final presupuesto = presupuestos[categoria] ?? 0.0;
    final gastado = gastosPorCategoria[categoria] ?? 0.0;
    final progreso = presupuesto > 0 ? gastado / presupuesto : 0.0;
    final restante = presupuesto - gastado;

    resultado[categoria] = {
      'presupuesto': presupuesto,
      'gastado': gastado,
      'restante': restante,
      'progreso': progreso,
      'presupuestoFormateado': currentCurrency.formatAmount(presupuesto),
      'gastadoFormateado': currentCurrency.formatAmount(gastado),
      'restanteFormateado': currentCurrency.formatAmount(restante > 0 ? restante : 0.0),
      'excesoFormateado': restante < 0 ? currentCurrency.formatAmount(restante.abs()) : null,
    };
  }

  return resultado;
});

// ===== NUEVOS PROVIDERS PARA MES SELECCIONADO =====

/// Provider para presupuestos del mes seleccionado
final presupuestosMesSeleccionadoProvider = Provider<Map<String, double>>((ref) {
  // Observar el estado completo para detectar cambios
  ref.watch(presupuestoProvider);
  final presupuestosNotifier = ref.read(presupuestoProvider.notifier);
  final monthKey = ref.watch(currentMonthKeyProvider);
  return presupuestosNotifier.getPresupuestosPorMes(monthKey);
});

/// Provider para presupuesto total del mes seleccionado
final presupuestoTotalMesSeleccionadoProvider = Provider<double>((ref) {
  // Observar el estado completo para detectar cambios
  ref.watch(presupuestoProvider);
  final presupuestosNotifier = ref.read(presupuestoProvider.notifier);
  final monthKey = ref.watch(currentMonthKeyProvider);
  return presupuestosNotifier.getPresupuestoTotalPorMes(monthKey);
});

/// Provider para presupuesto total formateado del mes seleccionado
final presupuestoTotalMesSeleccionadoFormateadoProvider = Provider<String>((ref) {
  final total = ref.watch(presupuestoTotalMesSeleccionadoProvider);
  final currentCurrency = ref.watch(currencyProvider);
  return currentCurrency.formatAmount(total);
});

/// Provider para progreso de gastos del mes seleccionado
final progresoGastosMesSeleccionadoProvider = Provider<Map<String, double>>((ref) {
  final presupuestos = ref.watch(presupuestosMesSeleccionadoProvider);
  final resumenGastos = ref.watch(resumenCategoriasMesSeleccionadoProvider);

  final Map<String, double> progreso = {};

  // Calcular progreso para cada categoría
  for (final categoria in presupuestos.keys) {
    if (categoria == 'total') continue; // Saltar el total
    
    final presupuesto = presupuestos[categoria] ?? 0.0;
    final gastado = resumenGastos[categoria] ?? 0.0;
    
    if (presupuesto > 0) {
      progreso[categoria] = (gastado / presupuesto).clamp(0.0, 2.0); // Máximo 200%
    } else {
      progreso[categoria] = 0.0;
    }
  }

  return progreso;
});

/// Provider para verificar si el mes seleccionado tiene presupuestos
final mesSeleccionadoTienePresupuestosProvider = Provider<bool>((ref) {
  // Observar el estado completo para detectar cambios
  ref.watch(presupuestoProvider);
  final presupuestosNotifier = ref.read(presupuestoProvider.notifier);
  final monthKey = ref.watch(currentMonthKeyProvider);
  return presupuestosNotifier.mesTienePresupuestos(monthKey);
});