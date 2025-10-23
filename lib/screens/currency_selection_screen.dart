import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/currency.dart';
import '../providers/currency_provider.dart';

class CurrencySelectionScreen extends ConsumerStatefulWidget {
  final bool isInitialSetup;

  const CurrencySelectionScreen({
    super.key,
    this.isInitialSetup = false,
  });

  @override
  ConsumerState<CurrencySelectionScreen> createState() => _CurrencySelectionScreenState();
}

class _CurrencySelectionScreenState extends ConsumerState<CurrencySelectionScreen> {
  String _searchQuery = '';
  String _selectedRegion = 'Todas';

  @override
  Widget build(BuildContext context) {
    final currentCurrency = ref.watch(currencyProvider);
    final currenciesByRegion = ref.watch(currenciesByRegionProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isInitialSetup ? 'Selecciona tu moneda' : 'Cambiar moneda'),
        backgroundColor: Colors.green.shade600,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Header con información actual
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.green.shade600, Colors.green.shade500],
              ),
            ),
            child: Column(
              children: [
                if (!widget.isInitialSetup) ...[
                  const Text(
                    'Moneda actual:',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${currentCurrency.flag} ${currentCurrency.name}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                Text(
                  widget.isInitialSetup 
                    ? 'Esta será la moneda principal de tu app' 
                    : 'Selecciona una nueva moneda',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          // Barra de búsqueda y filtros
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Campo de búsqueda
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Buscar país o moneda...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value.toLowerCase();
                    });
                  },
                ),
                const SizedBox(height: 12),

                // Filtro por región
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildRegionChip('Todas'),
                      ...currenciesByRegion.keys.map((region) => _buildRegionChip(region)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Lista de monedas
          Expanded(
            child: _buildCurrencyList(currenciesByRegion),
          ),
        ],
      ),
    );
  }

  Widget _buildRegionChip(String region) {
    final isSelected = _selectedRegion == region;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(region),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedRegion = region;
          });
        },
        selectedColor: Colors.green.shade100,
        checkmarkColor: Colors.green.shade700,
      ),
    );
  }

  Widget _buildCurrencyList(Map<String, List<Currency>> currenciesByRegion) {
    List<Currency> filteredCurrencies = [];

    if (_selectedRegion == 'Todas') {
      filteredCurrencies = AvailableCurrencies.all;
    } else {
      filteredCurrencies = currenciesByRegion[_selectedRegion] ?? [];
    }

    // Aplicar filtro de búsqueda
    if (_searchQuery.isNotEmpty) {
      filteredCurrencies = filteredCurrencies.where((currency) {
        return currency.country.toLowerCase().contains(_searchQuery) ||
               currency.name.toLowerCase().contains(_searchQuery) ||
               currency.code.toLowerCase().contains(_searchQuery);
      }).toList();
    }

    // Eliminar duplicados (países que usan USD)
    final Map<String, Currency> uniqueCurrencies = {};
    for (final currency in filteredCurrencies) {
      final key = '${currency.code}_${currency.country}';
      uniqueCurrencies[key] = currency;
    }

    final List<Currency> finalList = uniqueCurrencies.values.toList();
    finalList.sort((a, b) => a.country.compareTo(b.country));

    if (finalList.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'No se encontraron monedas',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: finalList.length,
      itemBuilder: (context, index) {
        final currency = finalList[index];
        final isSelected = ref.watch(currencyProvider).code == currency.code &&
                          ref.watch(currencyProvider).country == currency.country;

        return _buildCurrencyTile(currency, isSelected);
      },
    );
  }

  Widget _buildCurrencyTile(Currency currency, bool isSelected) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.grey.shade100,
        child: Text(
          currency.flag,
          style: const TextStyle(fontSize: 24),
        ),
      ),
      title: Text(
        currency.country,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      subtitle: Text('${currency.name} (${currency.code})'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            currency.symbol,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.green.shade600,
            ),
          ),
          const SizedBox(width: 8),
          if (isSelected)
            Icon(
              Icons.check_circle,
              color: Colors.green.shade600,
            ),
        ],
      ),
      selected: isSelected,
      selectedTileColor: Colors.green.shade50,
      onTap: () => _selectCurrency(currency),
    );
  }

  Future<void> _selectCurrency(Currency currency) async {
    // Mostrar loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      // Actualizar la moneda
      await ref.read(currencyProvider.notifier).setCurrency(currency);
      
      // Forzar reconstrucción del widget consumidor al esperar un frame
      await Future.delayed(const Duration(milliseconds: 50));

      // Cerrar loading
      if (mounted) Navigator.of(context).pop();

      // Mostrar confirmación
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Moneda cambiada a ${currency.name}'),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }

      // Navegar hacia atrás
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      // Cerrar loading si hay error
      if (mounted) Navigator.of(context).pop();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cambiar moneda: $e'),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}