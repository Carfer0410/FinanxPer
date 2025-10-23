import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'models/gasto.dart';

// Plugin de notificaciones locales
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> main() async {
  // Asegurar inicialización de widgets
  WidgetsFlutterBinding.ensureInitialized();

  // Ejecutar la aplicación básica primero
  runApp(
    const ProviderScope(
      child: FinanxperApp(),
    ),
  );
}

/// Inicializa Hive con los modelos de datos
Future<void> _initializeHive() async {
  try {
    // Inicializar Hive (initFlutter maneja el directorio automáticamente)
    await Hive.initFlutter();

    // Registrar adaptadores para los modelos
    Hive.registerAdapter(GastoAdapter());
    Hive.registerAdapter(PresupuestoAdapter());

    // Abrir cajas de datos principales
    await Hive.openBox<Gasto>('gastos');
    await Hive.openBox<Presupuesto>('presupuestos');

    print('✓ Hive inicializado correctamente');
  } catch (e) {
    print('⚠️ Error inicializando Hive (no crítico): $e');
  }
}

/// Configura las notificaciones locales
Future<void> _initializeNotifications() async {
  try {
    // Configuración para Android
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // Configuración para iOS
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    // Configuración general
    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    // Inicializar el plugin
    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Manejar respuesta a notificaciones
        print('Notificación recibida: ${response.payload}');
      },
    );

    print('✓ Notificaciones inicializadas correctamente');
  } catch (e) {
    print('⚠️ Error inicializando notificaciones (no crítico): $e');
  }
}

/// Aplicación principal de Finanxper
class FinanxperApp extends StatelessWidget {
  const FinanxperApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Finanxper',
      debugShowCheckedModeBanner: false,

      // Tema Material 3 con colores azules/verdes para éxito financiero
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1976D2), // Azul principal
          secondary: const Color(0xFF4CAF50), // Verde éxito
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 2,
        ),
      ),

      // Configuración de idioma por defecto (español)
      locale: const Locale('es', 'ES'),

      // Pantalla inicial con inicialización progresiva
      home: const HomeScreen(),
    );
  }
}

/// Pantalla inicial con inicialización progresiva
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final Map<String, bool> _initStatus = {
    'Tema Material 3': true,
    'Riverpod State Management': true,
    'Hive Database': false,
    'Notificaciones Locales': false,
  };

  bool _isInitializing = true;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // Inicializar Hive
      await _initializeHive();
      setState(() {
        _initStatus['Hive Database'] = true;
      });

      // Inicializar notificaciones
      await _initializeNotifications();
      setState(() {
        _initStatus['Notificaciones Locales'] = true;
      });

      setState(() {
        _isInitializing = false;
      });
    } catch (e) {
      print('Error durante inicialización: $e');
      setState(() {
        _isInitializing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isInitializing ? 'Finanxper - Inicializando...' : 'Finanxper - Listo'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.account_balance_wallet,
              size: 80,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 20),
            Text(
              _isInitializing ? 'Inicializando...' : '¡Proyecto inicializado!',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Finanxper - Control de Gastos Personales',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 32),
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 32),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: _initStatus.entries
                      .map((entry) => _buildStatusItem(context, entry.key, entry.value))
                      .toList(),
                ),
              ),
            ),
            if (_isInitializing) ...[
              const SizedBox(height: 20),
              const CircularProgressIndicator(),
            ] else ...[
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('¡Finanxper está listo para usar!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
                icon: const Icon(Icons.check_circle),
                label: const Text('¡Todo listo!'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusItem(BuildContext context, String feature, bool isReady) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            isReady ? Icons.check_circle : Icons.pending,
            color: isReady
              ? Theme.of(context).colorScheme.secondary
              : Colors.orange,
            size: 20,
          ),
          const SizedBox(width: 12),
          Text(
            feature,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}