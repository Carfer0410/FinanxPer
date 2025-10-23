import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auto_save_provider.dart';
import '../providers/app_state_provider.dart';

/// Widget que muestra el estado del auto-guardado
class AutoSaveIndicator extends ConsumerWidget {
  final bool compact;

  const AutoSaveIndicator({
    super.key,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final autoSaveState = ref.watch(autoSaveProvider);
    final appState = ref.watch(appStateProvider);

    // No mostrar nada si no hay actividad
    if (!autoSaveState.hasPendingChanges && 
        !autoSaveState.isSaving && 
        !appState.isSaving &&
        autoSaveState.lastSaveTime == null) {
      return const SizedBox.shrink();
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: compact 
          ? const EdgeInsets.symmetric(horizontal: 8, vertical: 4)
          : const EdgeInsets.all(8),
      padding: compact 
          ? const EdgeInsets.symmetric(horizontal: 8, vertical: 4)
          : const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _getBackgroundColor(autoSaveState, appState),
        borderRadius: BorderRadius.circular(compact ? 4 : 8),
        border: Border.all(
          color: _getBorderColor(autoSaveState, appState),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildIcon(autoSaveState, appState, compact),
          SizedBox(width: compact ? 4 : 8),
          if (!compact) ...[
            Flexible(
              child: Text(
                _getText(autoSaveState, appState),
                style: TextStyle(
                  color: _getTextColor(autoSaveState, appState),
                  fontSize: compact ? 11 : 12,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ] else ...[
            Text(
              _getCompactText(autoSaveState, appState),
              style: TextStyle(
                color: _getTextColor(autoSaveState, appState),
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildIcon(AutoSaveState autoSaveState, AppState appState, bool compact) {
    final size = compact ? 12.0 : 16.0;

    if (autoSaveState.isSaving || appState.isSaving) {
      return SizedBox(
        width: size,
        height: size,
        child: CircularProgressIndicator(
          strokeWidth: compact ? 1.5 : 2,
          color: Colors.blue[600],
        ),
      );
    }

    if (autoSaveState.hasPendingChanges) {
      return Icon(
        Icons.schedule,
        size: size,
        color: Colors.orange[600],
      );
    }

    if (autoSaveState.lastSaveTime != null) {
      return Icon(
        Icons.check_circle,
        size: size,
        color: Colors.green[600],
      );
    }

    return Icon(
      Icons.info,
      size: size,
      color: Colors.grey[600],
    );
  }

  Color _getBackgroundColor(AutoSaveState autoSaveState, AppState appState) {
    if (autoSaveState.isSaving || appState.isSaving) {
      return Colors.blue[50]!;
    }
    
    if (autoSaveState.hasPendingChanges) {
      return Colors.orange[50]!;
    }
    
    return Colors.green[50]!;
  }

  Color _getBorderColor(AutoSaveState autoSaveState, AppState appState) {
    if (autoSaveState.isSaving || appState.isSaving) {
      return Colors.blue[200]!;
    }
    
    if (autoSaveState.hasPendingChanges) {
      return Colors.orange[200]!;
    }
    
    return Colors.green[200]!;
  }

  Color _getTextColor(AutoSaveState autoSaveState, AppState appState) {
    if (autoSaveState.isSaving || appState.isSaving) {
      return Colors.blue[700]!;
    }
    
    if (autoSaveState.hasPendingChanges) {
      return Colors.orange[700]!;
    }
    
    return Colors.green[700]!;
  }

  String _getText(AutoSaveState autoSaveState, AppState appState) {
    if (autoSaveState.isSaving) {
      return 'Guardando automáticamente...';
    }
    
    if (appState.isSaving) {
      return appState.currentOperation ?? 'Guardando...';
    }
    
    if (autoSaveState.hasPendingChanges) {
      return 'Cambios pendientes de guardar';
    }
    
    if (autoSaveState.lastSaveTime != null) {
      final diff = DateTime.now().difference(autoSaveState.lastSaveTime!);
      if (diff.inSeconds < 60) {
        return 'Guardado hace ${diff.inSeconds}s';
      } else if (diff.inMinutes < 60) {
        return 'Guardado hace ${diff.inMinutes}m';
      } else {
        return 'Guardado hace ${diff.inHours}h';
      }
    }
    
    return 'Listo';
  }

  String _getCompactText(AutoSaveState autoSaveState, AppState appState) {
    if (autoSaveState.isSaving || appState.isSaving) {
      return 'Guardando...';
    }
    
    if (autoSaveState.hasPendingChanges) {
      return 'Pendiente';
    }
    
    return 'OK';
  }
}

/// Widget flotante que muestra el estado de guardado
class FloatingAutoSaveIndicator extends ConsumerWidget {
  const FloatingAutoSaveIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final autoSaveState = ref.watch(autoSaveProvider);
    final appState = ref.watch(appStateProvider);

    // Solo mostrar cuando hay actividad
    if (!autoSaveState.hasPendingChanges && 
        !autoSaveState.isSaving && 
        !appState.isSaving) {
      return const SizedBox.shrink();
    }

    return Positioned(
      top: MediaQuery.of(context).padding.top + 60,
      right: 16,
      child: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: const AutoSaveIndicator(compact: true),
        ),
      ),
    );
  }
}