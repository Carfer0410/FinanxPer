import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import 'app_state_provider.dart';

/// Provider para manejar el auto-guardado de datos
class AutoSaveNotifier extends StateNotifier<AutoSaveState> {
  AutoSaveNotifier(this.ref) : super(const AutoSaveState());

  final Ref ref;
  Timer? _saveTimer;
  final Duration _saveDelay = const Duration(milliseconds: 500);

  /// Programar un auto-guardado
  void scheduleSave(String operation, Future<void> Function() saveFunction) {
    // Cancelar timer anterior si existe
    _saveTimer?.cancel();

    // Actualizar estado para mostrar que hay cambios pendientes
    state = state.copyWith(
      hasPendingChanges: true,
      lastOperation: operation,
    );

    // Programar guardado después del delay
    _saveTimer = Timer(_saveDelay, () async {
      try {
        state = state.copyWith(isSaving: true);
        
        await saveFunction();
        
        state = state.copyWith(
          isSaving: false,
          hasPendingChanges: false,
          lastSaveTime: DateTime.now(),
        );
        
        ref.read(appStateProvider.notifier).notifyDataUpdate(
          DataUpdateType.gastoUpdated,
          'Datos guardados automáticamente'
        );
      } catch (e) {
        state = state.copyWith(
          isSaving: false,
          lastError: e.toString(),
        );
        
        ref.read(appStateProvider.notifier).notifyError('Error en auto-guardado: $e');
      }
    });
  }

  /// Forzar guardado inmediato
  Future<void> forceSave(Future<void> Function() saveFunction) async {
    _saveTimer?.cancel();
    
    try {
      state = state.copyWith(isSaving: true);
      
      await saveFunction();
      
      state = state.copyWith(
        isSaving: false,
        hasPendingChanges: false,
        lastSaveTime: DateTime.now(),
      );
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        lastError: e.toString(),
      );
      rethrow;
    }
  }

  /// Cancelar auto-guardado pendiente
  void cancelPendingSave() {
    _saveTimer?.cancel();
    state = state.copyWith(hasPendingChanges: false);
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    super.dispose();
  }
}

/// Estado del auto-guardado
class AutoSaveState {
  final bool hasPendingChanges;
  final bool isSaving;
  final String? lastOperation;
  final DateTime? lastSaveTime;
  final String? lastError;

  const AutoSaveState({
    this.hasPendingChanges = false,
    this.isSaving = false,
    this.lastOperation,
    this.lastSaveTime,
    this.lastError,
  });

  AutoSaveState copyWith({
    bool? hasPendingChanges,
    bool? isSaving,
    String? lastOperation,
    DateTime? lastSaveTime,
    String? lastError,
  }) {
    return AutoSaveState(
      hasPendingChanges: hasPendingChanges ?? this.hasPendingChanges,
      isSaving: isSaving ?? this.isSaving,
      lastOperation: lastOperation ?? this.lastOperation,
      lastSaveTime: lastSaveTime ?? this.lastSaveTime,
      lastError: lastError ?? this.lastError,
    );
  }
}

/// Provider para el auto-guardado
final autoSaveProvider = StateNotifierProvider<AutoSaveNotifier, AutoSaveState>((ref) {
  return AutoSaveNotifier(ref);
});

/// Provider para verificar si hay cambios pendientes
final hasPendingChangesProvider = Provider<bool>((ref) {
  return ref.watch(autoSaveProvider).hasPendingChanges;
});

/// Provider para verificar si se está guardando automáticamente
final isAutoSavingProvider = Provider<bool>((ref) {
  return ref.watch(autoSaveProvider).isSaving;
});

/// Mixin para widgets que necesitan auto-guardado
mixin AutoSaveMixin {
  /// Programar auto-guardado con debounce
  void scheduleAutoSave(
    WidgetRef ref,
    String operation,
    Future<void> Function() saveFunction,
  ) {
    ref.read(autoSaveProvider.notifier).scheduleSave(operation, saveFunction);
  }

  /// Forzar guardado inmediato
  Future<void> forceAutoSave(
    WidgetRef ref,
    Future<void> Function() saveFunction,
  ) async {
    await ref.read(autoSaveProvider.notifier).forceSave(saveFunction);
  }

  /// Cancelar auto-guardado pendiente
  void cancelAutoSave(WidgetRef ref) {
    ref.read(autoSaveProvider.notifier).cancelPendingSave();
  }
}