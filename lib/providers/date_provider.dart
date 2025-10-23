import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider para manejar el mes y año seleccionado por el usuario
class DateSelectionNotifier extends StateNotifier<DateTime> {
  DateSelectionNotifier() : super(DateTime.now());

  /// Cambia al mes anterior
  void previousMonth() {
    final current = state;
    final previous = DateTime(current.year, current.month - 1, 1);
    state = previous;
  }

  /// Cambia al mes siguiente
  void nextMonth() {
    final current = state;
    final next = DateTime(current.year, current.month + 1, 1);
    state = next;
  }

  /// Va al mes actual
  void goToCurrentMonth() {
    final now = DateTime.now();
    state = DateTime(now.year, now.month, 1);
  }

  /// Establece un mes y año específico
  void setDate(int year, int month) {
    state = DateTime(year, month, 1);
  }

  /// Obtiene la clave del mes en formato "YYYY-MM"
  String getMonthKey() {
    final year = state.year.toString();
    final month = state.month.toString().padLeft(2, '0');
    return '$year-$month';
  }

  /// Obtiene el nombre del mes en español
  String getMonthName() {
    const months = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];
    return months[state.month - 1];
  }

  /// Obtiene el texto completo "Mes YYYY"
  String getDisplayText() {
    return '${getMonthName()} ${state.year}';
  }

  /// Verifica si es el mes actual
  bool isCurrentMonth() {
    final now = DateTime.now();
    return state.year == now.year && state.month == now.month;
  }

  /// Verifica si se puede navegar al mes siguiente (no permitir meses futuros)
  bool canGoToNextMonth() {
    final now = DateTime.now();
    final next = DateTime(state.year, state.month + 1, 1);
    return next.isBefore(DateTime(now.year, now.month + 1, 1)) || 
           (next.year == now.year && next.month == now.month);
  }
}

/// Provider principal para la fecha seleccionada
final dateSelectionProvider = StateNotifierProvider<DateSelectionNotifier, DateTime>((ref) {
  return DateSelectionNotifier();
});

/// Provider computed para obtener la clave del mes actual
final currentMonthKeyProvider = Provider<String>((ref) {
  final dateState = ref.watch(dateSelectionProvider);
  return "${dateState.year}-${dateState.month.toString().padLeft(2, '0')}";
});

/// Provider computed para obtener el texto a mostrar
final currentDisplayTextProvider = Provider<String>((ref) {
  final dateState = ref.watch(dateSelectionProvider);
  final months = [
    'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
    'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
  ];
  return '${months[dateState.month - 1]} ${dateState.year}';
});