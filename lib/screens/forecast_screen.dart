import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/weather_provider.dart';

/// Forecast Screen — Hourly horizontal scroll + 7-day forecast list.
class ForecastScreen extends StatelessWidget {
  const ForecastScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<WeatherProvider>(context);
    final forecast = provider.forecast;
    final hourly = provider.hourlyForecast;
    final cityName = provider.currentWeather.cityName;
    final topPad = MediaQuery.of(context).padding.top;
    final dark = provider.isDarkMode;
    final fg = dark ? Colors.white : Colors.black87;
    final fgSub = dark ? Colors.white54 : Colors.black38;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.fromLTRB(20, topPad + 16, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──
            Text(provider.tr('forecast'),
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w300, color: fg)),
            const SizedBox(height: 4),
            Text(cityName, style: TextStyle(fontSize: 16, color: fgSub)),
            const SizedBox(height: 20),

            // ── Hourly Forecast Card ──
            _glassCard(dark, child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Icon(Icons.access_time, size: 14, color: fgSub),
                  const SizedBox(width: 6),
                  Text(provider.tr('hourly_forecast').toUpperCase(),
                      style: TextStyle(color: fgSub, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1)),
                ]),
                Divider(color: dark ? Colors.white24 : Colors.grey.shade300, height: 20),
                SizedBox(
                  height: 120,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    itemCount: hourly.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 16),
                    itemBuilder: (_, i) {
                      final h = hourly[i];
                      final isNow = h.time == 'now';
                      return SizedBox(
                        width: 56,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Text(
                              isNow ? provider.tr('now') : h.time,
                              style: TextStyle(
                                color: isNow ? const Color(0xFF3B82F6) : (dark ? Colors.white70 : Colors.black54),
                                fontSize: 13,
                                fontWeight: isNow ? FontWeight.w700 : FontWeight.w500,
                              ),
                            ),
                            Text(h.icon, style: const TextStyle(fontSize: 26)),
                            Text(
                              '${provider.displayTemp(h.temperature).toStringAsFixed(0)}°',
                              style: TextStyle(
                                color: fg,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            )),
            const SizedBox(height: 16),

            // ── 7-Day Forecast Card ──
            _glassCard(dark, child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Icon(Icons.calendar_today, size: 14, color: fgSub),
                  const SizedBox(width: 6),
                  Text(provider.tr('seven_day_forecast').toUpperCase(),
                      style: TextStyle(color: fgSub, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1)),
                ]),
                Divider(color: dark ? Colors.white24 : Colors.grey.shade300, height: 20),
                ...List.generate(forecast.length, (index) {
                  final day = forecast[index];
                  return Column(children: [
                    if (index > 0) Divider(color: dark ? Colors.white.withOpacity(0.1) : Colors.grey.shade200, height: 1),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(children: [
                        SizedBox(width: 42, child: Text(provider.tr(day.day), style: TextStyle(color: fg, fontSize: 15, fontWeight: FontWeight.w500))),
                        Text(day.icon, style: const TextStyle(fontSize: 26)),
                        const SizedBox(width: 10),
                        SizedBox(width: 36, child: Text('${provider.displayTemp(day.lowTemp).toStringAsFixed(0)}°', style: TextStyle(color: fgSub, fontSize: 14))),
                        Expanded(child: _buildTempBar(provider, day, dark)),
                        SizedBox(width: 36, child: Text('${provider.displayTemp(day.highTemp).toStringAsFixed(0)}°', textAlign: TextAlign.right, style: TextStyle(color: fg, fontSize: 14, fontWeight: FontWeight.w500))),
                      ]),
                    ),
                  ]);
                }),
              ],
            )),
          ],
        ),
      ),
    );
  }

  Widget _glassCard(bool dark, {required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: dark ? Colors.white.withOpacity(0.12) : Colors.white.withOpacity(0.7),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: dark ? Colors.white.withOpacity(0.2) : Colors.grey.withOpacity(0.2), width: 0.5),
          ),
          padding: const EdgeInsets.all(16),
          child: child,
        ),
      ),
    );
  }

  Widget _buildTempBar(WeatherProvider provider, dynamic day, bool dark) {
    return LayoutBuilder(builder: (context, constraints) {
      final w = constraints.maxWidth;
      const lo = -10.0, hi = 45.0;
      final l = provider.displayTemp(day.lowTemp);
      final h = provider.displayTemp(day.highTemp);
      final lf = ((l - lo) / (hi - lo)).clamp(0.0, 1.0);
      final hf = ((h - lo) / (hi - lo)).clamp(0.0, 1.0);
      return Stack(children: [
        Container(height: 5, decoration: BoxDecoration(color: dark ? Colors.white.withOpacity(0.1) : Colors.grey.shade200, borderRadius: BorderRadius.circular(3))),
        Positioned(
          left: w * lf,
          width: w * (hf - lf).clamp(0.05, 1.0),
          child: Container(height: 5, decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF3B82F6), Color(0xFFF59E0B)]), borderRadius: BorderRadius.circular(3))),
        ),
      ]);
    });
  }
}
