import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../providers/gastos_provider.dart';
import '../providers/presupuesto_provider.dart';

/// Dashboard principal - Completamente rediseñado y funcional
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Observar los providers para reactividad
    final gastos = ref.watch(gastosProvider);
    final presupuestos = ref.watch(presupuestoProvider);

    // Calcular totales
    final totalGastado = ref.read(gastosProvider.notifier).getTotalGastado();
    final presupuestoTotal = presupuestos['total'] ?? 0.0;
    final progresoTotal = presupuestoTotal > 0 ? totalGastado / presupuestoTotal : 0.0;

    // Obtener resumen de categorías
    final resumenCategorias = ref.read(gastosProvider.notifier).getResumenCategorias();

    // Top 3 gastos recientes (ordenados por fecha descendente)
    final topGastos = gastos
        .where((gasto) => gasto.fecha.month == DateTime.now().month && gasto.fecha.year == DateTime.now().year)
        .toList()
      ..sort((a, b) => b.fecha.compareTo(a.fecha))
      ..take(3);

    // Mostrar alerta si gastado > 80% del presupuesto
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (progresoTotal > 0.8 && presupuestoTotal > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Alerta! Has gastado más del 80% de tu presupuesto mensual'),
            backgroundColor: Colors.red,
          ),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Finanxper'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card de resumen mensual
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      'Total Gastado Mes: \$${totalGastado.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      softWrap: true,
                    ),
                    const SizedBox(height: 10),
                    LinearProgressIndicator(
                      value: progresoTotal.clamp(0.0, 1.0),
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        progresoTotal > 0.8 ? Colors.red : Colors.green,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Presupuesto: \$${presupuestoTotal.toStringAsFixed(2)}',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Gráfico circular de categorías
            const Text(
              'Gastos por Categoría',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: _crearSeccionesPie(resumenCategorias),
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Top 3 gastos recientes
            const Text(
              'Últimos Gastos',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: topGastos.length,
              itemBuilder: (context, index) {
                final gasto = topGastos[index];
                return ListTile(
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
                  subtitle: Text(DateFormat('dd/MM/yyyy').format(gasto.fecha)),
                  trailing: Text(
                    '\$${gasto.monto.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Simular compartir progreso (por ahora usa print)
          print('=== PROGRESO FINANXPER ===');
          print('Total gastado: \$${totalGastado.toStringAsFixed(2)}');
          print('Presupuesto total: \$${presupuestoTotal.toStringAsFixed(2)}');
          print('Progreso: ${(progresoTotal * 100).toStringAsFixed(1)}%');
          print('Resumen por categorías: $resumenCategorias');
          print('========================');

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Progreso compartido (simulado)')),
          );
        },
        child: const Icon(Icons.share),
        tooltip: 'Compartir Progreso',
      ),
    );
  }

  // Crear secciones para el gráfico circular
  List<PieChartSectionData> _crearSeccionesPie(Map<String, double> resumen) {
    final colores = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.red,
      Colors.purple,
      Colors.teal,
    ];

    return resumen.entries.map((entry) {
      final index = resumen.keys.toList().indexOf(entry.key);
      return PieChartSectionData(
        value: entry.value,
        title: '\$${entry.value.toStringAsFixed(0)}',
        color: colores[index % colores.length],
        radius: 50,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  // Obtener color por categoría
  Color _getColorCategoria(String categoria) {
    switch (categoria) {
      case 'Comida':
        return Colors.orange;
      case 'Transporte':
        return Colors.blue;
      case 'Entretenimiento':
        return Colors.purple;
      case 'Vivienda':
        return Colors.green;
      case 'Salud':
        return Colors.red;
      case 'Educación':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }
}