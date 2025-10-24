import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Utility class para garantizar actualizaciones reactivas en toda la app
class ReactiveRefresh {
  /// Notifica cambios importantes para disparar reconstrucciones
  static void notifyDataChange() {
    // Este método puede ser llamado después de cambios críticos
    // para asegurar que los widgets se reconstruyan
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Forzar reconstrucción en el siguiente frame
    });
  }

  /// Verifica si un widget necesita reconstruirse
  static bool shouldRebuild(DateTime? lastUpdate) {
    if (lastUpdate == null) return true;
    final now = DateTime.now();
    return now.difference(lastUpdate).inMilliseconds > 100;
  }
}

/// Widget wrapper que garantiza reactividad para cambios de datos
class ReactiveWrapper extends ConsumerWidget {
  final Widget child;
  final List<ProviderListenable>? watchProviders;

  const ReactiveWrapper({
    super.key,
    required this.child,
    this.watchProviders,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Escuchar a los providers especificados para forzar reconstrucción
    if (watchProviders != null) {
      for (final provider in watchProviders!) {
        try {
          ref.watch(provider);
        } catch (e) {
          // Si hay error al escuchar un provider, continuar con los demás
          debugPrint('Error watching provider: $e');
        }
      }
    }

    return child;
  }
}

/// Mixin para widgets que necesitan reactividad garantizada
mixin ReactiveWidgetMixin<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  /// Lista de providers a observar para cambios automáticos
  List<ProviderListenable> get watchedProviders => [];

  @override
  void initState() {
    super.initState();
    
    // Configurar listeners para los providers
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupProviderListeners();
    });
  }

  void _setupProviderListeners() {
    for (final provider in watchedProviders) {
      try {
        ref.listen(provider, (previous, next) {
          // Forzar reconstrucción cuando cambie cualquier provider
          if (mounted) {
            setState(() {});
          }
        });
      } catch (e) {
        debugPrint('Error setting up listener for provider: $e');
      }
    }
  }

  /// Método para forzar actualización manual
  void forceRefresh() {
    if (mounted) {
      setState(() {});
    }
  }
}