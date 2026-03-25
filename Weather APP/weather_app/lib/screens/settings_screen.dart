import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/weather_provider.dart';

/// Settings Screen — allows users to configure app preferences.
/// Currently supports toggling between Celsius and Fahrenheit.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<WeatherProvider>(context);

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──
            Text(
              'Settings',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'Customize your experience',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),

            // ── Temperature Unit Toggle ──
            _buildSettingsCard(
              icon: Icons.thermostat,
              iconColor: Colors.orange,
              title: 'Temperature Unit',
              subtitle: provider.useCelsius ? 'Celsius (°C)' : 'Fahrenheit (°F)',
              trailing: Switch(
                value: provider.useCelsius,
                activeTrackColor: Colors.deepPurple,
                onChanged: (_) => provider.toggleTemperatureUnit(),
              ),
            ),
            const SizedBox(height: 12),

            // ── Current City Info ──
            _buildSettingsCard(
              icon: Icons.location_on,
              iconColor: Colors.blue,
              title: 'Current City',
              subtitle: provider.currentWeather.cityName,
              trailing: const Icon(Icons.chevron_right, color: Colors.grey),
            ),
            const SizedBox(height: 12),

            // ── Favourites Count ──
            _buildSettingsCard(
              icon: Icons.favorite,
              iconColor: Colors.pink,
              title: 'Saved Cities',
              subtitle: '${provider.favouriteCities.length} favourite cities',
              trailing: const Icon(Icons.chevron_right, color: Colors.grey),
            ),
            const SizedBox(height: 12),

            // ── About Section ──
            _buildSettingsCard(
              icon: Icons.info_outline,
              iconColor: Colors.teal,
              title: 'About',
              subtitle: 'Weather App with Outfit Suggester v1.0',
              trailing: const Icon(Icons.chevron_right, color: Colors.grey),
            ),

            const Spacer(),

            // ── Available Cities Reference ──
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.deepPurple.shade50,
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Available Cities (Dummy Data)',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Colors.deepPurple,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: provider.availableCities
                        .map(
                          (city) => Chip(
                            label: Text(city, style: const TextStyle(fontSize: 12)),
                            backgroundColor: Colors.white,
                            padding: EdgeInsets.zero,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  /// Reusable settings row card.
  Widget _buildSettingsCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required Widget trailing,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 30),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 25),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}
