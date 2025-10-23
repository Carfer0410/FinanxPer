import 'package:hive/hive.dart';

class Gasto extends HiveObject {
  int id;
  double monto;
  String categoria;
  String descripcion;
  DateTime fecha;
  bool recurrente;
  String? currencyCode; // Código de moneda (USD, COP, MXN, etc.)

  Gasto({
    required this.id,
    required this.monto,
    required this.categoria,
    required this.descripcion,
    required this.fecha,
    this.recurrente = false,
    this.currencyCode,
  });

  // Categorías predefinidas para el enum-like
  static const List<String> categorias = [
    'Comida',
    'Transporte',
    'Vivienda',
    'Salud',
    'Entretenimiento',
    'Educación',
    'Ropa',
    'Tecnología',
    'Otros',
  ];

  /// Obtiene la clave del mes en formato "YYYY-MM"
  String getMonthKey() {
    final year = fecha.year.toString();
    final month = fecha.month.toString().padLeft(2, '0');
    return '$year-$month';
  }

  /// Verifica si el gasto pertenece al mes especificado
  bool belongsToMonth(String monthKey) {
    return getMonthKey() == monthKey;
  }

  /// Verifica si el gasto pertenece al mes y año dados
  bool belongsToMonthYear(int year, int month) {
    return fecha.year == year && fecha.month == month;
  }

  /// Verifica si el gasto es del mes actual
  bool isFromCurrentMonth() {
    final now = DateTime.now();
    return belongsToMonthYear(now.year, now.month);
  }

  /// Obtiene el nombre del mes del gasto en español
  String getMonthName() {
    const months = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];
    return months[fecha.month - 1];
  }

  @override
  String toString() {
    return 'Gasto{id: $id, monto: $monto, categoria: $categoria, descripcion: $descripcion, fecha: $fecha, recurrente: $recurrente, currencyCode: $currencyCode}';
  }
}

// Modelo adicional para presupuestos
class Presupuesto extends HiveObject {
  int id;
  String categoria;
  double limite;
  DateTime fechaInicio;
  DateTime fechaFin;
  String? currencyCode; // Código de moneda (USD, COP, MXN, etc.)

  Presupuesto({
    required this.id,
    required this.categoria,
    required this.limite,
    required this.fechaInicio,
    required this.fechaFin,
    this.currencyCode,
  });

  @override
  String toString() {
    return 'Presupuesto{id: $id, categoria: $categoria, limite: $limite, fechaInicio: $fechaInicio, fechaFin: $fechaFin, currencyCode: $currencyCode}';
  }
}

// Adapters personalizados para manejar la serialización correctamente
class GastoAdapter extends TypeAdapter<Gasto> {
  @override
  final int typeId = 0;

  @override
  Gasto read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Gasto(
      id: fields[0] as int,
      monto: fields[1] as double,
      categoria: fields[2] as String,
      descripcion: fields[3] as String,
      fecha: DateTime.fromMillisecondsSinceEpoch(fields[4] as int),
      recurrente: fields[5] as bool? ?? false,
      currencyCode: fields[6] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Gasto obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.monto)
      ..writeByte(2)
      ..write(obj.categoria)
      ..writeByte(3)
      ..write(obj.descripcion)
      ..writeByte(4)
      ..write(obj.fecha.millisecondsSinceEpoch)
      ..writeByte(5)
      ..write(obj.recurrente)
      ..writeByte(6)
      ..write(obj.currencyCode);
  }
}

class PresupuestoAdapter extends TypeAdapter<Presupuesto> {
  @override
  final int typeId = 1;

  @override
  Presupuesto read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Presupuesto(
      id: fields[0] as int,
      categoria: fields[1] as String,
      limite: fields[2] as double,
      fechaInicio: DateTime.fromMillisecondsSinceEpoch(fields[3] as int),
      fechaFin: DateTime.fromMillisecondsSinceEpoch(fields[4] as int),
      currencyCode: fields[5] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Presupuesto obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.categoria)
      ..writeByte(2)
      ..write(obj.limite)
      ..writeByte(3)
      ..write(obj.fechaInicio.millisecondsSinceEpoch)
      ..writeByte(4)
      ..write(obj.fechaFin.millisecondsSinceEpoch)
      ..writeByte(5)
      ..write(obj.currencyCode);
  }
}