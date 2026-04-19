import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/weather_provider.dart';

/// Favourites Screen — iOS Weather style city list with theme support.
class FavouritesScreen extends StatelessWidget {
  final VoidCallback? onCitySelected;

  const FavouritesScreen({super.key, this.onCitySelected});

  static const List<List<Color>> _darkGradients = [
    [Color(0xFF1A2980), Color(0xFF26D0CE)],
    [Color(0xFF2C3E50), Color(0xFF4CA1AF)],
    [Color(0xFF0F2027), Color(0xFF2C5364)],
    [Color(0xFF373B44), Color(0xFF4286f4)],
    [Color(0xFF1F1C2C), Color(0xFF928DAB)],
  ];

  static const List<List<Color>> _lightGradients = [
    [Color(0xFF667eea), Color(0xFF764ba2)],
    [Color(0xFF2193b0), Color(0xFF6dd5ed)],
    [Color(0xFF4facfe), Color(0xFF00f2fe)],
    [Color(0xFFa18cd1), Color(0xFFfbc2eb)],
    [Color(0xFF43e97b), Color(0xFF38f9d7)],
  ];

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<WeatherProvider>(context);
    final favourites = provider.favouriteCities;
    final topPad = MediaQuery.of(context).padding.top;
    final dark = provider.isDarkMode;
    final fg = dark ? Colors.white : Colors.black87;
    final fgSub = dark ? Colors.white60 : Colors.black45;
    final grads = dark ? _darkGradients : _lightGradients;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: EdgeInsets.fromLTRB(20, topPad + 16, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(provider.tr('favourite_cities'),
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w300, color: fg)),
            const SizedBox(height: 4),
            Text('${favourites.length} ${provider.tr('saved_cities_count')}',
                style: TextStyle(fontSize: 14, color: fgSub)),
            const SizedBox(height: 20),
            Expanded(
              child: favourites.isEmpty
                  ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.favorite_border, size: 64, color: dark ? Colors.white24 : Colors.grey.shade300),
                      const SizedBox(height: 12),
                      Text(provider.tr('no_favourites'), textAlign: TextAlign.center, style: TextStyle(fontSize: 15, color: fgSub)),
                    ]))
                  : ListView.separated(
                      physics: const BouncingScrollPhysics(),
                      itemCount: favourites.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final city = favourites[index];
                        final isSel = city == provider.currentWeather.cityName;
                        final grad = grads[index % grads.length];
                        return GestureDetector(
                          onTap: () {
                            provider.selectCity(city);
                            if (onCitySelected != null) onCitySelected!();
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: grad, begin: Alignment.topLeft, end: Alignment.bottomRight),
                              borderRadius: BorderRadius.circular(18),
                              border: isSel ? Border.all(color: const Color(0xFF3B82F6), width: 2) : null,
                              boxShadow: [BoxShadow(color: grad[0].withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))],
                            ),
                            padding: const EdgeInsets.all(20),
                            child: Row(children: [
                              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(city, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600)),
                                const SizedBox(height: 4),
                                Text(isSel ? provider.tr('currently_viewing') : provider.tr('tap_to_view'),
                                    style: const TextStyle(color: Colors.white60, fontSize: 13)),
                              ])),
                              IconButton(
                                onPressed: () => provider.removeFavourite(city),
                                icon: const Icon(Icons.close, color: Colors.white54, size: 20),
                              ),
                            ]),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
