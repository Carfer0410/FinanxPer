import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/gastos_provider.dart';
import '../providers/presupuesto_provider.dart';
import '../providers/currency_provider.dart';
import '../providers/date_provider.dart';
import '../models/gasto.dart';
import '../widgets/month_year_selector.dart';
import '../utils/currency_input_formatter.dart';

/// Pantalla para gestionar gastos con validación estricta de presupuesto
class GastosScreen extends ConsumerStatefulWidget {
  const GastosScreen({super.key});

  @override
  ConsumerState<GastosScreen> createState() => _GastosScreenState();
}

class _GastosScreenState extends ConsumerState<GastosScreen> {
  final _formKey = GlobalKey<FormState>();
  final _montoController = TextEditingController();
  final _descripcionController = TextEditingController();
  String _categoriaSeleccionada = 'Comida';

  // Lista de categorías disponibles
  final List<String> _categorias = [
    'Comida',
    'Transporte',
    'Entretenimiento',
    'Vivienda',
    'Salud',
    'Educación',
    'Ropa',
    'Tecnología',
    'Otros'
  ];

  @override
  void dispose() {
    _montoController.dispose();
    _descripcionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gastos = ref.watch(gastosDelMesSeleccionadoProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Gastos'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _mostrarAyudaGastos(context),
            tooltip: 'Información de Mis Gastos',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Selector de mes/año
            const MonthYearSelector(
              showCopyButton: false,
            ),
            
            const SizedBox(height: 16),
            
            // Formulario para agregar gastos
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Agregar Nuevo Gasto',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),

                      // Campo de monto
                      Consumer(
                        builder: (context, ref, child) {
                          final currencySymbol = ref.watch(currencySymbolProvider);
                          final currency = ref.watch(currencyProvider);
                          return TextFormField(
                            controller: _montoController,
                            decoration: InputDecoration(
                              labelText: 'Monto',
                              prefixText: '$currencySymbol ',
                              border: const OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              CurrencyInputFormatterFactory.create(decimalPlaces: currency.decimalPlaces),
                            ],
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Por favor ingresa un monto';
                              }
                              final parsed = CurrencyParser.parseFormattedCurrency(value);
                              if (parsed == null) {
                                return 'Por favor ingresa un número válido';
                              }
                              if (parsed <= 0) {
                                return 'El monto debe ser mayor a 0';
                              }
                              return null;
                            },
                          );
                        },
                      ),

                      const SizedBox(height: 16),

                      // Campo de descripción
                      TextFormField(
                        controller: _descripcionController,
                        decoration: const InputDecoration(
                          labelText: 'Descripción',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor ingresa una descripción';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // Selector de categoría
                      DropdownButtonFormField<String>(
                        value: _categoriaSeleccionada,
                        decoration: const InputDecoration(
                          labelText: 'Categoría',
                          border: OutlineInputBorder(),
                        ),
                        items: _categorias.map((categoria) {
                          return DropdownMenuItem<String>(
                            value: categoria,
                            child: Text(categoria),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null && value != _categoriaSeleccionada) {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (mounted) {
                                setState(() {
                                  _categoriaSeleccionada = value;
                                });
                              }
                            });
                          }
                        },
                      ),

                      const SizedBox(height: 16),

                      // Botón de agregar
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _agregarGasto,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text('Agregar Gasto'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Lista de gastos
            if (gastos.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Center(
                    child: Text(
                      'No hay gastos registrados para este mes',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ),
                ),
              )
            else
              Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.6,
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: gastos.length,
                  itemBuilder: (context, index) {
                    final gasto = gastos[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Dismissible(
                        key: Key(gasto.id.toString()),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          color: Colors.red,
                          child: const Icon(
                            Icons.delete,
                            color: Colors.white,
                          ),
                        ),
                        confirmDismiss: (direction) async {
                          // Mostrar diálogo de confirmación
                          final confirmar = await showDialog<bool>(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: const Text('Confirmar eliminación'),
                                content: Text('¿Estás seguro de que quieres eliminar "${gasto.descripcion}"?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(false),
                                    child: const Text('Cancelar'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () => Navigator.of(context).pop(true),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                      foregroundColor: Colors.white,
                                    ),
                                    child: const Text('Eliminar'),
                                  ),
                                ],
                              );
                            },
                          );
                          
                          if (confirmar != true) return false;
                          
                          // Intentar eliminar el gasto
                          try {
                            await ref.read(gastosProvider.notifier).removeGastoById(gasto.id);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Gasto "${gasto.descripcion}" eliminado'),
                                  duration: const Duration(seconds: 1),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                            return true; // Permitir el dismiss
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error al eliminar gasto: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                            return false; // NO permitir el dismiss
                          }
                        },
                        onDismissed: (direction) {
                          // Este método ya no necesita hacer nada porque la eliminación
                          // se maneja en confirmDismiss
                        },
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: _getColorCategoria(gasto.categoria),
                            child: Text(
                              gasto.categoria[0],
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          title: Text(
                            gasto.descripcion,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            DateFormat('dd/MM/yyyy HH:mm').format(gasto.fecha),
                          ),
                          trailing: Consumer(
                            builder: (context, ref, child) {
                              final montoFormateado = ref.watch(gastosFormateadosProvider(gasto));
                              return Text(
                                montoFormateado,
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Método para agregar gasto con validación estricta de presupuesto
  Future<void> _agregarGasto() async {
    if (_formKey.currentState!.validate()) {
      final monto = CurrencyParser.parseFormattedCurrency(_montoController.text) ?? 0.0;
      final descripcion = _descripcionController.text;
      
      // Verificar si hay presupuesto para el mes seleccionado
      final presupuestosDelMes = ref.read(presupuestosMesSeleccionadoProvider);
      final presupuestoTotal = presupuestosDelMes['total'] ?? 0.0;
      
      if (presupuestoTotal <= 0) {
        // No hay presupuesto asignado, mostrar diálogo de advertencia
        _mostrarDialogoSinPresupuesto(monto, descripcion);
        return;
      }
      
      // Verificar que el gasto individual no sea mayor al presupuesto general
      if (monto > presupuestoTotal) {
        _mostrarDialogoGastoMayorPresupuesto(context, ref, monto, presupuestoTotal);
        return;
      }
      
      // Verificar si hay presupuesto para la categoría específica
      final presupuestoCategoria = presupuestosDelMes[_categoriaSeleccionada] ?? 0.0;
      
      if (presupuestoCategoria <= 0) {
        // No hay presupuesto para esta categoría específica
        _mostrarDialogoPresupuestoRequerido(context, ref, 'categoria', _categoriaSeleccionada, presupuestoTotal);
        return;
      }
      
      // Verificar si el gasto excedería el presupuesto de la categoría
      final resumenGastos = ref.read(resumenCategoriasMesSeleccionadoProvider);
      final gastoActualCategoria = resumenGastos[_categoriaSeleccionada] ?? 0.0;
      final nuevoTotalCategoria = gastoActualCategoria + monto;
      
      if (nuevoTotalCategoria > presupuestoCategoria) {
        _mostrarDialogoExcesoPresupuesto(context, ref, _categoriaSeleccionada, monto, gastoActualCategoria, presupuestoCategoria);
        return;
      }
      
      try {
        // Obtener la fecha seleccionada
        final fechaSeleccionada = ref.read(dateSelectionProvider);
        final fechaGasto = DateTime(fechaSeleccionada.year, fechaSeleccionada.month, DateTime.now().day);

        final nuevoGasto = Gasto(
          id: 0, // El provider generará un ID válido automáticamente
          descripcion: descripcion,
          monto: monto,
          categoria: _categoriaSeleccionada,
          fecha: fechaGasto,
        );

        await ref.read(gastosProvider.notifier).addGasto(nuevoGasto);

        // Limpiar formulario
        _montoController.clear();
        _descripcionController.clear();
        setState(() {
          _categoriaSeleccionada = 'Comida';
        });

        // Mostrar mensaje de éxito (opcional ya que el GlobalNotificationListener lo manejará)
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Gasto agregado correctamente'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 1),
            ),
          );
        }
      } catch (e) {
        // El error será manejado por el GlobalNotificationListener
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al agregar gasto: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  /// Muestra diálogo cuando no hay presupuesto asignado - Validación estricta
  void _mostrarDialogoSinPresupuesto(double monto, String descripcion) {
    final currentCurrency = ref.read(currencyProvider);
    final fechaSeleccionada = ref.read(dateSelectionProvider);
    final months = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];
    final mesNombre = months[fechaSeleccionada.month - 1];

    showDialog(
      context: context,
      barrierDismissible: false, // No se puede cerrar tocando fuera
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning, color: Colors.orange),
              SizedBox(width: 8),
              Expanded(child: Text('Sin Presupuesto')),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'No tienes un presupuesto asignado para $mesNombre ${fechaSeleccionada.year}.',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Gasto que intentas registrar:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text('• $descripcion'),
                      Text('• ${currentCurrency.formatAmount(monto)}'),
                      Text('• Categoría: $_categoriaSeleccionada'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.lightbulb, color: Colors.blue.shade600, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Para un mejor control financiero, primero configura tu presupuesto mensual.',
                          style: TextStyle(
                            color: Colors.blue.shade700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Mostrar mensaje guiando al usuario
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Row(
                      children: [
                        Icon(Icons.arrow_forward, color: Colors.white),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text('Ve a la pestaña "Presupuesto" para configurar tu presupuesto mensual'),
                        ),
                      ],
                    ),
                    backgroundColor: Colors.blue.shade600,
                    duration: const Duration(seconds: 5),
                    action: SnackBarAction(
                      label: 'Entendido',
                      textColor: Colors.white,
                      onPressed: () {},
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
                foregroundColor: Colors.white,
              ),
              child: const Text('Configurar Presupuesto'),
            ),
          ],
        );
      },
    );
  }

  /// Función para obtener color por categoría
  Color _getColorCategoria(String categoria) {
    switch (categoria) {
      case 'Comida':
        return Colors.green;
      case 'Transporte':
        return Colors.blue;
      case 'Entretenimiento':
        return Colors.purple;
      case 'Vivienda':
        return Colors.brown;
      case 'Salud':
        return Colors.red;
      case 'Educación':
        return Colors.indigo;
      case 'Ropa':
        return Colors.pink;
      case 'Tecnología':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  /// Diálogo para requerir configuración de presupuesto
  void _mostrarDialogoPresupuestoRequerido(
    BuildContext context, 
    WidgetRef ref, 
    String tipo, 
    [String? categoria, double? presupuestoTotal]
  ) {
    final esCategoria = tipo == 'categoria';
    final titulo = esCategoria 
        ? 'Sin Presupuesto en "$categoria"' 
        : 'Presupuesto General Requerido';
    final currency = ref.watch(currencyProvider);
    
    String mensaje;
    if (esCategoria) {
      // Obtener información de otras categorías con presupuesto
      final presupuestosDelMes = ref.read(presupuestosMesSeleccionadoProvider);
      final categoriasConPresupuesto = <String>[];
      
      for (final entry in presupuestosDelMes.entries) {
        if (entry.key != 'total' && entry.value > 0) {
          categoriasConPresupuesto.add('${entry.key}: ${currency.formatAmount(entry.value)}');
        }
      }
      
      final ejemplosCategorias = categoriasConPresupuesto.isNotEmpty 
          ? '\n\n📈 Categorías con presupuesto:\n• ${categoriasConPresupuesto.take(3).join('\n• ')}'
          : '\n\n⚠️ Ninguna categoría tiene presupuesto asignado aún.';
      
      mensaje = 'No puedes agregar gastos a "$categoria" porque esta categoría no tiene presupuesto asignado.'
          '\n\n💰 Presupuesto general disponible: ${currency.formatAmount(presupuestoTotal ?? 0.0)}'
          '\n📊 Presupuesto en "$categoria": ${currency.formatAmount(0.0)}'
          '$ejemplosCategorias'
          '\n\n✅ Para continuar:'
          '\n1. Ve a la pantalla de Presupuesto'
          '\n2. Distribuye tu presupuesto general'
          '\n3. Asigna una cantidad a "$categoria"'
          '\n4. ¡Listo para registrar gastos!';
    } else {
      mensaje = 'No has configurado un presupuesto general para este mes.\n\nPara agregar gastos, primero debes establecer tu presupuesto total mensual.';
    }
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.orange[600]),
            const SizedBox(width: 8),
            Expanded(child: Text(titulo)),
          ],
        ),
        content: Text(mensaje),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/presupuesto');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange[600],
              foregroundColor: Colors.white,
            ),
            child: const Text('Configurar Presupuesto'),
          ),
        ],
      ),
    );
  }

  /// Diálogo cuando el gasto excede el presupuesto de la categoría
  void _mostrarDialogoExcesoPresupuesto(
    BuildContext context,
    WidgetRef ref,
    String categoria,
    double montoNuevo,
    double gastoActual,
    double presupuestoCategoria,
  ) {
    final currency = ref.watch(currencyProvider);
    final nuevoTotal = gastoActual + montoNuevo;
    final exceso = nuevoTotal - presupuestoCategoria;
    final disponible = presupuestoCategoria - gastoActual;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.error, color: Colors.red[600]),
            const SizedBox(width: 8),
            const Text('Presupuesto Excedido'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('El gasto de ${currency.formatAmount(montoNuevo)} excede el presupuesto disponible para "$categoria".'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Column(
                children: [
                  _buildInfoRow('Presupuesto categoría:', currency.formatAmount(presupuestoCategoria)),
                  _buildInfoRow('Ya gastado:', currency.formatAmount(gastoActual)),
                  _buildInfoRow('Disponible:', currency.formatAmount(disponible), disponible > 0 ? Colors.green : Colors.red),
                  const Divider(),
                  _buildInfoRow('Nuevo gasto:', currency.formatAmount(montoNuevo)),
                  _buildInfoRow('Exceso:', currency.formatAmount(exceso), Colors.red),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/presupuesto');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange[600],
              foregroundColor: Colors.white,
            ),
            child: const Text('Ajustar Presupuesto'),
          ),
        ],
      ),
    );
  }

  /// Diálogo cuando el gasto individual es mayor al presupuesto general
  void _mostrarDialogoGastoMayorPresupuesto(
    BuildContext context,
    WidgetRef ref,
    double montoGasto,
    double presupuestoTotal,
  ) {
    final currency = ref.watch(currencyProvider);
    final exceso = montoGasto - presupuestoTotal;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red[600]),
            const SizedBox(width: 8),
            const Text('Gasto ilógico'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'No puedes registrar un gasto de ${currency.formatAmount(montoGasto)} cuando tu presupuesto general es de ${currency.formatAmount(presupuestoTotal)}.',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Column(
                children: [
                  _buildInfoRow('Presupuesto general:', currency.formatAmount(presupuestoTotal)),
                  _buildInfoRow('Gasto que intentas registrar:', currency.formatAmount(montoGasto)),
                  _buildInfoRow('Exceso:', currency.formatAmount(exceso), Colors.red),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '💡 Sugerencias:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              '• Aumenta tu presupuesto general\n'
              '• Reduce el monto del gasto\n'
              '• Divide el gasto en varios registros más pequeños',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendido'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/presupuesto');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange[600],
              foregroundColor: Colors.white,
            ),
            child: const Text('Aumentar Presupuesto'),
          ),
        ],
      ),
    );
  }

  /// Widget auxiliar para mostrar información en el diálogo de exceso
  Widget _buildInfoRow(String label, String value, [Color? valueColor]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12)),
          Text(
            value, 
            style: TextStyle(
              fontSize: 12, 
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  /// Función para mostrar ayuda
  void _mostrarAyudaGastos(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Ayuda - Mis Gastos'),
          content: const SingleChildScrollView(
            child: Text(
              'Funcionalidades disponibles:\n\n'
              '• Agregar nuevos gastos con descripción y categoría\n'
              '• Ver todos tus gastos organizados por mes\n'
              '• Eliminar gastos deslizando hacia la izquierda\n'
              '• Cambiar de mes con el selector superior\n'
              '• Solo puedes agregar gastos si tienes presupuesto configurado\n\n'
              'Validación estricta:\n'
              '• Debes configurar un presupuesto antes de registrar gastos\n'
              '• Los gastos no pueden exceder el presupuesto de cada categoría\n'
              '• Esto te ayuda a mantener un mejor control financiero',
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
}