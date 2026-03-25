import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/weather_provider.dart';

/// Forecast Screen — displays a 5-day weather outlook for the current city.
/// All data is read from the global WeatherProvider.
class ForecastScreen extends StatelessWidget {
  const ForecastScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<WeatherProvider>(context);
    final forecast = provider.forecast;
    final cityName = provider.currentWeather.cityName;

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──
            Text(
              '5-Day Forecast',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              cityName,
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 20),

            // ── Forecast List ──
            Expanded(
              child: ListView.separated(
                itemCount: forecast.length,
                separatorBuilder: (_, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final day = forecast[index];
                  return _ForecastCard(day: day, provider: provider);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A single forecast day card.
class _ForecastCard extends StatelessWidget {
  final dynamic day;
  final WeatherProvider provider;

  const _ForecastCard({required this.day, required this.provider});

  @override
  Widget build(BuildContext context) {
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
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          // Day name
          SizedBox(
            width: 48,
            child: Text(
              day.day,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          // Weather icon
          Text(day.icon, style: const TextStyle(fontSize: 32)),
          const SizedBox(width: 12),

          // Condition
          Expanded(
            child: Text(
              day.condition,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
            ),
          ),

          // High / Low temperatures
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${provider.displayTemp(day.highTemp).toStringAsFixed(0)}${provider.unitLabel}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${provider.displayTemp(day.lowTemp).toStringAsFixed(0)}${provider.unitLabel}',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
