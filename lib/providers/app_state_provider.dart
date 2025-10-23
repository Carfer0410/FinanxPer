import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider para manejar el estado global de la aplicación y notificaciones
class AppStateNotifier extends StateNotifier<AppState> {
  AppStateNotifier() : super(const AppState());

  /// Notificar que los datos han sido actualizados
  void notifyDataUpdate(DataUpdateType type, String message) {
    state = state.copyWith(
      lastUpdateType: type,
      lastUpdateMessage: message,
      lastUpdateTime: DateTime.now(),
    );
    
    // Limpiar el mensaje después de un tiempo
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        state = state.copyWith(
          lastUpdateMessage: null,
          lastUpdateType: null,
        );
      }
    });
  }

  /// Notificar que se está guardando datos
  void notifySaving(String operation) {
    state = state.copyWith(
      isSaving: true,
      currentOperation: operation,
    );
  }

  /// Notificar que se terminó de guardar
  void notifySaved() {
    state = state.copyWith(
      isSaving: false,
      currentOperation: null,
    );
  }

  /// Notificar error
  void notifyError(String error) {
    state = state.copyWith(
      lastError: error,
      lastErrorTime: DateTime.now(),
    );
    
    // Limpiar el error después de un tiempo
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        state = state.copyWith(
          lastError: null,
          lastErrorTime: null,
        );
      }
    });
  }

  /// Forzar actualización de toda la UI
  void forceUIRefresh() {
    state = state.copyWith(
      refreshCounter: state.refreshCounter + 1,
    );
  }
}

/// Estado de la aplicación
class AppState {
  final DataUpdateType? lastUpdateType;
  final String? lastUpdateMessage;
  final DateTime? lastUpdateTime;
  final bool isSaving;
  final String? currentOperation;
  final String? lastError;
  final DateTime? lastErrorTime;
  final int refreshCounter;

  const AppState({
    this.lastUpdateType,
    this.lastUpdateMessage,
    this.lastUpdateTime,
    this.isSaving = false,
    this.currentOperation,
    this.lastError,
    this.lastErrorTime,
    this.refreshCounter = 0,
  });

  AppState copyWith({
    DataUpdateType? lastUpdateType,
    String? lastUpdateMessage,
    DateTime? lastUpdateTime,
    bool? isSaving,
    String? currentOperation,
    String? lastError,
    DateTime? lastErrorTime,
    int? refreshCounter,
  }) {
    return AppState(
      lastUpdateType: lastUpdateType ?? this.lastUpdateType,
      lastUpdateMessage: lastUpdateMessage ?? this.lastUpdateMessage,
      lastUpdateTime: lastUpdateTime ?? this.lastUpdateTime,
      isSaving: isSaving ?? this.isSaving,
      currentOperation: currentOperation ?? this.currentOperation,
      lastError: lastError ?? this.lastError,
      lastErrorTime: lastErrorTime ?? this.lastErrorTime,
      refreshCounter: refreshCounter ?? this.refreshCounter,
    );
  }
}

/// Tipos de actualizaciones de datos
enum DataUpdateType {
  gastoAdded('Gasto agregado'),
  gastoDeleted('Gasto eliminado'),
  gastoUpdated('Gasto actualizado'),
  presupuestoUpdated('Presupuesto actualizado'),
  currencyChanged('Moneda cambiada'),
  monthChanged('Mes cambiado'),
  dataCleared('Datos eliminados'),
  dataMigrated('Datos migrados');

  const DataUpdateType(this.description);
  final String description;
}

/// Provider para el estado global de la aplicación
final appStateProvider = StateNotifierProvider<AppStateNotifier, AppState>((ref) {
  return AppStateNotifier();
});

/// Provider para verificar si se está guardando
final isSavingProvider = Provider<bool>((ref) {
  return ref.watch(appStateProvider).isSaving;
});

/// Provider para obtener el último mensaje de actualización
final lastUpdateMessageProvider = Provider<String?>((ref) {
  return ref.watch(appStateProvider).lastUpdateMessage;
});

/// Provider para obtener el último error
final lastErrorProvider = Provider<String?>((ref) {
  return ref.watch(appStateProvider).lastError;
});

/// Provider para forzar actualizaciones globales
final globalRefreshProvider = Provider<int>((ref) {
  return ref.watch(appStateProvider).refreshCounter;
});