import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/gastos_provider.dart';
import '../providers/presupuesto_provider.dart';
import '../providers/currency_provider.dart';
import 'currency_selection_screen.dart';

/// Pantalla de configuraciones de la aplicación
class ConfiguracionesScreen extends ConsumerWidget {
  const ConfiguracionesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuraciones'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _mostrarAyudaConfiguraciones(context),
            tooltip: 'Información de Configuraciones',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Sección de configuración de moneda
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.monetization_on, color: Colors.green.shade700),
                      const SizedBox(width: 8),
                      Text(
                        'Configuración de Moneda',
                        style: TextStyle(
                          fontSize: 18, 
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  const Text(
                    'Selecciona la moneda de tu país para calcular presupuestos y límites apropiados.',
                    style: TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  Consumer(
                    builder: (context, ref, child) {
                      final currentCurrency = ref.watch(currencyProvider);
                      return Row(
                        children: [
                          Text(
                            currentCurrency.flag,
                            style: const TextStyle(fontSize: 24),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  currentCurrency.country,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  '${currentCurrency.name} (${currentCurrency.symbol})',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: () => _navigateToCurrencySelection(context),
                            icon: const Icon(Icons.edit, size: 18),
                            label: const Text('Cambiar'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade600,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 20),

          // Sección de configuración y datos
          Card(
            elevation: 4,
            color: Colors.red.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.restore, color: Colors.red.shade700),
                      const SizedBox(width: 8),
                      Text(
                        'Reiniciar Datos',
                        style: TextStyle(
                          fontSize: 18, 
                          fontWeight: FontWeight.bold,
                          color: Colors.red.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  const Text(
                    '⚠️ Zona de peligro',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  const Text(
                    'Esta acción eliminará TODOS tus gastos, presupuestos y configuraciones. No se puede deshacer.',
                    style: TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                  const SizedBox(height: 16),
                  
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _mostrarDialogoReinicio(context, ref),
                      icon: const Icon(Icons.delete_forever),
                      label: const Text('Reiniciar Todos los Datos'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Información de la app
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue.shade700),
                      const SizedBox(width: 8),
                      Text(
                        'Información de la App',
                        style: TextStyle(
                          fontSize: 18, 
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  const Row(
                    children: [
                      Text('Versión: ', style: TextStyle(fontWeight: FontWeight.w600)),
                      Text('1.0.0'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  
                  const Row(
                    children: [
                      Text('Desarrollado para: ', style: TextStyle(fontWeight: FontWeight.w600)),
                      Text('Latinoamérica'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  
                  Row(
                    children: [
                      const Text('Monedas soportadas: ', style: TextStyle(fontWeight: FontWeight.w600)),
                      const Text('21+'),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // Método para navegar a la pantalla de selección de moneda
  void _navigateToCurrencySelection(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const CurrencySelectionScreen(isInitialSetup: false),
      ),
    );
  }

  // Método para mostrar diálogo de confirmación de reinicio
  void _mostrarDialogoReinicio(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      barrierDismissible: false, // No se puede cerrar tocando afuera
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.warning, color: Colors.red, size: 28),
              const SizedBox(width: 8),
              const Text('⚠️ Confirmación'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '¿Estás completamente seguro?',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text('Esta acción eliminará PERMANENTEMENTE:'),
              const SizedBox(height: 8),
              const Text('• Todos tus gastos registrados'),
              const Text('• Todos los presupuestos configurados'),
              const Text('• Toda la configuración de la app'),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: const Text(
                  '⚠️ ESTA ACCIÓN NO SE PUEDE DESHACER',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            // Botón Cancelar
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            
            // Segundo botón de confirmación
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _mostrarSegundaConfirmacion(context, ref);
              },
              child: Text(
                'Sí, eliminar todo',
                style: TextStyle(color: Colors.red.shade700),
              ),
            ),
          ],
        );
      },
    );
  }

  // Segunda confirmación (doble seguridad)
  void _mostrarSegundaConfirmacion(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('🔥 Última confirmación'),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Esta es tu ÚLTIMA oportunidad para cancelar.',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              Text('¿Realmente quieres eliminar todos tus datos?'),
            ],
          ),
          actions: [
            // Botón Cancelar (destacado)
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('NO, cancelar'),
            ),
            
            // Botón final de eliminación
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _ejecutarReinicio(context, ref);
              },
              child: const Text(
                'SÍ, eliminar definitivamente',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  // Ejecutar el reinicio real
  Future<void> _ejecutarReinicio(BuildContext context, WidgetRef ref) async {
    // Mostrar indicador de carga
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Eliminando todos los datos...'),
          ],
        ),
      ),
    );

    try {
      // Eliminar todos los datos con timeout
      await ref.read(gastosProvider.notifier).reiniciarTodosDatos()
          .timeout(Duration(seconds: 10));
      
      // También reiniciar presupuestos
      ref.read(presupuestoProvider.notifier).resetPresupuestos();
      
      // Verificar si el widget sigue montado antes de usar context
      if (context.mounted) {
        // Cerrar diálogo de carga
        Navigator.of(context).pop();
        
        // Mostrar confirmación de éxito
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Todos los datos han sido eliminados correctamente'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
      
    } catch (e) {
      // Verificar si el widget sigue montado antes de usar context
      if (context.mounted) {
        // Cerrar diálogo de carga
        Navigator.of(context).pop();
        
        // Mostrar error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error al eliminar datos: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  // Método para mostrar ayuda de la pantalla de configuraciones
  void _mostrarAyudaConfiguraciones(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.info, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              const Expanded(
                child: Text('⚙️ Guía de Configuraciones'),
              ),
            ],
          ),
          contentPadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.85,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Aquí puedes personalizar y controlar tu app:',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 16),
                  
                  // Configuración de Moneda
                  _buildInfoItem(
                    icon: Icons.monetization_on,
                    color: Colors.green,
                    title: 'Configuración de Moneda',
                    description: 'Cambia la moneda de tu país para cálculos precisos de presupuesto.',
                  ),
                  
                  // Moneda Actual
                  _buildInfoItem(
                    icon: Icons.flag,
                    color: Colors.blue,
                    title: 'Moneda Actual',
                    description: 'Muestra tu moneda seleccionada con bandera, país y símbolo.',
                  ),
                  
                  // Botón Cambiar Moneda
                  _buildInfoItem(
                    icon: Icons.edit,
                    color: Colors.orange,
                    title: 'Cambiar Moneda',
                    description: 'Accede a la lista completa de monedas latinoamericanas.',
                  ),
                  
                  // Reiniciar Datos
                  _buildInfoItem(
                    icon: Icons.restore,
                    color: Colors.red,
                    title: 'Reiniciar Datos',
                    description: 'Elimina permanentemente todos tus gastos y presupuestos.',
                  ),
                  
                  // Zona de Peligro
                  _buildInfoItem(
                    icon: Icons.warning,
                    color: Colors.amber,
                    title: 'Zona de Peligro',
                    description: 'Advertencias claras sobre las consecuencias del reinicio.',
                  ),
                  
                  // Doble Confirmación
                  _buildInfoItem(
                    icon: Icons.security,
                    color: Colors.purple,
                    title: 'Doble Confirmación',
                    description: 'Sistema de seguridad que requiere múltiples confirmaciones.',
                  ),
                  
                  // Información de la App
                  _buildInfoItem(
                    icon: Icons.info_outline,
                    color: Colors.teal,
                    title: 'Información de la App',
                    description: 'Detalles sobre versión, monedas soportadas y características.',
                  ),
                  
                  // Configuración Inteligente
                  _buildInfoItem(
                    icon: Icons.smart_toy,
                    color: Colors.indigo,
                    title: 'Configuración Inteligente',
                    description: 'La app adapta automáticamente límites según tu moneda.',
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Entendido'),
            ),
          ],
        );
      },
    );
  }

  // Widget auxiliar para mostrar información de cada item
  Widget _buildInfoItem({
    required IconData icon,
    required Color color,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade700,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}