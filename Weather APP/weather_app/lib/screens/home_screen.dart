import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/weather_provider.dart';

/// Home Screen — displays current weather, city search bar, and outfit suggestion.
/// Uses Provider for global weather state and setState() for the local search bar.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // ── Local state managed with setState() for the search bar ──
  final TextEditingController _searchController = TextEditingController();
  String _searchError = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Handles city search — updates local error state with setState()
  /// and global weather state via Provider.
  void _onSearch(WeatherProvider provider) {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      setState(() => _searchError = 'Please enter a city name.');
      return;
    }

    final found = provider.searchCity(query);
    setState(() {
      _searchError = found
          ? ''
          : 'City "$query" not found. Try: ${provider.availableCities.join(", ")}';
    });

    if (found) {
      _searchController.clear();
      FocusScope.of(context).unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Access the global weather state via Provider
    final provider = Provider.of<WeatherProvider>(context);
    final weather = provider.currentWeather;

    return Scaffold(
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── City Search Bar (local state with setState) ──
              _buildSearchBar(provider),
              const SizedBox(height: 24),

              // ── Main Weather Card ──
              _buildWeatherCard(provider, weather),
              const SizedBox(height: 16),

              // ── Weather Details Row ──
              _buildWeatherDetailsRow(provider, weather),
              const SizedBox(height: 20),

              // ── Outfit Suggestion Card ──
              _buildOutfitCard(provider),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────
  // WIDGETS
  // ─────────────────────────────────────────────────────────────────────

  /// Search bar with local state management via setState().
  Widget _buildSearchBar(WeatherProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search city...',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                ),
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _onSearch(provider),
                // Clear error while user types — local setState
                onChanged: (_) {
                  if (_searchError.isNotEmpty) {
                    setState(() => _searchError = '');
                  }
                },
              ),
            ),
            const SizedBox(width: 8),
            Material(
              color: Colors.deepPurple,
              borderRadius: BorderRadius.circular(30),
              child: InkWell(
                borderRadius: BorderRadius.circular(30),
                onTap: () => _onSearch(provider),
                child: const Padding(
                  padding: EdgeInsets.all(12),
                  child: Icon(Icons.search, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
        // Error message — driven by local state
        if (_searchError.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 12),
            child: Text(
              _searchError,
              style: const TextStyle(color: Colors.redAccent, fontSize: 13),
            ),
          ),
      ],
    );
  }

  /// Main weather display card with gradient background.
  Widget _buildWeatherCard(WeatherProvider provider, dynamic weather) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6C63FF), Color(0xFF48C6EF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.withValues(alpha: 80),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(28),
      child: Column(
        children: [
          // City name + favourite toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.location_on, color: Colors.white70, size: 20),
              const SizedBox(width: 4),
              Text(
                weather.cityName,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  if (provider.isFavourite(weather.cityName)) {
                    provider.removeFavourite(weather.cityName);
                  } else {
                    provider.addFavourite(weather.cityName);
                  }
                },
                child: Icon(
                  provider.isFavourite(weather.cityName)
                      ? Icons.favorite
                      : Icons.favorite_border,
                  color: Colors.pinkAccent.shade100,
                  size: 22,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Weather icon
          Text(weather.icon, style: const TextStyle(fontSize: 72)),
          const SizedBox(height: 8),
          // Temperature
          Text(
            '${provider.displayTemp(weather.temperature).toStringAsFixed(0)}${provider.unitLabel}',
            style: const TextStyle(
              fontSize: 56,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          // Condition
          Text(
            weather.condition,
            style: const TextStyle(
              fontSize: 18,
              color: Colors.white70,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// Humidity & wind speed detail cards.
  Widget _buildWeatherDetailsRow(WeatherProvider provider, dynamic weather) {
    return Row(
      children: [
        Expanded(
          child: _detailCard(
            icon: Icons.water_drop,
            label: 'Humidity',
            value: '${weather.humidity.toStringAsFixed(0)}%',
            color: Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _detailCard(
            icon: Icons.air,
            label: 'Wind',
            value: '${weather.windSpeed.toStringAsFixed(0)} km/h',
            color: Colors.teal,
          ),
        ),
      ],
    );
  }

  Widget _detailCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 40),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 30),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Outfit suggestion card — reads suggestion from Provider.
  Widget _buildOutfitCard(WeatherProvider provider) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 40),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 30),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.checkroom, color: Colors.orange, size: 24),
              ),
              const SizedBox(width: 12),
              const Text(
                'Outfit Suggestion',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            provider.getOutfitSuggestion(),
            style: const TextStyle(fontSize: 16, height: 1.5),
          ),
        ],
      ),
    );
  }
}
