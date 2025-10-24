import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/gastos_provider.dart';
import '../providers/presupuesto_provider.dart';
import '../providers/currency_provider.dart';
import '../providers/date_provider.dart';
import '../widgets/month_year_selector.dart';
import '../utils/currency_input_formatter.dart';
import '../theme/app_theme.dart';

/// Pantalla para gestionar presupuestos con sliders funcionales
class PresupuestoScreen extends ConsumerWidget {
  const PresupuestoScreen({super.key});

  // Lista de categorías disponibles
  static const List<String> _categorias = [
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
  Widget build(BuildContext context, WidgetRef ref) {
    final presupuestos = ref.watch(presupuestosMesSeleccionadoProvider);
    final presupuestosFormateados = ref.watch(presupuestosFormateadosMesSeleccionadoProvider);
    final presupuestoTotalFormateado = ref.watch(presupuestoTotalMesSeleccionadoFormateadoProvider);
    final resumenGastos = ref.watch(resumenCategoriasMesSeleccionadoProvider);
    final totalGastado = ref.watch(totalGastadoMesSeleccionadoProvider);
    final totalGastadoFormateado = ref.watch(totalGastadoMesSeleccionadoFormateadoProvider);
    final presupuestoTotal = presupuestos['total'] ?? 0.0;
    final currentCurrency = ref.watch(currencyProvider);

    // Calcular suma total de presupuestos por categoría
    final sumaCategorias = _categorias.fold<double>(0.0, (sum, categoria) {
      return sum + (presupuestos[categoria] ?? 0.0);
    });
    
    // Verificar si hay inconsistencia presupuestaria
    final hayInconsistencia = sumaCategorias > presupuestoTotal && presupuestoTotal > 0;

    // Calcular progreso total
    final progresoTotal = presupuestoTotal > 0 ? (totalGastado / presupuestoTotal) : 0.0;

    return Scaffold(
      backgroundColor: FinanxperColors.background,
      appBar: AppBar(
        title: const Text('💰 Mi Presupuesto'),
        backgroundColor: FinanxperColors.success,
        foregroundColor: FinanxperColors.textOnPrimary,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [FinanxperColors.success, FinanxperColors.primary],
            ),
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.info_outline, color: Colors.white),
              onPressed: () => _mostrarAyudaPresupuesto(context),
              tooltip: 'Información de Presupuesto',
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Selector de mes/año con funcionalidad de copia
            MonthYearSelector(
              showCopyButton: true,
              isOnGradientBackground: false,
              onCopyFromPrevious: () {
                final presupuestoNotifier = ref.read(presupuestoProvider.notifier);
                final currentMonthKey = ref.read(currentMonthKeyProvider);
                
                // Calcular el mes anterior
                final current = ref.read(dateSelectionProvider);
                final previousMonth = DateTime(current.year, current.month - 1);
                final previousMonthKey = "${previousMonth.year}-${previousMonth.month.toString().padLeft(2, '0')}";
                
                presupuestoNotifier.copiarPresupuestosDeMes(previousMonthKey, currentMonthKey);
                
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Presupuestos copiados del mes anterior'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            
            // Presupuesto total mensual
            const Text(
              'Presupuesto Total Mensual',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Monto:'),
                        Row(
                          children: [
                            Text(
                              presupuestoTotalFormateado,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.edit, size: 20),
                              onPressed: () => _mostrarDialogoEdicion(context, ref, 'total', presupuestoTotal),
                              tooltip: 'Editar monto manualmente',
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Slider(
                      value: presupuestoTotal.clamp(0.0, currentCurrency.maxBudgetTotal),
                      min: 0,
                      max: currentCurrency.maxBudgetTotal,
                      divisions: currentCurrency.budgetDivisions,
                      label: presupuestoTotalFormateado,
                      onChanged: (value) async {
                        final monthKey = ref.read(currentMonthKeyProvider);
                        await ref.read(presupuestoProvider.notifier).setPresupuestoMesSeleccionado(monthKey, 'total', value);
                      },
                    ),
                    Text(
                      'Usa el botón de editar para montos mayores a ${currentCurrency.formatAmount(currentCurrency.maxBudgetTotal)}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Advertencia de inconsistencia presupuestaria
            if (hayInconsistencia)
              Card(
                elevation: 4,
                color: Colors.red[50],
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(Icons.warning, color: Colors.red[700]),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '¡Inconsistencia Presupuestaria!',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.red[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'La suma de presupuestos por categoría (${currentCurrency.formatAmount(sumaCategorias)}) '
                        'es mayor al presupuesto total (${currentCurrency.formatAmount(presupuestoTotal)}).',
                        style: TextStyle(color: Colors.red[600]),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Ajusta los presupuestos para que sean coherentes.',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 20),

            // Presupuestos por categoría
            const Text(
              'Presupuestos por Categoría',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _categorias.length,
              itemBuilder: (context, index) {
                final categoria = _categorias[index];
                final presupuestoCategoria = presupuestos[categoria] ?? 0.0;
                final gastadoCategoria = resumenGastos[categoria] ?? 0.0;
                final progresoCategoria = presupuestoCategoria > 0 ? gastadoCategoria / presupuestoCategoria : 0.0;
                
                // Calcular máximo asignable a esta categoría
                final sumaOtrasCategorias = _categorias
                    .where((cat) => cat != categoria)
                    .fold<double>(0.0, (sum, cat) => sum + (presupuestos[cat] ?? 0.0));
                final maximoAsignable = presupuestoTotal - sumaOtrasCategorias;

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              categoria,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              '${(progresoCategoria * 100).toStringAsFixed(0)}%',
                              style: TextStyle(
                                color: _getColorProgreso(progresoCategoria),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Presupuesto: ${presupuestosFormateados[categoria] ?? currentCurrency.formatAmount(0.0)}',
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                            ElevatedButton(
                              onPressed: () => _mostrarDialogoEdicion(context, ref, categoria, presupuestoCategoria),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                minimumSize: const Size(0, 32),
                              ),
                              child: const Text(
                                'Editar presupuesto',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: progresoCategoria.clamp(0.0, 1.0),
                          backgroundColor: Colors.grey[300],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _getColorProgreso(progresoCategoria),
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Gastado: ${currentCurrency.formatAmount(gastadoCategoria)}'),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Flexible(
                                  child: Text(
                                    'Máximo asignable: ${currentCurrency.formatAmount(maximoAsignable)}',
                                    style: const TextStyle(fontWeight: FontWeight.w500),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => _mostrarInfoPresupuesto(context, ref, categoria, maximoAsignable, presupuestoCategoria, gastadoCategoria),
                                  child: Icon(
                                    Icons.info_outline,
                                    size: 16,
                                    color: Colors.blue[600],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 20),

            // Resumen de progreso total
            Card(
              elevation: 4,
              color: progresoTotal > 0.8 ? Colors.red[50] : Colors.green[50],
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      'Progreso Total: ${(progresoTotal * 100).toStringAsFixed(0)}%',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
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
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text('Total gastado: $totalGastadoFormateado'),
                        ),
                        Flexible(
                          child: Text('Presupuesto: $presupuestoTotalFormateado'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Mostrar diálogo para edición manual del presupuesto
  void _mostrarDialogoEdicion(BuildContext context, WidgetRef ref, String categoria, double valorActual) {
    final TextEditingController controller = TextEditingController(
      text: valorActual.toStringAsFixed(0),
    );

    // Obtener información del presupuesto actual
    final currentCurrency = ref.watch(currencyProvider);

    // Definir ícono y color según la categoría
    IconData categoryIcon;
    Color categoryColor;
    if (categoria == 'total') {
      categoryIcon = Icons.account_balance_wallet;
      categoryColor = Colors.blue[600]!;
    } else {
      switch (categoria) {
        case 'Comida':
          categoryIcon = Icons.restaurant;
          categoryColor = Colors.orange[600]!;
          break;
        case 'Transporte':
          categoryIcon = Icons.directions_car;
          categoryColor = Colors.green[600]!;
          break;
        case 'Entretenimiento':
          categoryIcon = Icons.movie;
          categoryColor = Colors.purple[600]!;
          break;
        case 'Vivienda':
          categoryIcon = Icons.home;
          categoryColor = Colors.brown[600]!;
          break;
        case 'Salud':
          categoryIcon = Icons.local_hospital;
          categoryColor = Colors.red[600]!;
          break;
        case 'Educación':
          categoryIcon = Icons.school;
          categoryColor = Colors.indigo[600]!;
          break;
        case 'Ropa':
          categoryIcon = Icons.checkroom;
          categoryColor = Colors.pink[600]!;
          break;
        case 'Tecnología':
          categoryIcon = Icons.computer;
          categoryColor = Colors.cyan[600]!;
          break;
        default:
          categoryIcon = Icons.category;
          categoryColor = Colors.grey[600]!;
      }
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 10,
        child: Container(
          padding: const EdgeInsets.all(0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                categoryColor.withValues(alpha: 0.1),
                Colors.white,
                categoryColor.withValues(alpha: 0.05),
              ],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header con ícono y título
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                  gradient: LinearGradient(
                    colors: [
                      categoryColor,
                      categoryColor.withValues(alpha: 0.8),
                    ],
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        categoryIcon,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            categoria == 'total' ? 'Presupuesto Total' : categoria,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Editar presupuesto',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Contenido del formulario
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    // Campo de texto mejorado
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: categoryColor.withValues(alpha: 0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: controller,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [
                          CurrencyInputFormatterFactory.create(decimalPlaces: currentCurrency.decimalPlaces),
                        ],
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Monto del presupuesto',
                          labelStyle: TextStyle(color: categoryColor),
                          prefixIcon: Container(
                            margin: const EdgeInsets.all(12),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: categoryColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              ref.watch(currencySymbolProvider),
                              style: TextStyle(
                                color: categoryColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: categoryColor, width: 2),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Texto de ayuda simple
                    Text(
                      categoria == 'total' 
                          ? 'El presupuesto total debe ser mayor o igual a la suma de categorías'
                          : 'Asegúrate de que el monto no exceda el presupuesto total disponible',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              
              // Botones de acción mejorados
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          'Cancelar',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: () async {
                          final String text = controller.text.trim();
                          if (text.isNotEmpty) {
                            final double? valor = CurrencyParser.parseFormattedCurrency(text);
                            if (valor != null && valor >= 0) {
                              // Validación adicional para categorías
                              if (categoria != 'total') {
                                final presupuestosActuales = ref.read(presupuestosMesSeleccionadoProvider);
                                final presupuestoTotalActual = presupuestosActuales['total'] ?? 0.0;
                                final sumaOtrasCategorias = _categorias
                                    .where((cat) => cat != categoria)
                                    .fold<double>(0.0, (sum, cat) => sum + (presupuestosActuales[cat] ?? 0.0));
                                
                                if (presupuestoTotalActual > 0 && (valor + sumaOtrasCategorias) > presupuestoTotalActual) {
                                  final disponible = presupuestoTotalActual - sumaOtrasCategorias;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Monto excede el presupuesto disponible. Máximo: ${currentCurrency.formatAmount(disponible)}'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                  return;
                                }
                              }
                              
                              try {
                                final monthKey = ref.read(currentMonthKeyProvider);
                                await ref.read(presupuestoProvider.notifier).setPresupuestoMesSeleccionado(monthKey, categoria, valor);
                                
                                if (context.mounted) {
                                  Navigator.of(context).pop();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Presupuesto ${categoria == 'total' ? 'total' : 'de $categoria'} actualizado'),
                                      backgroundColor: Colors.green,
                                      duration: const Duration(seconds: 1),
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Error al actualizar presupuesto: $e'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Por favor ingresa un monto válido'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: categoryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 3,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.save, size: 20),
                            const SizedBox(width: 8),
                            const Text(
                              'Guardar',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Obtener color basado en progreso
  Color _getColorProgreso(double progreso) {
    if (progreso < 0.5) {
      return Colors.green; // Menos del 50%
    } else if (progreso < 0.8) {
      return Colors.orange; // 50-80%
    } else {
      return Colors.red; // Más del 80%
    }
  }

  // Método para mostrar ayuda de la pantalla de presupuesto
  void _mostrarAyudaPresupuesto(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.info, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              const Expanded(
                child: Text('💳 Guía de Presupuesto'),
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
                    'Aquí planificas y controlas tu dinero mensual:',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 16),
                  
                  // Presupuesto Total Mensual
                  _buildInfoItem(
                    icon: Icons.account_balance_wallet,
                    color: Colors.blue,
                    title: 'Presupuesto Total Mensual',
                    description: 'Define cuánto dinero planeas gastar este mes en total.',
                  ),
                  
                  // Slider de Presupuesto Total
                  _buildInfoItem(
                    icon: Icons.tune,
                    color: Colors.green,
                    title: 'Control Deslizante Total',
                    description: 'Desliza para ajustar tu presupuesto mensual. Se adapta a tu moneda.',
                  ),
                  
                  // Resumen de Progreso
                  _buildInfoItem(
                    icon: Icons.analytics,
                    color: Colors.orange,
                    title: 'Resumen de Progreso',
                    description: 'Muestra cuánto has gastado vs. tu presupuesto total con porcentaje.',
                  ),
                  
                  // Categorías de Presupuesto
                  _buildInfoItem(
                    icon: Icons.category,
                    color: Colors.purple,
                    title: 'Presupuesto por Categorías',
                    description: 'Asigna dinero específico a cada tipo de gasto (Comida, Transporte, etc.).',
                  ),
                  
                  // Sliders de Categoría
                  
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
              color: color.withValues(alpha: 0.1),
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

  void _mostrarInfoPresupuesto(BuildContext context, WidgetRef ref, String categoria, double maximoAsignable, double presupuestoCategoria, double gastadoCategoria) {
    final currentCurrency = ref.watch(currencyProvider);
    final presupuestos = ref.watch(presupuestosMesSeleccionadoProvider);
    final totalGastado = ref.watch(totalGastadoMesSeleccionadoProvider);
    final totalPresupuesto = presupuestos['total'] ?? 0.0;
    final saldoDisponible = totalPresupuesto - totalGastado;
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.lightbulb_outline, color: Colors.orange[700], size: 24),
              const SizedBox(width: 8),
              const Text('Guía de Presupuesto', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Explicación del máximo asignable
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.assignment_outlined, color: Colors.blue[700], size: 18),
                          const SizedBox(width: 6),
                          Text('Máximo Asignable', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue[700])),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text('Para la categoría "$categoria": ${currentCurrency.formatAmount(maximoAsignable)}'),
                      const SizedBox(height: 4),
                      const Text(
                        'Es la cantidad máxima que puedes asignar a esta categoría sin exceder tu presupuesto total.',
                        style: TextStyle(fontSize: 12),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Cálculo: Se toma tu presupuesto total menos lo que ya gastaste en otras categorías.',
                        style: TextStyle(fontSize: 11, color: Colors.grey[700], fontStyle: FontStyle.italic),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Explicación del saldo disponible
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.account_balance_wallet_outlined, color: Colors.green[700], size: 18),
                          const SizedBox(width: 6),
                          Text('Saldo Disponible', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green[700])),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text('Total disponible: ${currentCurrency.formatAmount(saldoDisponible)}'),
                      const SizedBox(height: 4),
                      const Text(
                        'Es el dinero que te queda después de restar todos tus gastos del presupuesto total.',
                        style: TextStyle(fontSize: 12),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Cálculo: Presupuesto total - Todos los gastos realizados',
                        style: TextStyle(fontSize: 11, color: Colors.grey[700], fontStyle: FontStyle.italic),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Diferencias clave
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.compare_arrows, color: Colors.amber[700], size: 18),
                          const SizedBox(width: 6),
                          Text('Diferencias Clave', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber[700])),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _buildDiferencia('📊', 'Máximo Asignable', 'Se calcula por categoría individual'),
                      _buildDiferencia('💰', 'Saldo Disponible', 'Es un total general de toda la app'),
                      _buildDiferencia('🎯', 'Uso del Máximo Asignable', 'Para planificar presupuestos por categoría'),
                      _buildDiferencia('📈', 'Uso del Saldo Disponible', 'Para saber cuánto dinero tienes libre'),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Resumen de números actuales
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.purple[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.purple[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.analytics_outlined, color: Colors.purple[700], size: 18),
                          const SizedBox(width: 6),
                          Text('Tu Situación Actual', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.purple[700])),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _buildNumeroActual('💰', 'Presupuesto Total', totalPresupuesto),
                      _buildNumeroActual('🛒', 'Total Gastado', totalGastado),
                      _buildNumeroActual('✅', 'Saldo Disponible General', saldoDisponible),
                      _buildNumeroActual('📋', 'Presupuesto Actual ($categoria)', presupuestoCategoria),
                      _buildNumeroActual('💸', 'Gastado en $categoria', gastadoCategoria),
                      _buildNumeroActual('🎯', 'Máximo Asignable ($categoria)', maximoAsignable),
                    ],
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // Consejo adicional
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.indigo[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.indigo[200]!),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.tips_and_updates, color: Colors.indigo[600], size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Consejo: Si el "Máximo Asignable" es menor de lo esperado, revisa si has gastado mucho en otras categorías.',
                          style: TextStyle(fontSize: 11, color: Colors.indigo[700]),
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
              child: const Text('Entendido', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDiferencia(String emoji, String concepto, String descripcion) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 6),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 11, color: Colors.black87),
                children: [
                  TextSpan(text: '$concepto: ', style: const TextStyle(fontWeight: FontWeight.w600)),
                  TextSpan(text: descripcion),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNumeroActual(String emoji, String concepto, double valor) {
    return Consumer(
      builder: (context, ref, child) {
        final currentCurrency = ref.watch(currencyProvider);
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 1),
          child: Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 11)),
              const SizedBox(width: 6),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: const TextStyle(fontSize: 10, color: Colors.black87),
                    children: [
                      TextSpan(text: '$concepto: ', style: const TextStyle(fontWeight: FontWeight.w500)),
                      TextSpan(text: currentCurrency.formatAmount(valor), style: const TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}