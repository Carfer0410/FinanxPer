import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:google_mobile_ads/google_mobile_ads.dart'; // TEMPORALMENTE COMENTADO
import 'models/gasto.dart';
import 'models/currency.dart';
import 'providers/first_time_provider.dart';
import 'screens/home_screen.dart';
import 'screens/gastos_screen.dart';
import 'screens/presupuesto_screen.dart';
import 'screens/tips_screen.dart';
import 'screens/configuraciones_screen.dart';
import 'screens/welcome_screen.dart';
import 'widgets/global_notification_listener.dart';

// Plugin de notificaciones locales
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

// Variable global para premium (futura monetización)
bool isPremium = false;

Future<void> main() async {
  // Inicializar widgets
  WidgetsFlutterBinding.ensureInitialized();

  // Configurar Hive para almacenamiento local
  final appDocumentDir = await getApplicationDocumentsDirectory();
  await Hive.initFlutter(appDocumentDir.path);
  Hive.registerAdapter(GastoAdapter());
  Hive.registerAdapter(PresupuestoAdapter());
  Hive.registerAdapter(CurrencyAdapter());
  await Hive.openBox<Gasto>('gastos');
  await Hive.openBox<Presupuesto>('presupuestos');
  await Hive.openBox<String>('presupuestos_config'); // Para configuración de presupuestos
  await Hive.openBox<String>('currency_config'); // Para configuración de moneda
  await Hive.openBox<bool>('app_config'); // Para configuración de primera vez

  // Inicializar notificaciones locales
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  const DarwinInitializationSettings initializationSettingsIOS =
      DarwinInitializationSettings();
  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsIOS,
  );
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  // Configurar AdMob con test ad unit IDs - TEMPORALMENTE COMENTADO
  // await MobileAds.instance.initialize();

  // Ejecutar aplicación con Riverpod
  runApp(
    const ProviderScope(
      child: FinanxperApp(),
    ),
  );
}

/// Aplicación principal de Finanxper
class FinanxperApp extends StatelessWidget {
  const FinanxperApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Finanxper',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1976D2), // Azul principal
          secondary: const Color(0xFF4CAF50), // Verde éxito
          brightness: Brightness.light,
        ),
      ),
      locale: const Locale('es', 'ES'),
      home: const AppStartScreen(),
      routes: {
        '/main': (context) => const MainScreen(),
        '/gastos': (context) => const GastosScreen(),
        '/presupuesto': (context) => const PresupuestoScreen(),
        '/tips': (context) => const TipsScreen(),
        '/configuraciones': (context) => const ConfiguracionesScreen(),
      },
    );
  }
}

/// Pantalla de inicio que decide si mostrar bienvenida o app principal
class AppStartScreen extends ConsumerWidget {
  const AppStartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFirstTime = ref.watch(firstTimeProvider);

    // Si es la primera vez, mostrar pantalla de bienvenida
    if (isFirstTime) {
      return const WelcomeScreen();
    }

    // Si no, mostrar la app principal
    return const MainScreen();
  }
}

/// Pantalla principal con navegación inferior mejorada
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  // Lista de pantallas importadas correctamente
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      HomeScreen(onNavigateToTab: _navigateToTab),
      const GastosScreen(),
      const PresupuestoScreen(),
      const TipsScreen(),
      const ConfiguracionesScreen(),
    ];
  }

  void _navigateToTab(int tabIndex) {
    setState(() {
      _currentIndex = tabIndex;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GlobalNotificationListener(
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: _screens,
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          type: BottomNavigationBarType.fixed,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          selectedItemColor: Theme.of(context).colorScheme.primary,
          unselectedItemColor: Colors.grey,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.add_circle),
              label: 'Agregar',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.account_balance_wallet),
              label: 'Presupuesto',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.tips_and_updates),
              label: 'Tips',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings),
              label: 'Configuración',
            ),
          ],
        ),
      ),
    );
  }
}