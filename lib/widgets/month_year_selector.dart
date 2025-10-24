import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/date_provider.dart';
import '../theme/app_theme.dart';

/// Widget selector de mes/año con navegación temporal
class MonthYearSelector extends ConsumerWidget {
  final bool showCopyButton;
  final VoidCallback? onCopyFromPrevious;
  final bool isOnGradientBackground;

  const MonthYearSelector({
    super.key,
    this.showCopyButton = false,
    this.onCopyFromPrevious,
    this.isOnGradientBackground = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final displayText = ref.watch(currentDisplayTextProvider);
    final dateNotifier = ref.watch(dateSelectionProvider.notifier);
    
    // Colores adaptativos según el fondo
    final backgroundColor = isOnGradientBackground 
        ? Colors.white.withOpacity(0.15)
        : FinanxperColors.surface;
    final borderColor = isOnGradientBackground 
        ? Colors.white.withOpacity(0.3)
        : FinanxperColors.primary.withOpacity(0.3);
    final iconBackgroundColor = isOnGradientBackground 
        ? Colors.white.withOpacity(0.2)
        : FinanxperColors.primary.withOpacity(0.1);
    final iconColor = isOnGradientBackground 
        ? Colors.white
        : FinanxperColors.primary;
    final textColor = isOnGradientBackground 
        ? Colors.white
        : FinanxperColors.textPrimary;
    final buttonBackgroundColor = isOnGradientBackground 
        ? Colors.white.withOpacity(0.1)
        : FinanxperColors.primary.withOpacity(0.1);
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
        boxShadow: isOnGradientBackground ? [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ] : FinanxperColors.softShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Icono de calendario
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: iconBackgroundColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.calendar_month,
                color: iconColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            
            // Botón mes anterior
            Container(
              decoration: BoxDecoration(
                color: buttonBackgroundColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: IconButton(
                onPressed: () => dateNotifier.previousMonth(),
                icon: Icon(Icons.chevron_left, color: iconColor),
                tooltip: 'Mes anterior',
              ),
            ),
            
            // Texto del mes actual con gesto para selector
            Expanded(
              child: GestureDetector(
                onTap: () => _showMonthYearPicker(context, ref),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    displayText,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: textColor,
                      fontSize: 16,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ),
            
            // Botón mes siguiente (solo si no es futuro)
            Container(
              decoration: BoxDecoration(
                color: buttonBackgroundColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: IconButton(
                onPressed: dateNotifier.canGoToNextMonth() 
                    ? () => dateNotifier.nextMonth()
                    : null,
                icon: Icon(
                  Icons.chevron_right, 
                  color: dateNotifier.canGoToNextMonth() 
                      ? iconColor 
                      : iconColor.withOpacity(0.5),
                ),
                tooltip: 'Mes siguiente',
              ),
            ),
            
            // Botón ir al mes actual
            if (!dateNotifier.isCurrentMonth())
              IconButton(
                onPressed: () => dateNotifier.goToCurrentMonth(),
                icon: Icon(Icons.today, color: iconColor),
                tooltip: 'Ir al mes actual',
              ),
            
            // Botón copiar del mes anterior (opcional)
            if (showCopyButton && onCopyFromPrevious != null)
              IconButton(
                onPressed: onCopyFromPrevious,
                icon: Icon(Icons.copy, color: iconColor),
                tooltip: 'Copiar del mes anterior',
              ),
          ],
        ),
      ),
    );
  }

  /// Muestra el selector de mes y año
  void _showMonthYearPicker(BuildContext context, WidgetRef ref) {
    final dateNotifier = ref.read(dateSelectionProvider.notifier);
    final currentDate = ref.read(dateSelectionProvider);
    final now = DateTime.now();
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Seleccionar Mes y Año'),
          content: SizedBox(
            width: 300,
            height: 300,
            child: YearMonth(
              initialDate: currentDate,
              firstDate: DateTime(2020, 1),
              lastDate: now,
              onChanged: (date) {
                dateNotifier.setDate(date.year, date.month);
                Navigator.of(context).pop();
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
          ],
        );
      },
    );
  }
}

/// Widget personalizado para seleccionar año y mes
class YearMonth extends StatefulWidget {
  final DateTime initialDate;
  final DateTime firstDate;
  final DateTime lastDate;
  final Function(DateTime) onChanged;

  const YearMonth({
    super.key,
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
    required this.onChanged,
  });

  @override
  State<YearMonth> createState() => _YearMonthState();
}

class _YearMonthState extends State<YearMonth> {
  late int selectedYear;
  late int selectedMonth;

  final List<String> months = [
    'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
    'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
  ];

  @override
  void initState() {
    super.initState();
    selectedYear = widget.initialDate.year;
    selectedMonth = widget.initialDate.month;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Selector de año
        DropdownButtonFormField<int>(
          value: selectedYear,
          decoration: const InputDecoration(
            labelText: 'Año',
            border: OutlineInputBorder(),
          ),
          items: List.generate(
            widget.lastDate.year - widget.firstDate.year + 1,
            (index) {
              final year = widget.firstDate.year + index;
              return DropdownMenuItem<int>(
                value: year,
                child: Text(year.toString()),
              );
            },
          ),
          onChanged: (value) {
            if (value != null) {
              setState(() {
                selectedYear = value;
                // Validar que el mes no sea futuro
                final selectedDate = DateTime(selectedYear, selectedMonth);
                if (selectedDate.isAfter(widget.lastDate)) {
                  selectedMonth = widget.lastDate.month;
                }
              });
            }
          },
        ),
        
        const SizedBox(height: 16),
        
        // Selector de mes
        DropdownButtonFormField<int>(
          value: selectedMonth,
          decoration: const InputDecoration(
            labelText: 'Mes',
            border: OutlineInputBorder(),
          ),
          items: List.generate(12, (index) {
            final month = index + 1;
            final isEnabled = DateTime(selectedYear, month).isBefore(
              DateTime(widget.lastDate.year, widget.lastDate.month + 1)
            );
            return DropdownMenuItem<int>(
              value: month,
              enabled: isEnabled,
              child: Text(
                months[index],
                style: TextStyle(
                  color: isEnabled ? null : Colors.grey,
                ),
              ),
            );
          }),
          onChanged: (value) {
            if (value != null) {
              setState(() {
                selectedMonth = value;
              });
            }
          },
        ),
        
        const SizedBox(height: 24),
        
        // Botón seleccionar
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              final selectedDate = DateTime(selectedYear, selectedMonth);
              if (!selectedDate.isAfter(widget.lastDate)) {
                widget.onChanged(selectedDate);
              }
            },
            child: const Text('Seleccionar'),
          ),
        ),
      ],
    );
  }
}