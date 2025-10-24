import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/gastos_provider.dart';
import '../theme/app_theme.dart';

// Variable global para premium (futura monetización)
bool isPremium = false;

/// Pantalla de tips anti-deudas
class TipsScreen extends ConsumerStatefulWidget {
  const TipsScreen({super.key});

  @override
  ConsumerState<TipsScreen> createState() => _TipsScreenState();
}

class _TipsScreenState extends ConsumerState<TipsScreen> {
  int _currentTipSet = 0;

  // Lista de tips estáticos con múltiples sets
  static const List<List<String>> _tipsEstaticosVariados = [
    // Set 1 - Tips básicos
    [
      '1. Compra productos genéricos en el supermercado para ahorrar hasta 20% en gastos de comida.',
      '2. Usa transporte público 3 días a la semana para reducir significativamente tus gastos de transporte.',
      '3. Cancela suscripciones que no uses. Revisa tus apps bancarias mensualmente.',
      '4. Cocina en casa en lugar de comer fuera. Prepara comidas para llevar al trabajo.',
      '5. Espera a que haya ofertas antes de comprar ropa o tecnología. Las rebajas pueden ahorrar 50%.',
      '6. Revisa tu plan de telefonía móvil. Cambia a uno más económico si consumes poco.',
      '7. Compra medicamentos genéricos en lugar de marca. El ahorro puede ser del 30-50%.',
      '8. Usa energía LED en tu casa. Reduce la factura de luz hasta en un 80%.',
      '9. Evita las compras por impulso. Espera 24 horas antes de comprar algo no esencial.',
      '10. Invierte en educación financiera. Lee libros como "Padre Rico, Padre Pobre".',
    ],
    // Set 2 - Tips avanzados
    [
      '1. Implementa la regla 50/30/20: 50% necesidades, 30% gustos, 20% ahorros.',
      '2. Usa apps de cupones y descuentos antes de cada compra importante.',
      '3. Compra al por mayor productos no perecederos que uses frecuentemente.',
      '4. Negocia tus seguros anualmente. Puedes ahorrar hasta 15% cambiando de proveedor.',
      '5. Establece un día sin gastos a la semana. Usa solo lo que tienes en casa.',
      '6. Vende artículos que no uses. Convierte el desorden en dinero extra.',
      '7. Participa en programas de lealtad de tiendas donde compras frecuentemente.',
      '8. Repara en lugar de reemplazar. YouTube tiene tutoriales para casi todo.',
      '9. Usa la biblioteca pública para libros, películas y eventos gratuitos.',
      '10. Cultiva algunas hierbas y vegetales en casa. Incluso en macetas pequeñas.',
    ],
    // Set 3 - Tips específicos
    [
      '1. Planifica tus comidas semanalmente para evitar desperdicios y gastos extra.',
      '2. Compra ropa de temporada al final de la estación con grandes descuentos.',
      '3. Usa agua fría para lavar ropa. Ahorras energía sin perder calidad de limpieza.',
      '4. Aprovecha las horas valle de electricidad si tienes tarifa diferenciada.',
      '5. Intercambia servicios con amigos: cuidado de niños, reparaciones, clases.',
      '6. Compra vehículos usados de 2-3 años. Evitas la depreciación inicial.',
      '7. Usa aplicaciones para dividir gastos compartidos con roommates o pareja.',
      '8. Aprovecha descuentos de estudiante, adulto mayor o empleado si aplicas.',
      '9. Prepara regalos caseros para ocasiones especiales. Son más personales y económicos.',
      '10. Revisa y disputa cargos incorrectos en tarjetas de crédito mensualmente.',
    ],
  ];

  @override
  Widget build(BuildContext context) {
    final ref = this.ref;
    final resumenGastos = ref.watch(gastosProvider.notifier).getResumenCategorias();

    // Encontrar la categoría más gastada
    String categoriaTop = 'Comida'; // Default
    double maxGasto = 0;
    resumenGastos.forEach((categoria, gasto) {
      if (gasto > maxGasto) {
        maxGasto = gasto;
        categoriaTop = categoria;
      }
    });

    // Obtener tips personalizados basados en la categoría top
    final tipsPersonalizados = _getTipsPersonalizados(categoriaTop);

    return Scaffold(
      backgroundColor: FinanxperColors.background,
      appBar: AppBar(
        title: const Text('💡 Tips Anti-Deudas'),
        backgroundColor: FinanxperColors.warning,
        foregroundColor: FinanxperColors.textOnPrimary,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [FinanxperColors.warning, FinanxperColors.accent],
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
              onPressed: () => _mostrarAyudaTips(context),
              tooltip: 'Información de Tips',
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.delayed(const Duration(seconds: 1));
          setState(() {
            _currentTipSet = (_currentTipSet + 1) % _tipsEstaticosVariados.length;
          });
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Tips actualizados - Set ${_currentTipSet + 1}')),
            );
          }
        },
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Banner premium (si no es premium)
            if (!isPremium) _buildPremiumBanner(),

            const SizedBox(height: 20),

            // Título sección personalizada
            const Text(
              'Tips Personalizados para Ti',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Card(
              elevation: 4,
              color: Colors.blue[50],
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tu categoría más gastada es: $categoriaTop',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ...tipsPersonalizados.map((tip) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('💡 ', style: TextStyle(fontSize: 16)),
                          Expanded(
                            child: Text(
                              tip,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    )),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),

            // Título sección general
            const Text(
              'Tips Generales Anti-Deudas',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            // Lista de tips estáticos
            ..._tipsEstaticosVariados[_currentTipSet].map((tip) => Card(
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('💰 ', style: TextStyle(fontSize: 16)),
                    Expanded(
                      child: Text(
                        tip,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            )),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // Banner para premium
  Widget _buildPremiumBanner() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.amber, Colors.orange],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        children: [
          Icon(Icons.star, color: Colors.white, size: 30),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '¡Actualiza a Premium!',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  'Tips ilimitados y funciones avanzadas por solo \$1.99/mes',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.arrow_forward, color: Colors.white),
        ],
      ),
    );
  }

  // Obtener tips personalizados basados en categoría
  List<String> _getTipsPersonalizados(String categoria) {
    switch (categoria) {
      case 'Comida':
        return [
          'Prepara tus comidas en casa. Cocinar es más económico y saludable.',
          'Haz una lista de compras semanal y cíñete a ella para evitar gastos extras.',
          'Compra frutas y verduras de temporada, son más baratas y nutritivas.',
        ];
      case 'Transporte':
        return [
          'Combina transporte público con bicicleta para reducir costos.',
          'Mantén tu vehículo en buen estado para evitar reparaciones costosas.',
          'Comparte viajes con compañeros de trabajo cuando sea posible.',
        ];
      case 'Entretenimiento':
        return [
          'Utiliza Netflix Party o plataformas similares para compartir suscripciones.',
          'Busca eventos gratuitos en tu ciudad: conciertos, exposiciones, parques.',
          'Intercambia libros o juegos con amigos en lugar de comprar nuevos.',
        ];
      case 'Vivienda':
        return [
          'Negocia el alquiler con tu casero. Un descuento del 5-10% es común.',
          'Reduce el consumo de energía apagando luces y electrodomésticos.',
          'Considera mudarte a un barrio más económico si es viable.',
        ];
      case 'Salud':
        return [
          'Compra medicamentos genéricos, cuestan hasta 70% menos.',
          'Haz ejercicio al aire libre en parques para ahorrar en gimnasios.',
          'Programa revisiones médicas anuales para prevenir enfermedades costosas.',
        ];
      case 'Educación':
        return [
          'Utiliza bibliotecas públicas y recursos online gratuitos.',
          'Busca becas y programas de ayuda financiera para cursos.',
          'Comparte libros de texto con compañeros de estudio.',
        ];
      case 'Ropa':
        return [
          'Compra en tiendas de segunda mano o mercados de pulgas.',
          'Establece un presupuesto mensual fijo para ropa.',
          'Arregla la ropa dañada en lugar de tirarla.',
        ];
      case 'Tecnología':
        return [
          'Espera a que bajen los precios de nuevos lanzamientos tecnológicos.',
          'Utiliza software gratuito en lugar de versiones pagas.',
          'Vende tus dispositivos antiguos antes de comprar nuevos.',
        ];
      default:
        return [
          'Revisa tus gastos mensuales y identifica áreas de mejora.',
          'Establece metas de ahorro realistas y síguelas.',
          'Educa sobre finanzas personales para tomar mejores decisiones.',
        ];
    }
  }

  // Método para mostrar ayuda de la pantalla de tips
  void _mostrarAyudaTips(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.info, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              const Expanded(
                child: Text('💡 Guía de Tips Anti-Deudas'),
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
                    'Aquí encontrarás consejos para mejorar tus finanzas:',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 16),
                  
                  // Banner Premium
                  _buildInfoItem(
                    icon: Icons.star,
                    color: Colors.amber,
                    title: 'Banner Premium',
                    description: 'Información sobre funciones avanzadas y suscripción premium.',
                  ),
                  
                  // Tips Personalizados
                  _buildInfoItem(
                    icon: Icons.person,
                    color: Colors.blue,
                    title: 'Tips Personalizados',
                    description: 'Consejos específicos basados en tu categoría de mayor gasto actual.',
                  ),
                  
                  // Categoría Top
                  _buildInfoItem(
                    icon: Icons.trending_up,
                    color: Colors.red,
                    title: 'Tu Categoría Más Gastada',
                    description: 'Se actualiza automáticamente según tus gastos registrados.',
                  ),
                  
                  // Tips Generales
                  _buildInfoItem(
                    icon: Icons.lightbulb,
                    color: Colors.green,
                    title: 'Tips Generales Rotativos',
                    description: 'Diferentes sets de consejos que cambian al deslizar para refrescar.',
                  ),
                  
                  // Actualización de Tips
                  _buildInfoItem(
                    icon: Icons.refresh,
                    color: Colors.purple,
                    title: 'Cambiar Set de Tips',
                    description: 'Desliza hacia abajo para ver un nuevo conjunto de consejos financieros.',
                  ),
                  
                  // Tips por Categoría
                  _buildInfoItem(
                    icon: Icons.category,
                    color: Colors.teal,
                    title: 'Consejos Personalizados',
                    description: 'Los tips de arriba se adaptan según dónde gastas más dinero.',
                  ),
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
}