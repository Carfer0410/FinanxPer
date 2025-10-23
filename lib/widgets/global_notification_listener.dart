import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_state_provider.dart';
import 'auto_save_indicator.dart';

/// Widget que escucha los cambios del estado global y muestra notificaciones
class GlobalNotificationListener extends ConsumerWidget {
  final Widget child;

  const GlobalNotificationListener({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Escuchar cambios en el estado global
    ref.listen<AppState>(appStateProvider, (previous, next) {
      // Mostrar mensaje de actualización si existe
      if (next.lastUpdateMessage != null && 
          next.lastUpdateMessage != previous?.lastUpdateMessage) {
        _showUpdateNotification(context, next.lastUpdateMessage!, next.lastUpdateType);
      }

      // Mostrar error si existe
      if (next.lastError != null && 
          next.lastError != previous?.lastError) {
        _showErrorNotification(context, next.lastError!);
      }
    });

    final appState = ref.watch(appStateProvider);

    return Stack(
      children: [
        child,
        // Indicador de carga global
        if (appState.isSaving)
          _buildSavingOverlay(appState.currentOperation),
        // Indicador flotante de auto-guardado
        const FloatingAutoSaveIndicator(),
      ],
    );
  }

  void _showUpdateNotification(BuildContext context, String message, DataUpdateType? type) {
    if (!context.mounted) return;

    final icon = _getIconForUpdateType(type);
    final color = _getColorForUpdateType(type);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showErrorNotification(BuildContext context, String error) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                error,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red[600],
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        margin: const EdgeInsets.all(16),
        action: SnackBarAction(
          label: 'Cerrar',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  IconData _getIconForUpdateType(DataUpdateType? type) {
    switch (type) {
      case DataUpdateType.gastoAdded:
        return Icons.add_circle;
      case DataUpdateType.gastoDeleted:
        return Icons.delete;
      case DataUpdateType.gastoUpdated:
        return Icons.edit;
      case DataUpdateType.presupuestoUpdated:
        return Icons.savings;
      case DataUpdateType.currencyChanged:
        return Icons.currency_exchange;
      case DataUpdateType.monthChanged:
        return Icons.calendar_month;
      case DataUpdateType.dataCleared:
        return Icons.clear_all;
      case DataUpdateType.dataMigrated:
        return Icons.upgrade;
      default:
        return Icons.check_circle;
    }
  }

  Color _getColorForUpdateType(DataUpdateType? type) {
    switch (type) {
      case DataUpdateType.gastoAdded:
        return Colors.green[600]!;
      case DataUpdateType.gastoDeleted:
        return Colors.orange[600]!;
      case DataUpdateType.gastoUpdated:
        return Colors.blue[600]!;
      case DataUpdateType.presupuestoUpdated:
        return Colors.purple[600]!;
      case DataUpdateType.currencyChanged:
        return Colors.teal[600]!;
      case DataUpdateType.monthChanged:
        return Colors.indigo[600]!;
      case DataUpdateType.dataCleared:
        return Colors.red[600]!;
      case DataUpdateType.dataMigrated:
        return Colors.amber[600]!;
      default:
        return Colors.green[600]!;
    }
  }

  Widget _buildSavingOverlay(String? operation) {
    return Container(
      color: Colors.black26,
      child: Center(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  operation ?? 'Guardando...',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Widget compacto para mostrar el estado de la última actualización
class CompactUpdateIndicator extends ConsumerWidget {
  const CompactUpdateIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appState = ref.watch(appStateProvider);

    if (appState.lastUpdateMessage == null && !appState.isSaving) {
      return const SizedBox.shrink();
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: appState.isSaving 
            ? Colors.blue[50] 
            : Colors.green[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: appState.isSaving 
              ? Colors.blue[200]! 
              : Colors.green[200]!,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (appState.isSaving) ...[
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.blue[600],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              appState.currentOperation ?? 'Guardando...',
              style: TextStyle(
                color: Colors.blue[700],
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ] else if (appState.lastUpdateMessage != null) ...[
            Icon(
              Icons.check_circle,
              size: 16,
              color: Colors.green[600],
            ),
            const SizedBox(width: 8),
            Text(
              appState.lastUpdateMessage!,
              style: TextStyle(
                color: Colors.green[700],
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Botón con indicador de guardado integrado
class SaveButton extends ConsumerWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;

  const SaveButton({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSaving = ref.watch(isSavingProvider);

    return ElevatedButton.icon(
      onPressed: isSaving ? null : onPressed,
      icon: isSaving 
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(icon ?? Icons.save),
      label: Text(isSaving ? 'Guardando...' : text),
    );
  }
}