import 'package:flutter/material.dart';
import '../models/weather_model.dart';

/// WeatherProvider manages the global "current weather state" using Provider.
/// It holds dummy weather data, forecast data, favourite cities, and settings.
class WeatherProvider extends ChangeNotifier {
  // ─── Current Weather ───────────────────────────────────────────────

  WeatherData _currentWeather = _dummyWeatherDatabase['Amman']!;

  WeatherData get currentWeather => _currentWeather;

  // ─── 5-Day Forecast ────────────────────────────────────────────────

  List<ForecastDay> _forecast = _generateForecast('Amman');

  List<ForecastDay> get forecast => _forecast;

  // ─── Favourite Cities ──────────────────────────────────────────────

  final List<String> _favouriteCities = ['Amman', 'London', 'Tokyo'];

  List<String> get favouriteCities => List.unmodifiable(_favouriteCities);

  // ─── Settings ──────────────────────────────────────────────────────

  bool _useCelsius = true;

  bool get useCelsius => _useCelsius;

  /// Toggle between Celsius and Fahrenheit.
  void toggleTemperatureUnit() {
    _useCelsius = !_useCelsius;
    notifyListeners();
  }

  /// Helper to convert temperature based on current unit preference.
  double displayTemp(double celsius) {
    if (_useCelsius) return celsius;
    return celsius * 9 / 5 + 32; // Convert to Fahrenheit
  }

  /// Returns the unit label string.
  String get unitLabel => _useCelsius ? '°C' : '°F';

  // ─── City Search / Selection ───────────────────────────────────────

  /// Search for a city in the dummy database and update current weather.
  /// Returns true if the city was found, false otherwise.
  bool searchCity(String cityName) {
    final key = _dummyWeatherDatabase.keys.firstWhere(
      (k) => k.toLowerCase() == cityName.trim().toLowerCase(),
      orElse: () => '',
    );
    if (key.isEmpty) return false;

    _currentWeather = _dummyWeatherDatabase[key]!;
    _forecast = _generateForecast(key);
    notifyListeners();
    return true;
  }

  /// Select a city directly (e.g., from favourites list).
  void selectCity(String cityName) {
    if (_dummyWeatherDatabase.containsKey(cityName)) {
      _currentWeather = _dummyWeatherDatabase[cityName]!;
      _forecast = _generateForecast(cityName);
      notifyListeners();
    }
  }

  // ─── Favourite Management ──────────────────────────────────────────

  /// Add a city to favourites if it exists in the database and isn't already saved.
  bool addFavourite(String cityName) {
    final key = _dummyWeatherDatabase.keys.firstWhere(
      (k) => k.toLowerCase() == cityName.trim().toLowerCase(),
      orElse: () => '',
    );
    if (key.isEmpty || _favouriteCities.contains(key)) return false;
    _favouriteCities.add(key);
    notifyListeners();
    return true;
  }

  /// Remove a city from favourites.
  void removeFavourite(String cityName) {
    _favouriteCities.remove(cityName);
    notifyListeners();
  }

  bool isFavourite(String cityName) => _favouriteCities.contains(cityName);

  // ─── Outfit Suggestion Logic ───────────────────────────────────────

  /// Returns an outfit suggestion based on the current temperature and condition.
  String getOutfitSuggestion() {
    final temp = _currentWeather.temperature;
    final condition = _currentWeather.condition.toLowerCase();

    // Cold weather (below 5°C)
    if (temp < 5) {
      if (condition.contains('snow')) {
        return '🧥 Wear a heavy winter coat, scarf, gloves, and snow boots.';
      }
      return '🧥 Wear a heavy coat, scarf, and warm layers.';
    }

    // Cool weather (5–15°C)
    if (temp < 15) {
      if (condition.contains('rain')) {
        return '🧥 Wear a waterproof jacket with a warm sweater underneath.';
      }
      return '🧶 Wear a light jacket or sweater with long pants.';
    }

    // Mild weather (15–25°C)
    if (temp < 25) {
      if (condition.contains('rain')) {
        return '☂️ Carry an umbrella! A light rain jacket and jeans work well.';
      }
      if (condition.contains('cloud')) {
        return '👕 A long-sleeve shirt and comfortable pants are perfect.';
      }
      return '👕 A light shirt and comfortable pants — enjoy the nice weather!';
    }

    // Hot weather (25°C+)
    if (condition.contains('rain')) {
      return '🌂 It\'s warm but rainy — light clothes with an umbrella.';
    }
    return '👕 T-shirt, shorts, and sunglasses — stay cool and hydrated!';
  }

  // ─── Dummy Weather Database ────────────────────────────────────────

  static final Map<String, WeatherData> _dummyWeatherDatabase = {
    'Amman': WeatherData(
      cityName: 'Amman',
      temperature: 22,
      humidity: 45,
      windSpeed: 12,
      condition: 'Sunny',
      icon: '☀️',
    ),
    'London': WeatherData(
      cityName: 'London',
      temperature: 12,
      humidity: 78,
      windSpeed: 20,
      condition: 'Rainy',
      icon: '🌧️',
    ),
    'Tokyo': WeatherData(
      cityName: 'Tokyo',
      temperature: 18,
      humidity: 65,
      windSpeed: 10,
      condition: 'Cloudy',
      icon: '☁️',
    ),
    'Dubai': WeatherData(
      cityName: 'Dubai',
      temperature: 38,
      humidity: 30,
      windSpeed: 8,
      condition: 'Sunny',
      icon: '☀️',
    ),
    'Moscow': WeatherData(
      cityName: 'Moscow',
      temperature: -5,
      humidity: 85,
      windSpeed: 25,
      condition: 'Snowy',
      icon: '❄️',
    ),
    'New York': WeatherData(
      cityName: 'New York',
      temperature: 15,
      humidity: 60,
      windSpeed: 18,
      condition: 'Partly Cloudy',
      icon: '⛅',
    ),
    'Paris': WeatherData(
      cityName: 'Paris',
      temperature: 14,
      humidity: 70,
      windSpeed: 15,
      condition: 'Rainy',
      icon: '🌧️',
    ),
    'Sydney': WeatherData(
      cityName: 'Sydney',
      temperature: 26,
      humidity: 55,
      windSpeed: 14,
      condition: 'Sunny',
      icon: '☀️',
    ),
  };

  /// Expose available cities for search suggestions.
  List<String> get availableCities => _dummyWeatherDatabase.keys.toList();

  // ─── Dummy Forecast Generator ──────────────────────────────────────

  static List<ForecastDay> _generateForecast(String city) {
    final base = _dummyWeatherDatabase[city];
    if (base == null) return [];

    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'];
    final conditions = ['Sunny', 'Cloudy', 'Rainy', 'Partly Cloudy', 'Sunny'];
    final icons = ['☀️', '☁️', '🌧️', '⛅', '☀️'];

    return List.generate(5, (i) {
      // Vary temperature slightly per day for realism
      final variation = (i - 2) * 2.0;
      return ForecastDay(
        day: days[i],
        highTemp: base.temperature + variation + 3,
        lowTemp: base.temperature + variation - 4,
        condition: conditions[i],
        icon: icons[i],
      );
    });
  }
}
