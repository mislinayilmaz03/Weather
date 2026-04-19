/// Data model representing current weather information for a city.
class WeatherData {
  final String cityName;
  final String country;
  final String region;
  final double temperature; // in Celsius
  final double humidity; // percentage
  final double windSpeed; // km/h
  final String condition; // e.g., "Sunny", "Rainy", "Snowy", "Cloudy"
  final String icon; // emoji representation

  WeatherData({
    required this.cityName,
    this.country = '',
    this.region = '',
    required this.temperature,
    required this.humidity,
    required this.windSpeed,
    required this.condition,
    required this.icon,
  });
}

/// Data model for a single day in the 7-day forecast.
class ForecastDay {
  final String day; // translation key, e.g., "mon"
  final double highTemp;
  final double lowTemp;
  final String condition;
  final String icon;

  ForecastDay({
    required this.day,
    required this.highTemp,
    required this.lowTemp,
    required this.condition,
    required this.icon,
  });
}

/// Data model for hourly forecast entry.
class HourlyForecast {
  final String time; // e.g., "9 AM", "Now"
  final double temperature;
  final String icon;
  final String condition;

  HourlyForecast({
    required this.time,
    required this.temperature,
    required this.icon,
    required this.condition,
  });
}

/// Data model for outfit suggestion with image and seasonal color palette.
class OutfitSuggestion {
  final String description;
  final String imageUrl;
  final String imageQuery; // Unsplash search query for dynamic image
  final List<SeasonalColor> seasonalColors;
  final String seasonName; // translation key for season

  OutfitSuggestion({
    required this.description,
    required this.imageUrl,
    this.imageQuery = '',
    this.seasonalColors = const [],
    this.seasonName = '',
  });
}

/// Represents a single color swatch in a seasonal palette.
class SeasonalColor {
  final int colorValue; // 0xAARRGGBB format
  final String name; // translation key

  const SeasonalColor({required this.colorValue, required this.name});
}
