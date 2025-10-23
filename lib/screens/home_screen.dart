import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../providers/gastos_provider.dart';
import '../providers/presupuesto_provider.dart';
import '../providers/currency_provider.dart';
import '../models/gasto.dart';
import '../widgets/month_year_selector.dart';
import '../widgets/auto_save_indicator.dart';
import '../utils/currency_input_formatter.dart';

class HomeScreen extends ConsumerWidget {
  final Function(int)? onNavigateToTab;
  
  const HomeScreen({super.key, this.onNavigateToTab});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Observar providers del mes seleccionado
    final gastosDelMes = ref.watch(gastosDelMesSeleccionadoProvider);
    final presupuestosDelMes = ref.watch(presupuestosMesSeleccionadoProvider);
    final totalGastadoFormateado = ref.watch(totalGastadoMesSeleccionadoFormateadoProvider);
    final presupuestoTotalFormateado = ref.watch(presupuestoTotalMesSeleccionadoFormateadoProvider);
    final currentCurrency = ref.watch(currencyProvider);

    // Cálculos del mes seleccionado
    final totalGastado = ref.watch(totalGastadoMesSeleccionadoProvider);
    final presupuestoTotal = presupuestosDelMes['total'] ?? 0.0;
    final dineroRestante = presupuestoTotal - totalGastado;
    final dineroRestanteFormateado = currentCurrency.formatAmount(dineroRestante > 0 ? dineroRestante : 0.0);
    
    // Cálculo mejorado del progreso
    final progresoTotal = presupuestoTotal > 0 ? (totalGastado / presupuestoTotal) : 0.0;
    final tienePresupuesto = presupuestoTotal > 0;
    final tieneGastos = totalGastado > 0;

    // Gastos recientes del mes seleccionado ordenados por fecha
    final gastosRecientes = List<Gasto>.from(gastosDelMes)
      ..sort((a, b) => b.fecha.compareTo(a.fecha));

    // Resumen por categorías con gastos del mes seleccionado
    final resumenCategorias = ref.watch(resumenCategoriasMesSeleccionadoProvider);
    final categoriasConGastos = Map<String, double>.from(resumenCategorias)
      ..removeWhere((key, value) => value <= 0);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          // AppBar con gradiente
          SliverAppBar(
            expandedHeight: 150,
            pinned: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.info_outline),
                onPressed: () => _mostrarAyudaDashboard(context),
                tooltip: 'Información del Dashboard',
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.blue[600]!,
                      Colors.blue[400]!,
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 5),
                      Text(
                        '💰 Panel Financiero',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const MonthYearSelector(),
                      const SizedBox(height: 5),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Contenido principal
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Indicador de auto-guardado
                  const AutoSaveIndicator(),
                  const SizedBox(height: 16),

                  // Cards de resumen
                  Row(
                    children: [
                      Expanded(
                        child: _buildCardResumen(
                          'Total Gastado',
                          totalGastadoFormateado,
                          Colors.red,
                          Icons.money_off,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildCardResumen(
                          'Presupuesto',
                          presupuestoTotalFormateado,
                          Colors.blue,
                          Icons.account_balance_wallet,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildCardResumen(
                          'Disponible',
                          dineroRestanteFormateado,
                          dineroRestante > 0 ? Colors.green : Colors.red,
                          Icons.savings,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildCardProgreso(
                          context,
                          totalGastado,
                          presupuestoTotal,
                          progresoTotal,
                          tienePresupuesto,
                          tieneGastos,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Gráfico circular de gastos por categoría
                  if (categoriasConGastos.isNotEmpty) ...[
                    Card(
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '📊 Gastos por Categoría',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              height: 200,
                              child: PieChart(
                                PieChartData(
                                  sectionsSpace: 2,
                                  centerSpaceRadius: 40,
                                  sections: _buildPieChartSections(categoriasConGastos),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Leyenda
                            Wrap(
                              spacing: 16,
                              runSpacing: 8,
                              children: categoriasConGastos.entries.map((entry) {
                                final color = _getCategoriaColor(entry.key);
                                return Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 12,
                                      height: 12,
                                      decoration: BoxDecoration(
                                        color: color,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      entry.key,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    // Análisis de gastos vs presupuesto
                    _buildAnalisisPresupuesto(context, ref, categoriasConGastos, presupuestosDelMes),
                    
                    const SizedBox(height: 24),
                  ] else ...[
                    // Mensaje cuando no hay datos del gráfico
                    Card(
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Icon(Icons.pie_chart_outline, size: 48, color: Colors.grey[400]),
                            const SizedBox(height: 8),
                            Text(
                              'Sin datos para el gráfico',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Añade gastos para ver el gráfico por categorías',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Gastos recientes
                  Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '📝 Gastos Recientes',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),
                          if (gastosRecientes.isEmpty)
                            Center(
                              child: Column(
                                children: [
                                  Icon(Icons.receipt_long, size: 48, color: Colors.grey[400]),
                                  const SizedBox(height: 8),
                                  Text(
                                    'No hay gastos registrados',
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                            )
                          else
                            ...gastosRecientes.take(5).map((gasto) => Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 20,
                                    backgroundColor: _getCategoriaColor(gasto.categoria),
                                    child: Icon(
                                      Icons.shopping_cart,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          gasto.descripcion,
                                          style: const TextStyle(fontWeight: FontWeight.w500),
                                        ),
                                        Text(
                                          '${gasto.categoria} • ${DateFormat('dd/MM/yyyy').format(gasto.fecha)}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    currentCurrency.formatAmount(gasto.monto),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                            )).toList(),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Botones de acción rápida
                  Row(
                    children: [
                      Expanded(
                        child: _buildBotonAccion(
                          context,
                          'Nuevo Gasto',
                          Icons.add,
                          Colors.red,
                          () => _mostrarDialogoGastoRapido(context, ref),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildBotonAccion(
                          context,
                          'Ver Gastos',
                          Icons.list,
                          Colors.blue,
                          () => onNavigateToTab?.call(1) ?? Navigator.pushNamed(context, '/gastos'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildBotonAccion(
                          context,
                          'Presupuesto',
                          Icons.account_balance,
                          Colors.green,
                          () => onNavigateToTab?.call(2) ?? Navigator.pushNamed(context, '/presupuesto'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildBotonAccion(
                          context,
                          'Reportes',
                          Icons.bar_chart,
                          Colors.purple,
                          () => Navigator.pushNamed(context, '/reportes'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardResumen(String titulo, String valor, Color color, IconData icono) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icono, color: color, size: 24),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    titulo,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              valor,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardProgreso(
    BuildContext context,
    double totalGastado,
    double presupuestoTotal,
    double progresoTotal,
    bool tienePresupuesto,
    bool tieneGastos,
  ) {
    String titulo;
    String valor;
    Color color;
    IconData icono;

    if (tienePresupuesto) {
      // Caso normal: tiene presupuesto configurado
      titulo = 'Progreso';
      valor = '${(progresoTotal * 100).toStringAsFixed(0)}%';
      color = progresoTotal <= 0.8 ? Colors.green : Colors.orange;
      icono = Icons.donut_large;
    } else if (tieneGastos) {
      // Sin presupuesto pero tiene gastos: mostrar total gastado
      titulo = 'Total Gastado';
      valor = NumberFormat.currency(
        locale: 'es_CO',
        symbol: '\$',
        decimalDigits: 0,
      ).format(totalGastado);
      color = Colors.blue;
      icono = Icons.account_balance_wallet;
    } else {
      // Sin presupuesto ni gastos
      titulo = 'Sin Actividad';
      valor = 'Añade un gasto';
      color = Colors.grey;
      icono = Icons.add_circle_outline;
    }

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icono, color: color, size: 24),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    titulo,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              valor,
              style: TextStyle(
                fontSize: 20,
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
              Icon(icono, color: color, size: 28),
              const SizedBox(height: 8),
              Text(
                texto,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<PieChartSectionData> _buildPieChartSections(Map<String, double> categorias) {
    final total = categorias.values.fold(0.0, (sum, amount) => sum + amount);
    
    return categorias.entries.map((entry) {
      final percentage = (entry.value / total) * 100;
      final color = _getCategoriaColor(entry.key);
      
      return PieChartSectionData(
        color: color,
        value: entry.value,
        title: '${percentage.toStringAsFixed(1)}%',
        radius: 60,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  Color _getCategoriaColor(String categoria) {
    // Normalizar la categoría (quitar espacios y convertir a lowercase para comparación)
    final categoriaNormalizada = categoria.trim().toLowerCase();
    
    final colors = {
      'comida': Colors.orange,
      'transporte': Colors.blue,
      'entretenimiento': Colors.purple,
      'vivienda': Colors.green,
      'salud': Colors.red,
      'educación': Colors.indigo,
      'educacion': Colors.indigo, // Sin acento también
      'ropa': Colors.pink,
      'tecnología': Colors.cyan,
      'tecnologia': Colors.cyan, // Sin acento también
      'otros': Colors.grey,
    };
    
    // Primero intentar con el nombre original
    Color? color = colors[categoria];
    if (color != null) return color;
    
    // Luego intentar con el nombre normalizado
    color = colors[categoriaNormalizada];
    if (color != null) return color;
    
    // Si no encuentra la categoría, usar colores predefinidos basados en hash
    final coloresAlternativos = [
      Colors.deepOrange,
      Colors.teal,
      Colors.amber,
      Colors.deepPurple,
      Colors.lime,
      Colors.redAccent,
      Colors.blueGrey,
      Colors.brown,
    ];
    
    final index = categoria.hashCode.abs() % coloresAlternativos.length;
    return coloresAlternativos[index];
  }

  // Diálogo para gasto rápido
  void _mostrarDialogoGastoRapido(BuildContext context, WidgetRef ref) {
    final montoController = TextEditingController();
    final descripcionController = TextEditingController();
    String categoriaSeleccionada = 'Comida';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Gasto Rápido'),
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
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: categoriaSeleccionada,
              decoration: const InputDecoration(
                labelText: 'Categoría',
              ),
              items: const [
                'Comida',
                'Transporte',
                'Entretenimiento',
                'Vivienda',
                'Salud',
                'Educación',
                'Ropa',
                'Tecnología',
                'Otros'
              ].map((categoria) => DropdownMenuItem(
                value: categoria,
                child: Text(categoria),
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
            onPressed: () async {
              if (montoController.text.isNotEmpty && descripcionController.text.isNotEmpty) {
                final monto = CurrencyParser.parseFormattedCurrency(montoController.text);
                if (monto != null && monto > 0) {
                  
                  // VALIDACIÓN DE PRESUPUESTO
                  final presupuestosDelMes = ref.read(presupuestosMesSeleccionadoProvider);
                  final presupuestoTotal = presupuestosDelMes['total'] ?? 0.0;
                  final presupuestoCategoria = presupuestosDelMes[categoriaSeleccionada] ?? 0.0;
                  
                  // Verificar si hay presupuesto general
                  if (presupuestoTotal <= 0) {
                    Navigator.pop(context);
                    _mostrarDialogoPresupuestoRequerido(context, ref, 'general');
                    return;
                  }
                  
                  // Verificar si hay presupuesto para la categoría específica
                  if (presupuestoCategoria <= 0) {
                    Navigator.pop(context);
                    _mostrarDialogoPresupuestoRequerido(context, ref, 'categoria', categoriaSeleccionada, presupuestoTotal);
                    return;
                  }
                  
                  // Verificar si el gasto excedería el presupuesto de la categoría
                  final resumenGastos = ref.read(resumenCategoriasMesSeleccionadoProvider);
                  final gastoActualCategoria = resumenGastos[categoriaSeleccionada] ?? 0.0;
                  final nuevoTotalCategoria = gastoActualCategoria + monto;
                  
                  if (nuevoTotalCategoria > presupuestoCategoria) {
                    Navigator.pop(context);
                    _mostrarDialogoExcesoPresupuesto(context, ref, categoriaSeleccionada, 
                      monto, gastoActualCategoria, presupuestoCategoria);
                    return;
                  }
                  
                  // Si todas las validaciones pasan, agregar el gasto
                  final gasto = Gasto(
                    id: DateTime.now().millisecondsSinceEpoch,
                    descripcion: descripcionController.text,
                    monto: monto,
                    categoria: categoriaSeleccionada,
                    fecha: DateTime.now(),
                  );
                  
                  await ref.read(gastosProvider.notifier).addGasto(gasto);
                  Navigator.pop(context);
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Gasto agregado exitosamente')),
                  );
                }
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _mostrarAyudaDashboard(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.help_outline, color: Colors.blue),
              SizedBox(width: 8),
              Text('Ayuda del Dashboard'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildInfoItem(
                  icon: Icons.dashboard,
                  color: Colors.blue,
                  title: 'Resumen Financiero',
                  description: 'Visualiza tu situación financiera actual del mes seleccionado.',
                ),
                
                _buildInfoItem(
                  icon: Icons.pie_chart,
                  color: Colors.orange,
                  title: 'Gráfico de Categorías',
                  description: 'Distribución visual de gastos por categoría.',
                ),
                
                _buildInfoItem(
                  icon: Icons.receipt_long,
                  color: Colors.green,
                  title: 'Gastos Recientes',
                  description: 'Lista de los últimos 5 gastos registrados.',
                ),
                
                _buildInfoItem(
                  icon: Icons.flash_on,
                  color: Colors.amber,
                  title: 'Acciones Rápidas',
                  description: 'Botones para tareas comunes rápidamente.',
                ),
              ],
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
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  // Widget para analizar gastos vs presupuesto
  Widget _buildAnalisisPresupuesto(
    BuildContext context, 
    WidgetRef ref, 
    Map<String, double> categoriasConGastos,
    Map<String, double> presupuestosDelMes,
  ) {
    // Identificar categorías con gastos pero sin presupuesto
    final categoriasSinPresupuesto = <String>[];
    final categoriasConPresupuesto = <String>[];
    
    for (final categoria in categoriasConGastos.keys) {
      if (!presupuestosDelMes.containsKey(categoria) || (presupuestosDelMes[categoria] ?? 0.0) <= 0) {
        categoriasSinPresupuesto.add(categoria);
      } else {
        categoriasConPresupuesto.add(categoria);
      }
    }
    
    // Si no hay categorías sin presupuesto, no mostrar nada
    if (categoriasSinPresupuesto.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Card(
      elevation: 4,
      color: Colors.amber[50],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning_amber, color: Colors.amber[700], size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '💡 Sugerencia de Presupuesto',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.amber[800],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            Text(
              'Tienes gastos en ${categoriasSinPresupuesto.length} ${categoriasSinPresupuesto.length == 1 ? 'categoría' : 'categorías'} sin presupuesto asignado:',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            
            // Lista de categorías sin presupuesto
            ...categoriasSinPresupuesto.map((categoria) {
              final gasto = categoriasConGastos[categoria] ?? 0.0;
              final currency = ref.watch(currencyProvider);
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 4.0),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _getCategoriaColor(categoria),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        categoria,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                    Text(
                      currency.formatAmount(gasto),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange[700],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            
            const SizedBox(height: 12),
            
            // Botones de acción
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => onNavigateToTab?.call(2) ?? Navigator.pushNamed(context, '/presupuesto'),
                    icon: const Icon(Icons.add_chart, size: 18),
                    label: const Text('Crear Presupuesto'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber[600],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _mostrarSugerenciasPresupuesto(context, ref, categoriasSinPresupuesto, categoriasConGastos),
                    icon: const Icon(Icons.lightbulb_outline, size: 18),
                    label: const Text('Ver Sugerencias'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.amber[700],
                      side: BorderSide(color: Colors.amber[600]!),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  // Método para mostrar sugerencias de presupuesto
  void _mostrarSugerenciasPresupuesto(
    BuildContext context,
    WidgetRef ref,
    List<String> categoriasSinPresupuesto,
    Map<String, double> categoriasConGastos,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.lightbulb, color: Colors.amber[600]),
            const SizedBox(width: 8),
            const Text('Sugerencias de Presupuesto'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Basado en tus gastos actuales, te sugerimos estos presupuestos:',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              
              ...categoriasSinPresupuesto.map((categoria) {
                final gastoActual = categoriasConGastos[categoria] ?? 0.0;
                final sugerencia1 = gastoActual * 1.2; // 20% más
                final sugerencia2 = gastoActual * 1.5; // 50% más
                final currency = ref.watch(currencyProvider);
                
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: _getCategoriaColor(categoria),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              categoria,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text('Gasto actual: ${currency.formatAmount(gastoActual)}'),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.recommend, size: 16, color: Colors.green[600]),
                            const SizedBox(width: 4),
                            Text('Sugerido: ${currency.formatAmount(sugerencia1)} - ${currency.formatAmount(sugerencia2)}'),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onNavigateToTab?.call(2) ?? Navigator.pushNamed(context, '/presupuesto');
            },
            child: const Text('Ir a Presupuesto'),
          ),
        ],
      ),
    );
  }
  
  // Diálogo cuando no hay presupuesto configurado
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
              onNavigateToTab?.call(2) ?? Navigator.pushNamed(context, '/presupuesto');
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
  
  // Diálogo cuando el gasto excede el presupuesto de la categoría
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
          if (disponible > 0) ...[
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _mostrarDialogoAjustarGasto(context, ref, categoria, disponible);
              },
              child: Text('Ajustar a ${currency.formatAmount(disponible)}'),
            ),
          ],
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onNavigateToTab?.call(2) ?? Navigator.pushNamed(context, '/presupuesto');
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
  
  // Widget auxiliar para mostrar información en el diálogo de exceso
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
  
  // Diálogo para ajustar el gasto al monto disponible
  void _mostrarDialogoAjustarGasto(
    BuildContext context,
    WidgetRef ref,
    String categoria,
    double montoDisponible,
  ) {
    final montoController = TextEditingController(text: montoDisponible.toStringAsFixed(0));
    final descripcionController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ajustar Gasto'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Gasto ajustado para categoría "$categoria"'),
            const SizedBox(height: 16),
            Consumer(
              builder: (context, ref, child) {
                final currency = ref.watch(currencyProvider);
                return TextField(
                  controller: montoController,
                  decoration: InputDecoration(
                    labelText: 'Monto',
                    prefixText: '${currency.symbol} ',
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
            onPressed: () async {
              if (montoController.text.isNotEmpty && descripcionController.text.isNotEmpty) {
                final monto = CurrencyParser.parseFormattedCurrency(montoController.text);
                if (monto != null && monto > 0 && monto <= montoDisponible) {
                  final gasto = Gasto(
                    id: DateTime.now().millisecondsSinceEpoch,
                    descripcion: descripcionController.text,
                    monto: monto,
                    categoria: categoria,
                    fecha: DateTime.now(),
                  );
                  
                  await ref.read(gastosProvider.notifier).addGasto(gasto);
                  Navigator.pop(context);
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Gasto agregado exitosamente')),
                  );
                }
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }
}