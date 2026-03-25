/// Data model representing current weather information for a city.
class WeatherData {
  final String cityName;
  final double temperature; // in Celsius
  final double humidity; // percentage
  final double windSpeed; // km/h
  final String condition; // e.g., "Sunny", "Rainy", "Snowy", "Cloudy"
  final String icon; // emoji representation

  WeatherData({
    required this.cityName,
    required this.temperature,
    required this.humidity,
    required this.windSpeed,
    required this.condition,
    required this.icon,
  });
}

/// Data model for a single day in the 5-day forecast.
class ForecastDay {
  final String day; // e.g., "Monday"
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
