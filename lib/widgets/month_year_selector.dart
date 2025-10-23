import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/date_provider.dart';

/// Widget selector de mes/año con navegación temporal
class MonthYearSelector extends ConsumerWidget {
  final bool showCopyButton;
  final VoidCallback? onCopyFromPrevious;

  const MonthYearSelector({
    super.key,
    this.showCopyButton = false,
    this.onCopyFromPrevious,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final displayText = ref.watch(currentDisplayTextProvider);
    final dateNotifier = ref.watch(dateSelectionProvider.notifier);
    
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Icono de calendario
            Icon(
              Icons.calendar_month,
              color: Theme.of(context).colorScheme.primary,
              size: 24,
            ),
            const SizedBox(width: 12),
            
            // Botón mes anterior
            IconButton(
              onPressed: () => dateNotifier.previousMonth(),
              icon: const Icon(Icons.chevron_left),
              tooltip: 'Mes anterior',
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
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ),
            ),
            
            // Botón mes siguiente (solo si no es futuro)
            IconButton(
              onPressed: dateNotifier.canGoToNextMonth() 
                  ? () => dateNotifier.nextMonth()
                  : null,
              icon: const Icon(Icons.chevron_right),
              tooltip: 'Mes siguiente',
            ),
            
            // Botón ir al mes actual
            if (!dateNotifier.isCurrentMonth())
              IconButton(
                onPressed: () => dateNotifier.goToCurrentMonth(),
                icon: const Icon(Icons.today),
                tooltip: 'Ir al mes actual',
                color: Theme.of(context).colorScheme.secondary,
              ),
            
            // Botón copiar del mes anterior (opcional)
            if (showCopyButton && onCopyFromPrevious != null)
              IconButton(
                onPressed: onCopyFromPrevious,
                icon: const Icon(Icons.copy),
                tooltip: 'Copiar del mes anterior',
                color: Colors.green,
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