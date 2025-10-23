import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../providers/gastos_provider.dart';
import '../providers/presupuesto_provider.dart';
import '../providers/currency_provider.dart';
import '../models/gasto.dart';
import '../utils/currency_input_formatter.dart';

/// Dashboard principal - Completamente rediseñado y funcional
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Observar providers
    final gastos = ref.watch(gastosProvider);
    final presupuestos = ref.watch(presupuestoProvider);

    // Cálculos del mes actual
    final totalGastado = ref.read(gastosProvider.notifier).getTotalGastado();
    final presupuestoTotal = presupuestos['total'] ?? 0.0;
    final dineroRestante = presupuestoTotal - totalGastado;
    final progresoTotal = presupuestoTotal > 0 ? (totalGastado / presupuestoTotal) : 0.0;

    // Gastos recientes del mes
    final ahora = DateTime.now();
    final gastosDelMes = gastos.where((g) => 
      g.fecha.month == ahora.month && g.fecha.year == ahora.year).toList()
      ..sort((a, b) => b.fecha.compareTo(a.fecha));

    // Resumen por categorías con gastos
    final resumenCategorias = ref.read(gastosProvider.notifier).getResumenCategorias();
    final categoriasConGastos = Map<String, double>.from(resumenCategorias)
      ..removeWhere((key, value) => value <= 0);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          // AppBar con gradiente
          SliverAppBar(
            expandedHeight: 120,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text('💰 Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.secondary,
                    ],
                  ),
                ),
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.all(16.0),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Cards de resumen principal
                Row(
                  children: [
                    Expanded(
                      child: _buildCardResumen(
                        'Total Gastado',
                        '\$${totalGastado.toStringAsFixed(0)}',
                        Colors.red,
                        Icons.trending_up,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildCardResumen(
                        'Disponible',
                        dineroRestante >= 0 
                          ? '\$${dineroRestante.toStringAsFixed(0)}'
                          : '-\$${(-dineroRestante).toStringAsFixed(0)}',
                        dineroRestante >= 0 ? Colors.green : Colors.red,
                        Icons.account_balance_wallet,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Barra de progreso del presupuesto
                Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Progreso Mensual', style: TextStyle(fontWeight: FontWeight.bold)),
                            Text('${(progresoTotal * 100).toStringAsFixed(0)}%'),
                          ],
                        ),
                        const SizedBox(height: 12),
                        LinearProgressIndicator(
                          value: progresoTotal.clamp(0.0, 1.0),
                          backgroundColor: Colors.grey[300],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            progresoTotal > 0.8 ? Colors.red :
                            progresoTotal > 0.5 ? Colors.orange : Colors.green,
                          ),
                          minHeight: 8,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          presupuestoTotal > 0 
                            ? 'Presupuesto: \$${presupuestoTotal.toStringAsFixed(0)}'
                            : 'Define tu presupuesto en la tab Presupuesto',
                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Gráfico de gastos por categoría
                if (categoriasConGastos.isNotEmpty) ...[
                  const Text(
                    'Gastos por Categoría',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: SizedBox(
                        height: 200,
                        child: PieChart(
                          PieChartData(
                            sections: _crearSeccionesPie(categoriasConGastos),
                            sectionsSpace: 2,
                            centerSpaceRadius: 50,
                            startDegreeOffset: -90,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Gastos recientes
                const Text(
                  'Gastos Recientes',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),

                if (gastosDelMes.isEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        children: [
                          Icon(Icons.receipt_long, size: 48, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            'No tienes gastos este mes',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: () => _mostrarDialogoGastoRapido(context, ref),
                            child: const Text('Agregar tu primer gasto'),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ...gastosDelMes.take(5).map((gasto) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _getColorCategoria(gasto.categoria),
                        child: Text(
                          gasto.categoria[0],
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                      title: Text(
                        gasto.descripcion,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      subtitle: Text(
                        '${gasto.categoria} • ${DateFormat('dd/MM').format(gasto.fecha)}',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '\$${gasto.monto.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.red,
                            ),
                          ),
                          Text(
                            DateFormat('HH:mm').format(gasto.fecha),
                            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                          ),
                        ],
                      ),
                    ),
                  )),

                const SizedBox(height: 24),

                // Acciones rápidas
                const Text(
                  'Acciones Rápidas',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildBotonAccion(
                        context,
                        'Ver Todos\nlos Gastos',
                        Icons.list_alt,
                        Colors.blue,
                        () {
                          // Cambiar a tab de gastos
                          // Nota: Esto requiere acceso al TabController padre
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildBotonAccion(
                        context,
                        'Configurar\nPresupuesto',
                        Icons.settings,
                        Colors.green,
                        () {
                          // Cambiar a tab de presupuesto
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildBotonAccion(
                        context,
                        'Ver Tips\nde Ahorro',
                        Icons.lightbulb,
                        Colors.orange,
                        () {
                          // Cambiar a tab de tips
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 100), // Espacio para el FAB
              ]),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _mostrarDialogoGastoRapido(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Gasto Rápido'),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  // Widgets helper
  Widget _buildCardResumen(String titulo, String valor, Color color, IconData icono) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icono, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              titulo,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              valor,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBotonAccion(BuildContext context, String texto, IconData icono, Color color, VoidCallback onTap) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Icon(icono, color: color, size: 32),
              const SizedBox(height: 8),
              Text(
                texto,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Diálogo para agregar gasto rápido
  void _mostrarDialogoGastoRapido(BuildContext context, WidgetRef ref) {
    final montoController = TextEditingController();
    final descripcionController = TextEditingController();
    String categoriaSeleccionada = 'Comida';
    
    final categorias = ['Comida', 'Transporte', 'Entretenimiento', 'Vivienda', 'Salud', 'Otros'];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('💸 Gasto Rápido'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Consumer(
              builder: (context, ref, child) {
                final currency = ref.watch(currencyProvider);
                return TextField(
                  controller: montoController,
                  decoration: InputDecoration(
                    labelText: 'Monto',
                    prefixText: '${currency.symbol} ',
                    border: const OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    CurrencyInputFormatterFactory.create(decimalPlaces: currency.decimalPlaces),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descripcionController,
              decoration: const InputDecoration(
                labelText: 'Descripción',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: categoriaSeleccionada,
              decoration: const InputDecoration(
                labelText: 'Categoría',
                border: OutlineInputBorder(),
              ),
              items: categorias.map((cat) => DropdownMenuItem(
                value: cat,
                child: Text(cat),
              )).toList(),
              onChanged: (value) => categoriaSeleccionada = value!,
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
              final monto = CurrencyParser.parseFormattedCurrency(montoController.text);
              if (monto != null && monto > 0 && descripcionController.text.isNotEmpty) {
                
                // Verificar si hay presupuesto general
                final presupuestosDelMes = ref.read(presupuestosMesSeleccionadoProvider);
                final presupuestoTotal = presupuestosDelMes['total'] ?? 0.0;
                
                if (presupuestoTotal <= 0) {
                  Navigator.pop(context);
                  _mostrarDialogoPresupuestoRequerido(context, ref, 'general');
                  return;
                }
                
                // Verificar que el gasto individual no sea mayor al presupuesto general
                if (monto > presupuestoTotal) {
                  Navigator.pop(context);
                  _mostrarDialogoGastoMayorPresupuesto(context, ref, monto, presupuestoTotal);
                  return;
                }
                
                // Verificar si hay presupuesto para la categoría específica
                final presupuestoCategoria = presupuestosDelMes[categoriaSeleccionada] ?? 0.0;
                
                if (presupuestoCategoria <= 0) {
                  Navigator.pop(context);
                  _mostrarDialogoPresupuestoRequerido(context, ref, 'general');
                  return;
                }
                
                // Verificar si el gasto excedería el presupuesto de la categoría
                final resumenGastos = ref.read(resumenCategoriasMesSeleccionadoProvider);
                final gastoActualCategoria = resumenGastos[categoriaSeleccionada] ?? 0.0;
                final nuevoTotalCategoria = gastoActualCategoria + monto;
                
                if (nuevoTotalCategoria > presupuestoCategoria) {
                  Navigator.pop(context);
                  _mostrarDialogoExcesoPresupuesto(context, ref, categoriaSeleccionada, monto, gastoActualCategoria, presupuestoCategoria);
                  return;
                }
                
                final nuevoGasto = Gasto(
                  id: DateTime.now().millisecondsSinceEpoch,
                  descripcion: descripcionController.text,
                  monto: monto,
                  categoria: categoriaSeleccionada,
                  fecha: DateTime.now(),
                );
                
                ref.read(gastosProvider.notifier).addGasto(nuevoGasto);
                Navigator.pop(context);
                
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✅ Gasto agregado correctamente'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: const Text('Agregar'),
          ),
        ],
      ),
    );
  }

  // Crear secciones del gráfico circular
  List<PieChartSectionData> _crearSeccionesPie(Map<String, double> resumen) {
    final colores = [
      Colors.blue[400]!,
      Colors.green[400]!,
      Colors.orange[400]!,
      Colors.red[400]!,
      Colors.purple[400]!,
      Colors.teal[400]!,
      Colors.pink[400]!,
      Colors.indigo[400]!,
    ];

    return resumen.entries.map((entry) {
      final index = resumen.keys.toList().indexOf(entry.key);
      return PieChartSectionData(
        value: entry.value,
        title: '${entry.key}\n\$${entry.value.toStringAsFixed(0)}',
        color: colores[index % colores.length],
        radius: 60,
        titleStyle: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  // Obtener color por categoría
  Color _getColorCategoria(String categoria) {
    switch (categoria) {
      case 'Comida': return Colors.orange[400]!;
      case 'Transporte': return Colors.blue[400]!;
      case 'Entretenimiento': return Colors.purple[400]!;
      case 'Vivienda': return Colors.green[400]!;
      case 'Salud': return Colors.red[400]!;
      case 'Educación': return Colors.teal[400]!;
      case 'Ropa': return Colors.pink[400]!;
      case 'Tecnología': return Colors.indigo[400]!;
      default: return Colors.grey[400]!;
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
            const Text('Gasto Ilógico'),
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
}