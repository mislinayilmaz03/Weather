import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/weather_provider.dart';

/// Favourites Screen — lists saved favourite cities.
/// Tapping a city selects it and navigates back to the Home tab.
class FavouritesScreen extends StatelessWidget {
  /// Callback to switch the bottom navigation to the Home tab.
  final VoidCallback? onCitySelected;

  const FavouritesScreen({super.key, this.onCitySelected});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<WeatherProvider>(context);
    final favourites = provider.favouriteCities;

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──
            Text(
              'Favourite Cities',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              '${favourites.length} saved cities',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 20),

            // ── Favourites List ──
            Expanded(
              child: favourites.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.favorite_border,
                              size: 64, color: Colors.grey.shade300),
                          const SizedBox(height: 12),
                          Text(
                            'No favourite cities yet.\nSearch a city on the Home screen\nand tap the heart icon.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      itemCount: favourites.length,
                      separatorBuilder: (_, index) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final city = favourites[index];
                        final isSelected =
                            city == provider.currentWeather.cityName;

                        return Container(
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.deepPurple.shade50
                                : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: isSelected
                                ? Border.all(
                                    color: Colors.deepPurple, width: 1.5)
                                : null,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withValues(alpha: 30),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 8,
                            ),
                            leading: CircleAvatar(
                              backgroundColor:
                                  Colors.deepPurple.withValues(alpha: 25),
                              child: const Icon(Icons.location_city,
                                  color: Colors.deepPurple),
                            ),
                            title: Text(
                              city,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                                color: isSelected
                                    ? Colors.deepPurple
                                    : Colors.black87,
                              ),
                            ),
                            subtitle: isSelected
                                ? const Text('Currently viewing',
                                    style:
                                        TextStyle(color: Colors.deepPurple))
                                : const Text('Tap to view weather'),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline,
                                  color: Colors.redAccent),
                              onPressed: () =>
                                  provider.removeFavourite(city),
                            ),
                            onTap: () {
                              // Select this city via Provider
                              provider.selectCity(city);
                              // Navigate to Home tab if callback is provided
                              if (onCitySelected != null) {
                                onCitySelected!();
                              }
                            },
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
