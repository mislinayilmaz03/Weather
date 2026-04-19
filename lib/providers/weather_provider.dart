import 'package:flutter/material.dart';
import '../models/weather_model.dart';

/// WeatherProvider manages global app state: weather data, forecasts,
/// favourites, settings, localization, gender, dark mode, and outfits.
class WeatherProvider extends ChangeNotifier {
  // ─── Current Weather ───────────────────────────────────────────────

  WeatherData _currentWeather = _cityWeatherDB['Amman']!;
  WeatherData get currentWeather => _currentWeather;

  // ─── 7-Day Forecast ────────────────────────────────────────────────

  List<ForecastDay> _forecast = _generateForecast(_cityWeatherDB['Amman']!);
  List<ForecastDay> get forecast => _forecast;

  // ─── Hourly Forecast ───────────────────────────────────────────────

  List<HourlyForecast> _hourlyForecast =
      _generateHourly(_cityWeatherDB['Amman']!);
  List<HourlyForecast> get hourlyForecast => _hourlyForecast;

  // ─── Favourite Cities ──────────────────────────────────────────────

  final List<String> _favouriteCities = ['Amman', 'London', 'Tokyo'];
  List<String> get favouriteCities => List.unmodifiable(_favouriteCities);

  // ─── Temperature Unit ──────────────────────────────────────────────

  bool _useCelsius = true;
  bool get useCelsius => _useCelsius;

  void toggleTemperatureUnit() {
    _useCelsius = !_useCelsius;
    notifyListeners();
  }

  void setCelsius(bool val) {
    _useCelsius = val;
    notifyListeners();
  }

  double displayTemp(double celsius) {
    if (_useCelsius) return celsius;
    return celsius * 9 / 5 + 32;
  }

  String get unitLabel => _useCelsius ? '°C' : '°F';

  // ─── Dark Mode ─────────────────────────────────────────────────────

  bool _isDarkMode = true;
  bool get isDarkMode => _isDarkMode;

  void toggleDarkMode() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  // ─── Gender Selection ──────────────────────────────────────────────

  String _selectedGender = 'male';
  String get selectedGender => _selectedGender;

  void setGender(String gender) {
    _selectedGender = gender;
    notifyListeners();
  }

  // ─── Language ──────────────────────────────────────────────────────

  String _language = 'en';
  String get language => _language;

  static const List<Map<String, String>> supportedLanguages = [
    {'code': 'en', 'name': 'English', 'flag': '🇬🇧'},
    {'code': 'tr', 'name': 'Türkçe', 'flag': '🇹🇷'},
    {'code': 'ar', 'name': 'العربية', 'flag': '🇯🇴'},
    {'code': 'ru', 'name': 'Русский', 'flag': '🇷🇺'},
    {'code': 'es', 'name': 'Español', 'flag': '🇪🇸'},
    {'code': 'it', 'name': 'Italiano', 'flag': '🇮🇹'},
  ];

  void setLanguage(String langCode) {
    _language = langCode;
    notifyListeners();
  }

  String tr(String key) {
    return _translations[_language]?[key] ?? _translations['en']?[key] ?? key;
  }

  // ─── Country / City / District Selection ───────────────────────────

  String _selectedCountry = 'Jordan';
  String _selectedCity = 'Amman';
  String _selectedDistrict = 'Abdali';

  String get selectedCountry => _selectedCountry;
  String get selectedCity => _selectedCity;
  String get selectedDistrict => _selectedDistrict;

  List<String> get countries => _countryData.keys.toList();

  List<String> getCitiesForCountry(String country) =>
      _countryData[country]?.keys.toList() ?? [];

  List<String> getDistrictsForCity(String country, String city) =>
      _countryData[country]?[city] ?? [];

  String translateCountry(String country) =>
      _countryTranslations[_language]?[country] ?? country;

  void setCountry(String country) {
    _selectedCountry = country;
    final cities = getCitiesForCountry(country);
    if (cities.isNotEmpty) {
      _selectedCity = cities.first;
      final districts = getDistrictsForCity(country, _selectedCity);
      _selectedDistrict = districts.isNotEmpty ? districts.first : '';
    }
    _updateWeatherForSelection();
    notifyListeners();
  }

  void setCity(String city) {
    _selectedCity = city;
    final districts = getDistrictsForCity(_selectedCountry, city);
    _selectedDistrict = districts.isNotEmpty ? districts.first : '';
    _updateWeatherForSelection();
    notifyListeners();
  }

  void setDistrict(String district) {
    _selectedDistrict = district;
    _updateWeatherForSelection();
    notifyListeners();
  }

  void _updateWeatherForSelection() {
    final baseWeather = _cityWeatherDB[_selectedCity];
    if (baseWeather != null) {
      final districts = getDistrictsForCity(_selectedCountry, _selectedCity);
      final districtIndex = districts.indexOf(_selectedDistrict);
      final tempVar = districtIndex > 0 ? (districtIndex % 3 - 1) * 1.0 : 0.0;
      _currentWeather = WeatherData(
        cityName: _selectedDistrict.isNotEmpty
            ? '$_selectedCity - $_selectedDistrict'
            : _selectedCity,
        country: _selectedCountry,
        region: _selectedDistrict,
        temperature: baseWeather.temperature + tempVar,
        humidity: baseWeather.humidity,
        windSpeed: baseWeather.windSpeed,
        condition: baseWeather.condition,
        icon: baseWeather.icon,
      );
      _forecast = _generateForecast(_currentWeather);
      _hourlyForecast = _generateHourly(_currentWeather);
    }
  }

  // ─── City Search / Selection ───────────────────────────────────────

  bool searchCity(String cityName) {
    final key = _cityWeatherDB.keys.firstWhere(
      (k) => k.toLowerCase() == cityName.trim().toLowerCase(),
      orElse: () => '',
    );
    if (key.isEmpty) return false;
    for (final country in _countryData.keys) {
      if (_countryData[country]!.containsKey(key)) {
        _selectedCountry = country;
        _selectedCity = key;
        final districts = getDistrictsForCity(country, key);
        _selectedDistrict = districts.isNotEmpty ? districts.first : '';
        break;
      }
    }
    _updateWeatherForSelection();
    notifyListeners();
    return true;
  }

  void selectCity(String cityName) {
    final parts = cityName.split(' - ');
    if (_cityWeatherDB.containsKey(parts[0])) searchCity(parts[0]);
  }

  // ─── Favourite Management ──────────────────────────────────────────

  bool addFavourite(String cityName) {
    if (_favouriteCities.contains(cityName)) return false;
    _favouriteCities.add(cityName);
    notifyListeners();
    return true;
  }

  void removeFavourite(String cityName) {
    _favouriteCities.remove(cityName);
    notifyListeners();
  }

  bool isFavourite(String cityName) => _favouriteCities.contains(cityName);

  // ─── Seasonal Color Palette ────────────────────────────────────────

  String get currentSeason {
    final temp = _currentWeather.temperature;
    if (temp < 5) return 'winter';
    if (temp < 15) return 'autumn';
    if (temp < 25) return 'spring';
    return 'summer';
  }

  List<SeasonalColor> get seasonalColors {
    switch (currentSeason) {
      case 'winter':
        return const [
          SeasonalColor(colorValue: 0xFF800020, name: 'clr_burgundy'),
          SeasonalColor(colorValue: 0xFF1B1F3B, name: 'clr_navy'),
          SeasonalColor(colorValue: 0xFF228B22, name: 'clr_forest'),
          SeasonalColor(colorValue: 0xFF36454F, name: 'clr_charcoal'),
          SeasonalColor(colorValue: 0xFFE8E8E8, name: 'clr_ivory'),
        ];
      case 'autumn':
        return const [
          SeasonalColor(colorValue: 0xFFCC5500, name: 'clr_burnt_orange'),
          SeasonalColor(colorValue: 0xFFE1AD01, name: 'clr_mustard'),
          SeasonalColor(colorValue: 0xFF6B8E23, name: 'clr_olive'),
          SeasonalColor(colorValue: 0xFF800020, name: 'clr_burgundy'),
          SeasonalColor(colorValue: 0xFF8B4513, name: 'clr_saddle_brown'),
        ];
      case 'spring':
        return const [
          SeasonalColor(colorValue: 0xFFFFB6C1, name: 'clr_pastel_pink'),
          SeasonalColor(colorValue: 0xFFE6E6FA, name: 'clr_lavender'),
          SeasonalColor(colorValue: 0xFF98FB98, name: 'clr_mint'),
          SeasonalColor(colorValue: 0xFFFFFDD0, name: 'clr_soft_yellow'),
          SeasonalColor(colorValue: 0xFF87CEEB, name: 'clr_sky_blue'),
        ];
      default:
        return const [
          SeasonalColor(colorValue: 0xFFFF6F61, name: 'clr_coral'),
          SeasonalColor(colorValue: 0xFF40E0D0, name: 'clr_turquoise'),
          SeasonalColor(colorValue: 0xFFFFFAFA, name: 'clr_white'),
          SeasonalColor(colorValue: 0xFFC2B280, name: 'clr_sand'),
          SeasonalColor(colorValue: 0xFFFFD700, name: 'clr_gold'),
        ];
    }
  }

  // ─── Outfit Suggestion Logic (Gender-aware + dynamic images) ─────

  /// Build a dynamic Unsplash URL based on outfit item keywords.
  String _unsplashUrl(String query) =>
      'https://source.unsplash.com/featured/600x400/?fashion,$query';

  OutfitSuggestion getOutfitSuggestion() {
    final temp = _currentWeather.temperature;
    final cond = _currentWeather.condition.toLowerCase();
    final m = _selectedGender == 'male';
    final colors = seasonalColors;
    final season = currentSeason;

    if (temp < 5) {
      if (cond.contains('snow')) {
        final q = m ? 'winter+coat,man,snow+boots' : 'puffer+jacket,woman,fur+boots';
        return OutfitSuggestion(
          description: tr(m ? 'outfit_snow_m' : 'outfit_snow_f'),
          imageUrl: _unsplashUrl(q), imageQuery: q,
          seasonalColors: colors, seasonName: season,
        );
      }
      final q = m ? 'wool+overcoat,man,leather+boots' : 'trench+coat,woman,ankle+boots';
      return OutfitSuggestion(
        description: tr(m ? 'outfit_heavy_cold_m' : 'outfit_heavy_cold_f'),
        imageUrl: _unsplashUrl(q), imageQuery: q,
        seasonalColors: colors, seasonName: season,
      );
    }
    if (temp < 15) {
      if (cond.contains('rain')) {
        final q = m ? 'waterproof+parka,man,rain+boots' : 'trench+coat,woman,chelsea+boots';
        return OutfitSuggestion(
          description: tr(m ? 'outfit_cool_rain_m' : 'outfit_cool_rain_f'),
          imageUrl: _unsplashUrl(q), imageQuery: q,
          seasonalColors: colors, seasonName: season,
        );
      }
      final q = m ? 'bomber+jacket,man,chinos' : 'cardigan,woman,midi+skirt';
      return OutfitSuggestion(
        description: tr(m ? 'outfit_cool_m' : 'outfit_cool_f'),
        imageUrl: _unsplashUrl(q), imageQuery: q,
        seasonalColors: colors, seasonName: season,
      );
    }
    if (temp < 25) {
      if (cond.contains('rain')) {
        final q = m ? 'rain+jacket,man,jeans' : 'raincoat,woman,floral+dress';
        return OutfitSuggestion(
          description: tr(m ? 'outfit_mild_rain_m' : 'outfit_mild_rain_f'),
          imageUrl: _unsplashUrl(q), imageQuery: q,
          seasonalColors: colors, seasonName: season,
        );
      }
      final q = m ? 'button+shirt,man,white+sneakers' : 'blouse,woman,linen+pants';
      return OutfitSuggestion(
        description: tr(m ? 'outfit_mild_m' : 'outfit_mild_f'),
        imageUrl: _unsplashUrl(q), imageQuery: q,
        seasonalColors: colors, seasonName: season,
      );
    }
    if (cond.contains('rain')) {
      final q = m ? 'shorts,man,sport+sandals,umbrella' : 'summer+dress,woman,sandals';
      return OutfitSuggestion(
        description: tr(m ? 'outfit_hot_rain_m' : 'outfit_hot_rain_f'),
        imageUrl: _unsplashUrl(q), imageQuery: q,
        seasonalColors: colors, seasonName: season,
      );
    }
    final q = m ? 'linen+shirt,man,shorts,sunglasses' : 'sundress,woman,espadrilles,hat';
    return OutfitSuggestion(
      description: tr(m ? 'outfit_hot_m' : 'outfit_hot_f'),
      imageUrl: _unsplashUrl(q), imageQuery: q,
      seasonalColors: colors, seasonName: season,
    );
  }

  String translateCondition(String condition) {
    final key = condition.toLowerCase().replaceAll(' ', '_');
    return tr(key);
  }

  List<String> get availableCities => _cityWeatherDB.keys.toList();

  /// Gradient colors based on weather + dark/light mode.
  List<Color> get weatherGradient {
    final c = _currentWeather.condition.toLowerCase();
    if (_isDarkMode) {
      if (c.contains('snow')) return const [Color(0xFF3A3D5C), Color(0xFF6B7394), Color(0xFF8E9EAB)];
      if (c.contains('rain')) return const [Color(0xFF0D1117), Color(0xFF1A2332), Color(0xFF2D3748)];
      if (c.contains('cloud')) return const [Color(0xFF1A1F2E), Color(0xFF2C3E50), Color(0xFF4A5568)];
      return const [Color(0xFF0F1923), Color(0xFF1B3A5C), Color(0xFF2980B9)];
    } else {
      if (c.contains('snow')) return const [Color(0xFFBDC3C7), Color(0xFFD5DDE8), Color(0xFFECF0F1)];
      if (c.contains('rain')) return const [Color(0xFF636E72), Color(0xFF95A5A6), Color(0xFFBDC3C7)];
      if (c.contains('cloud')) return const [Color(0xFF74B9FF), Color(0xFFA8D8EA), Color(0xFFD6EAF8)];
      return const [Color(0xFF2E86DE), Color(0xFF54A0FF), Color(0xFF8CC0FF)];
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // STATIC DATA
  // ═══════════════════════════════════════════════════════════════════

  static final Map<String, Map<String, List<String>>> _countryData = {
    'Jordan': {
      'Amman': ['Abdali', 'Jabal Amman', 'Swefieh', 'Dabouq', 'Khalda'],
      'Irbid': ['Downtown', 'Al-Husn', 'Beit Ras'],
      'Aqaba': ['City Center', 'South Beach', 'Tala Bay'],
      'Zarqa': ['City Center', 'Russeifa', 'Hashemiya'],
    },
    'Turkey': {
      'Istanbul': ['Kadıköy', 'Beşiktaş', 'Üsküdar', 'Fatih', 'Şişli', 'Bakırköy'],
      'Ankara': ['Çankaya', 'Keçiören', 'Mamak', 'Etimesgut'],
      'Izmir': ['Konak', 'Bornova', 'Karşıyaka', 'Alsancak'],
      'Antalya': ['Muratpaşa', 'Konyaaltı', 'Kepez'],
      'Bursa': ['Osmangazi', 'Nilüfer', 'Yıldırım'],
    },
    'UK': {
      'London': ['Westminster', 'Camden', 'Greenwich', 'Kensington'],
      'Manchester': ['City Centre', 'Salford', 'Didsbury'],
      'Birmingham': ['City Centre', 'Edgbaston', 'Moseley'],
    },
    'Japan': {
      'Tokyo': ['Shibuya', 'Shinjuku', 'Akihabara', 'Ginza'],
      'Osaka': ['Namba', 'Umeda', 'Tennoji'],
      'Kyoto': ['Gion', 'Arashiyama', 'Fushimi'],
    },
    'UAE': {
      'Dubai': ['Downtown', 'Marina', 'Deira', 'Jumeirah'],
      'Abu Dhabi': ['Corniche', 'Yas Island', 'Saadiyat'],
    },
    'USA': {
      'New York': ['Manhattan', 'Brooklyn', 'Queens', 'Bronx'],
      'Los Angeles': ['Hollywood', 'Santa Monica', 'Beverly Hills'],
      'Chicago': ['Loop', 'Lincoln Park', 'Wicker Park'],
    },
    'France': {
      'Paris': ['Montmartre', 'Le Marais', 'Champs-Élysées', 'Latin Quarter'],
      'Lyon': ['Vieux Lyon', "Presqu'île", 'Part-Dieu'],
      'Marseille': ['Vieux-Port', 'Panier', 'Prado'],
    },
    'Russia': {
      'Moscow': ['Red Square', 'Arbat', 'Tverskaya'],
      'St. Petersburg': ['Nevsky', 'Petrogradsky', 'Vasilievsky'],
    },
    'Australia': {
      'Sydney': ['CBD', 'Bondi', 'Manly', 'Surry Hills'],
      'Melbourne': ['CBD', 'St Kilda', 'Fitzroy'],
    },
  };

  static final Map<String, WeatherData> _cityWeatherDB = {
    'Amman': WeatherData(cityName: 'Amman', country: 'Jordan', temperature: 22, humidity: 45, windSpeed: 12, condition: 'Sunny', icon: '☀️'),
    'Irbid': WeatherData(cityName: 'Irbid', country: 'Jordan', temperature: 20, humidity: 50, windSpeed: 10, condition: 'Partly Cloudy', icon: '⛅'),
    'Aqaba': WeatherData(cityName: 'Aqaba', country: 'Jordan', temperature: 30, humidity: 35, windSpeed: 8, condition: 'Sunny', icon: '☀️'),
    'Zarqa': WeatherData(cityName: 'Zarqa', country: 'Jordan', temperature: 23, humidity: 40, windSpeed: 14, condition: 'Sunny', icon: '☀️'),
    'Istanbul': WeatherData(cityName: 'Istanbul', country: 'Turkey', temperature: 16, humidity: 72, windSpeed: 18, condition: 'Cloudy', icon: '☁️'),
    'Ankara': WeatherData(cityName: 'Ankara', country: 'Turkey', temperature: 14, humidity: 55, windSpeed: 15, condition: 'Partly Cloudy', icon: '⛅'),
    'Izmir': WeatherData(cityName: 'Izmir', country: 'Turkey', temperature: 20, humidity: 60, windSpeed: 12, condition: 'Sunny', icon: '☀️'),
    'Antalya': WeatherData(cityName: 'Antalya', country: 'Turkey', temperature: 24, humidity: 65, windSpeed: 10, condition: 'Sunny', icon: '☀️'),
    'Bursa': WeatherData(cityName: 'Bursa', country: 'Turkey', temperature: 15, humidity: 68, windSpeed: 12, condition: 'Rainy', icon: '🌧️'),
    'London': WeatherData(cityName: 'London', country: 'UK', temperature: 12, humidity: 78, windSpeed: 20, condition: 'Rainy', icon: '🌧️'),
    'Manchester': WeatherData(cityName: 'Manchester', country: 'UK', temperature: 10, humidity: 82, windSpeed: 22, condition: 'Rainy', icon: '🌧️'),
    'Birmingham': WeatherData(cityName: 'Birmingham', country: 'UK', temperature: 11, humidity: 75, windSpeed: 18, condition: 'Cloudy', icon: '☁️'),
    'Tokyo': WeatherData(cityName: 'Tokyo', country: 'Japan', temperature: 18, humidity: 65, windSpeed: 10, condition: 'Cloudy', icon: '☁️'),
    'Osaka': WeatherData(cityName: 'Osaka', country: 'Japan', temperature: 19, humidity: 62, windSpeed: 8, condition: 'Partly Cloudy', icon: '⛅'),
    'Kyoto': WeatherData(cityName: 'Kyoto', country: 'Japan', temperature: 17, humidity: 60, windSpeed: 7, condition: 'Sunny', icon: '☀️'),
    'Dubai': WeatherData(cityName: 'Dubai', country: 'UAE', temperature: 38, humidity: 30, windSpeed: 8, condition: 'Sunny', icon: '☀️'),
    'Abu Dhabi': WeatherData(cityName: 'Abu Dhabi', country: 'UAE', temperature: 37, humidity: 32, windSpeed: 10, condition: 'Sunny', icon: '☀️'),
    'New York': WeatherData(cityName: 'New York', country: 'USA', temperature: 15, humidity: 60, windSpeed: 18, condition: 'Partly Cloudy', icon: '⛅'),
    'Los Angeles': WeatherData(cityName: 'Los Angeles', country: 'USA', temperature: 25, humidity: 40, windSpeed: 12, condition: 'Sunny', icon: '☀️'),
    'Chicago': WeatherData(cityName: 'Chicago', country: 'USA', temperature: 10, humidity: 65, windSpeed: 25, condition: 'Cloudy', icon: '☁️'),
    'Paris': WeatherData(cityName: 'Paris', country: 'France', temperature: 14, humidity: 70, windSpeed: 15, condition: 'Rainy', icon: '🌧️'),
    'Lyon': WeatherData(cityName: 'Lyon', country: 'France', temperature: 16, humidity: 65, windSpeed: 12, condition: 'Cloudy', icon: '☁️'),
    'Marseille': WeatherData(cityName: 'Marseille', country: 'France', temperature: 19, humidity: 55, windSpeed: 14, condition: 'Sunny', icon: '☀️'),
    'Moscow': WeatherData(cityName: 'Moscow', country: 'Russia', temperature: -5, humidity: 85, windSpeed: 25, condition: 'Snowy', icon: '❄️'),
    'St. Petersburg': WeatherData(cityName: 'St. Petersburg', country: 'Russia', temperature: -2, humidity: 80, windSpeed: 20, condition: 'Snowy', icon: '❄️'),
    'Sydney': WeatherData(cityName: 'Sydney', country: 'Australia', temperature: 26, humidity: 55, windSpeed: 14, condition: 'Sunny', icon: '☀️'),
    'Melbourne': WeatherData(cityName: 'Melbourne', country: 'Australia', temperature: 20, humidity: 60, windSpeed: 16, condition: 'Partly Cloudy', icon: '⛅'),
  };

  static final Map<String, Map<String, String>> _countryTranslations = {
    'tr': {'Jordan': 'Ürdün', 'Turkey': 'Türkiye', 'UK': 'Birleşik Krallık', 'Japan': 'Japonya', 'UAE': 'BAE', 'USA': 'ABD', 'France': 'Fransa', 'Russia': 'Rusya', 'Australia': 'Avustralya'},
    'ar': {'Jordan': 'الأردن', 'Turkey': 'تركيا', 'UK': 'المملكة المتحدة', 'Japan': 'اليابان', 'UAE': 'الإمارات', 'USA': 'الولايات المتحدة', 'France': 'فرنسا', 'Russia': 'روسيا', 'Australia': 'أستراليا'},
    'ru': {'Jordan': 'Иордания', 'Turkey': 'Турция', 'UK': 'Великобритания', 'Japan': 'Япония', 'UAE': 'ОАЭ', 'USA': 'США', 'France': 'Франция', 'Russia': 'Россия', 'Australia': 'Австралия'},
    'es': {'Jordan': 'Jordania', 'Turkey': 'Turquía', 'UK': 'Reino Unido', 'Japan': 'Japón', 'UAE': 'EAU', 'USA': 'EE.UU.', 'France': 'Francia', 'Russia': 'Rusia', 'Australia': 'Australia'},
    'it': {'Jordan': 'Giordania', 'Turkey': 'Turchia', 'UK': 'Regno Unito', 'Japan': 'Giappone', 'UAE': 'EAU', 'USA': 'USA', 'France': 'Francia', 'Russia': 'Russia', 'Australia': 'Australia'},
  };

  // ─── UI Translations (6 languages) ─────────────────────────────────

  static final Map<String, Map<String, String>> _translations = {
    'en': {
      'home': 'Home', 'forecast': 'Forecast', 'favourites': 'Favourites', 'settings': 'Settings',
      'seven_day_forecast': '7-Day Forecast', 'five_day_forecast': '7-Day Forecast',
      'hourly_forecast': 'Hourly Forecast',
      'search_city': 'Search city...', 'enter_city': 'Please enter a city name.',
      'city_not_found': 'City not found. Try another city name.',
      'humidity': 'Humidity', 'wind': 'Wind', 'outfit_suggestion': 'Outfit Suggestion',
      'country': 'Country', 'city': 'City', 'district': 'District', 'language': 'Language',
      'customize': 'Customize your experience',
      'temp_unit': 'Temperature Unit', 'celsius': 'Celsius (°C)', 'fahrenheit': 'Fahrenheit (°F)',
      'favourite_cities': 'Favourite Cities', 'saved_cities_count': 'saved cities',
      'no_favourites': 'No favourite cities yet.\nTap the heart icon on Home.',
      'currently_viewing': 'Currently viewing', 'tap_to_view': 'Tap to view weather',
      'version': 'Version', 'dark_mode': 'Dark Mode', 'light_mode': 'Light Mode', 'appearance': 'Appearance',
      'male': 'Male', 'female': 'Female', 'gender': 'Style',
      'seasonal_colors': 'Season Colors', 'color_palette': 'Color Palette',
      'winter': 'Winter', 'spring': 'Spring', 'summer': 'Summer', 'autumn': 'Autumn', 'now': 'Now',
      'mon': 'Mon', 'tue': 'Tue', 'wed': 'Wed', 'thu': 'Thu', 'fri': 'Fri', 'sat': 'Sat', 'sun': 'Sun',
      'clr_burgundy': 'Burgundy', 'clr_navy': 'Navy', 'clr_forest': 'Forest', 'clr_charcoal': 'Charcoal', 'clr_ivory': 'Ivory',
      'clr_burnt_orange': 'Burnt Orange', 'clr_mustard': 'Mustard', 'clr_olive': 'Olive', 'clr_saddle_brown': 'Brown',
      'clr_pastel_pink': 'Pastel Pink', 'clr_lavender': 'Lavender', 'clr_mint': 'Mint', 'clr_soft_yellow': 'Soft Yellow', 'clr_sky_blue': 'Sky Blue',
      'clr_coral': 'Coral', 'clr_turquoise': 'Turquoise', 'clr_white': 'White', 'clr_sand': 'Sand', 'clr_gold': 'Gold',
      'outfit_snow_m': 'Heavy winter coat, thermal layers, scarf, gloves, and snow boots.',
      'outfit_snow_f': 'Elegant puffer jacket, cashmere scarf, warm leggings, and fur-lined boots.',
      'outfit_heavy_cold_m': 'Wool overcoat, layered sweater, dark jeans, and leather boots.',
      'outfit_heavy_cold_f': 'Long trench coat, turtleneck sweater, slim pants, and ankle boots.',
      'outfit_cool_rain_m': 'Waterproof parka, hoodie, cargo pants, and rain boots.',
      'outfit_cool_rain_f': 'Trench coat with belt, knit dress, tights, and waterproof Chelsea boots.',
      'outfit_cool_m': 'Bomber jacket, crew-neck sweater, chinos, and sneakers.',
      'outfit_cool_f': 'Cardigan, blouse, midi skirt, and loafers.',
      'outfit_mild_rain_m': 'Light rain jacket, T-shirt, jeans, and waterproof shoes.',
      'outfit_mild_rain_f': 'Lightweight raincoat, floral dress, and rain-resistant flats.',
      'outfit_mild_m': 'Button-up shirt, light chinos, and clean white sneakers.',
      'outfit_mild_f': 'Flowy blouse, linen pants, and strappy sandals.',
      'outfit_hot_rain_m': 'Quick-dry shorts, light T-shirt, and sport sandals with an umbrella.',
      'outfit_hot_rain_f': 'Breezy summer dress, light cardigan, and waterproof sandals.',
      'outfit_hot_m': 'Linen shirt, shorts, sunglasses, and breathable sneakers.',
      'outfit_hot_f': 'Sundress, wide-brim hat, sunglasses, and espadrilles.',
      'sunny': 'Sunny', 'rainy': 'Rainy', 'cloudy': 'Cloudy', 'snowy': 'Snowy', 'partly_cloudy': 'Partly Cloudy',
    },
    'tr': {
      'home': 'Ana Sayfa', 'forecast': 'Tahmin', 'favourites': 'Favoriler', 'settings': 'Ayarlar',
      'seven_day_forecast': '7 Günlük Tahmin', 'five_day_forecast': '7 Günlük Tahmin',
      'hourly_forecast': 'Saatlik Tahmin',
      'search_city': 'Şehir ara...', 'enter_city': 'Lütfen bir şehir adı girin.',
      'city_not_found': 'Şehir bulunamadı.', 'humidity': 'Nem', 'wind': 'Rüzgar',
      'outfit_suggestion': 'Kıyafet Önerisi', 'country': 'Ülke', 'city': 'Şehir', 'district': 'İlçe', 'language': 'Dil',
      'customize': 'Deneyiminizi özelleştirin',
      'temp_unit': 'Sıcaklık Birimi', 'celsius': 'Santigrat (°C)', 'fahrenheit': 'Fahrenheit (°F)',
      'favourite_cities': 'Favori Şehirler', 'saved_cities_count': 'kayıtlı şehir',
      'no_favourites': 'Henüz favori şehir yok.\nAna ekranda kalp simgesine dokunun.',
      'currently_viewing': 'Şu an görüntüleniyor', 'tap_to_view': 'Hava durumunu görmek için dokunun',
      'version': 'Sürüm', 'dark_mode': 'Karanlık Mod', 'light_mode': 'Aydınlık Mod', 'appearance': 'Görünüm',
      'male': 'Erkek', 'female': 'Kadın', 'gender': 'Stil',
      'seasonal_colors': 'Mevsim Renkleri', 'color_palette': 'Renk Paleti',
      'winter': 'Kış', 'spring': 'İlkbahar', 'summer': 'Yaz', 'autumn': 'Sonbahar', 'now': 'Şimdi',
      'mon': 'Pzt', 'tue': 'Sal', 'wed': 'Çar', 'thu': 'Per', 'fri': 'Cum', 'sat': 'Cmt', 'sun': 'Paz',
      'clr_burgundy': 'Bordo', 'clr_navy': 'Lacivert', 'clr_forest': 'Orman Yeşili', 'clr_charcoal': 'Antrasit', 'clr_ivory': 'Fildişi',
      'clr_burnt_orange': 'Yanık Turuncu', 'clr_mustard': 'Hardal', 'clr_olive': 'Zeytin', 'clr_saddle_brown': 'Kahve',
      'clr_pastel_pink': 'Pastel Pembe', 'clr_lavender': 'Lavanta', 'clr_mint': 'Nane', 'clr_soft_yellow': 'Yumuşak Sarı', 'clr_sky_blue': 'Gök Mavisi',
      'clr_coral': 'Mercan', 'clr_turquoise': 'Turkuaz', 'clr_white': 'Beyaz', 'clr_sand': 'Kum', 'clr_gold': 'Altın',
      'outfit_snow_m': 'Kalın kışlık mont, termal iç giyim, atkı, eldiven ve kar botu.',
      'outfit_snow_f': 'Şık şişme mont, kaşmir atkı, sıcak tayt ve kürklü bot.',
      'outfit_heavy_cold_m': 'Yünlü palto, katmanlı kazak, koyu kot ve deri bot.',
      'outfit_heavy_cold_f': 'Uzun trençkot, balıkçı yaka kazak, slim pantolon ve bilekte bot.',
      'outfit_cool_rain_m': 'Su geçirmez parka, kapüşonlu, kargo pantolon ve yağmur botu.',
      'outfit_cool_rain_f': 'Kemerli trençkot, örgü elbise, tayt ve su geçirmez Chelsea bot.',
      'outfit_cool_m': 'Bomber ceket, bisiklet yaka kazak, chino ve spor ayakkabı.',
      'outfit_cool_f': 'Hırka, bluz, midi etek ve loafer.',
      'outfit_mild_rain_m': 'Hafif yağmurluk, tişört, kot ve su geçirmez ayakkabı.',
      'outfit_mild_rain_f': 'Hafif yağmurluk, çiçekli elbise ve yağmura dayanıklı babet.',
      'outfit_mild_m': 'Düğmeli gömlek, hafif chino ve beyaz spor ayakkabı.',
      'outfit_mild_f': 'Akışkan bluz, keten pantolon ve bantlı sandalet.',
      'outfit_hot_rain_m': 'Çabuk kuruyan şort, hafif tişört ve şemsiyeyle spor sandalet.',
      'outfit_hot_rain_f': 'Yazlık elbise, hafif hırka ve su geçirmez sandalet.',
      'outfit_hot_m': 'Keten gömlek, şort, güneş gözlüğü ve nefes alan spor ayakkabı.',
      'outfit_hot_f': 'Yazlık elbise, geniş kenarlı şapka, güneş gözlüğü ve espadril.',
      'sunny': 'Güneşli', 'rainy': 'Yağmurlu', 'cloudy': 'Bulutlu', 'snowy': 'Karlı', 'partly_cloudy': 'Parçalı Bulutlu',
    },
    'ar': {
      'home': 'الرئيسية', 'forecast': 'التوقعات', 'favourites': 'المفضلة', 'settings': 'الإعدادات',
      'seven_day_forecast': 'توقعات 7 أيام', 'five_day_forecast': 'توقعات 7 أيام',
      'hourly_forecast': 'التوقعات بالساعة',
      'search_city': 'ابحث عن مدينة...', 'enter_city': 'الرجاء إدخال اسم المدينة.',
      'city_not_found': 'المدينة غير موجودة.', 'humidity': 'الرطوبة', 'wind': 'الرياح',
      'outfit_suggestion': 'اقتراح الملابس', 'country': 'الدولة', 'city': 'المدينة', 'district': 'المنطقة', 'language': 'اللغة',
      'customize': 'خصص تجربتك',
      'temp_unit': 'وحدة الحرارة', 'celsius': 'مئوية (°C)', 'fahrenheit': 'فهرنهايت (°F)',
      'favourite_cities': 'المدن المفضلة', 'saved_cities_count': 'مدن محفوظة',
      'no_favourites': 'لا توجد مدن مفضلة بعد.\nانقر على أيقونة القلب في الصفحة الرئيسية.',
      'currently_viewing': 'يتم العرض حالياً', 'tap_to_view': 'انقر لعرض الطقس',
      'version': 'الإصدار', 'dark_mode': 'الوضع الداكن', 'light_mode': 'الوضع الفاتح', 'appearance': 'المظهر',
      'male': 'رجال', 'female': 'نساء', 'gender': 'الأسلوب',
      'seasonal_colors': 'ألوان الموسم', 'color_palette': 'لوحة الألوان',
      'winter': 'شتاء', 'spring': 'ربيع', 'summer': 'صيف', 'autumn': 'خريف', 'now': 'الآن',
      'mon': 'الإثنين', 'tue': 'الثلاثاء', 'wed': 'الأربعاء', 'thu': 'الخميس', 'fri': 'الجمعة', 'sat': 'السبت', 'sun': 'الأحد',
      'clr_burgundy': 'عنابي', 'clr_navy': 'كحلي', 'clr_forest': 'أخضر غابي', 'clr_charcoal': 'فحمي', 'clr_ivory': 'عاجي',
      'clr_burnt_orange': 'برتقالي محروق', 'clr_mustard': 'خردلي', 'clr_olive': 'زيتوني', 'clr_saddle_brown': 'بني',
      'clr_pastel_pink': 'وردي فاتح', 'clr_lavender': 'لافندر', 'clr_mint': 'نعناعي', 'clr_soft_yellow': 'أصفر ناعم', 'clr_sky_blue': 'أزرق سماوي',
      'clr_coral': 'مرجاني', 'clr_turquoise': 'فيروزي', 'clr_white': 'أبيض', 'clr_sand': 'رملي', 'clr_gold': 'ذهبي',
      'outfit_snow_m': 'معطف شتوي ثقيل وطبقات حرارية ووشاح وقفازات وأحذية ثلج.',
      'outfit_snow_f': 'جاكيت منفوخ أنيق ووشاح كشمير وبنطلون دافئ وحذاء مبطن بالفرو.',
      'outfit_heavy_cold_m': 'معطف صوف وكنزة طبقات وجينز داكن وحذاء جلد.',
      'outfit_heavy_cold_f': 'ترنش كوت طويل وكنزة بياقة عالية وبنطلون ضيق وبوت كاحل.',
      'outfit_cool_rain_m': 'باركا مقاومة للماء وهودي وبنطلون كارجو وحذاء مطر.',
      'outfit_cool_rain_f': 'ترنش كوت بحزام وفستان محبوك وجوارب وبوت تشيلسي مقاوم للماء.',
      'outfit_cool_m': 'جاكيت بومبر وكنزة وتشينو وحذاء رياضي.',
      'outfit_cool_f': 'كارديجان وبلوزة وتنورة ميدي ولوفر.',
      'outfit_mild_rain_m': 'جاكيت مطر خفيف وتيشيرت وجينز وحذاء مقاوم للماء.',
      'outfit_mild_rain_f': 'معطف مطر خفيف وفستان بأزهار وحذاء مسطح مقاوم للمطر.',
      'outfit_mild_m': 'قميص بأزرار وتشينو خفيف وحذاء رياضي أبيض.',
      'outfit_mild_f': 'بلوزة انسيابية وبنطلون كتان وصندل بأشرطة.',
      'outfit_hot_rain_m': 'شورت سريع الجفاف وتيشيرت خفيف وصندل رياضي مع مظلة.',
      'outfit_hot_rain_f': 'فستان صيفي خفيف وكارديجان وصندل مقاوم للماء.',
      'outfit_hot_m': 'قميص كتان وشورت ونظارات شمسية وحذاء خفيف.',
      'outfit_hot_f': 'فستان شمسي وقبعة واسعة ونظارات شمسية وإسبادريل.',
      'sunny': 'مشمس', 'rainy': 'ممطر', 'cloudy': 'غائم', 'snowy': 'مثلج', 'partly_cloudy': 'غائم جزئياً',
    },
    'ru': {
      'home': 'Главная', 'forecast': 'Прогноз', 'favourites': 'Избранное', 'settings': 'Настройки',
      'seven_day_forecast': 'Прогноз на 7 дней', 'five_day_forecast': 'Прогноз на 7 дней',
      'hourly_forecast': 'Почасовой прогноз',
      'search_city': 'Поиск города...', 'enter_city': 'Введите название города.',
      'city_not_found': 'Город не найден.', 'humidity': 'Влажность', 'wind': 'Ветер',
      'outfit_suggestion': 'Рекомендация одежды', 'country': 'Страна', 'city': 'Город', 'district': 'Район', 'language': 'Язык',
      'customize': 'Настройте свой опыт',
      'temp_unit': 'Единица температуры', 'celsius': 'Цельсий (°C)', 'fahrenheit': 'Фаренгейт (°F)',
      'favourite_cities': 'Избранные города', 'saved_cities_count': 'сохранённых городов',
      'no_favourites': 'Нет избранных городов.\nНажмите на иконку сердца на главной.',
      'currently_viewing': 'Просмотр', 'tap_to_view': 'Нажмите для просмотра',
      'version': 'Версия', 'dark_mode': 'Тёмный режим', 'light_mode': 'Светлый режим', 'appearance': 'Оформление',
      'male': 'Мужской', 'female': 'Женский', 'gender': 'Стиль',
      'seasonal_colors': 'Цвета сезона', 'color_palette': 'Палитра',
      'winter': 'Зима', 'spring': 'Весна', 'summer': 'Лето', 'autumn': 'Осень', 'now': 'Сейчас',
      'mon': 'Пн', 'tue': 'Вт', 'wed': 'Ср', 'thu': 'Чт', 'fri': 'Пт', 'sat': 'Сб', 'sun': 'Вс',
      'clr_burgundy': 'Бордовый', 'clr_navy': 'Тёмно-синий', 'clr_forest': 'Лесной', 'clr_charcoal': 'Угольный', 'clr_ivory': 'Слоновая кость',
      'clr_burnt_orange': 'Жжёный оранж', 'clr_mustard': 'Горчичный', 'clr_olive': 'Оливковый', 'clr_saddle_brown': 'Коричневый',
      'clr_pastel_pink': 'Пастельный розовый', 'clr_lavender': 'Лавандовый', 'clr_mint': 'Мятный', 'clr_soft_yellow': 'Нежно-жёлтый', 'clr_sky_blue': 'Небесно-голубой',
      'clr_coral': 'Коралловый', 'clr_turquoise': 'Бирюзовый', 'clr_white': 'Белый', 'clr_sand': 'Песочный', 'clr_gold': 'Золотой',
      'outfit_snow_m': 'Тёплое зимнее пальто, термобельё, шарф, перчатки и зимние ботинки.',
      'outfit_snow_f': 'Элегантный пуховик, кашемировый шарф, утеплённые леггинсы и ботинки с мехом.',
      'outfit_heavy_cold_m': 'Шерстяное пальто, свитер, тёмные джинсы и кожаные ботинки.',
      'outfit_heavy_cold_f': 'Длинный тренч, свитер с высоким воротом, узкие брюки и ботильоны.',
      'outfit_cool_rain_m': 'Водонепроницаемая парка, худи, карго и резиновые ботинки.',
      'outfit_cool_rain_f': 'Тренч с поясом, вязаное платье, колготки и ботинки Челси.',
      'outfit_cool_m': 'Бомбер, свитер, чиносы и кроссовки.',
      'outfit_cool_f': 'Кардиган, блузка, миди-юбка и лоферы.',
      'outfit_mild_rain_m': 'Лёгкая куртка-дождевик, футболка, джинсы и непромокаемая обувь.',
      'outfit_mild_rain_f': 'Лёгкий дождевик, платье с цветами и непромокаемые балетки.',
      'outfit_mild_m': 'Рубашка на пуговицах, лёгкие чиносы и белые кроссовки.',
      'outfit_mild_f': 'Лёгкая блузка, льняные брюки и босоножки.',
      'outfit_hot_rain_m': 'Быстросохнущие шорты, лёгкая футболка и сандалии с зонтом.',
      'outfit_hot_rain_f': 'Лёгкое летнее платье, кардиган и водонепроницаемые сандалии.',
      'outfit_hot_m': 'Льняная рубашка, шорты, очки и лёгкие кроссовки.',
      'outfit_hot_f': 'Сарафан, широкополая шляпа, очки и эспадрильи.',
      'sunny': 'Солнечно', 'rainy': 'Дождливо', 'cloudy': 'Облачно', 'snowy': 'Снежно', 'partly_cloudy': 'Переменная облачность',
    },
    'es': {
      'home': 'Inicio', 'forecast': 'Pronóstico', 'favourites': 'Favoritos', 'settings': 'Ajustes',
      'seven_day_forecast': 'Pronóstico 7 días', 'five_day_forecast': 'Pronóstico 7 días',
      'hourly_forecast': 'Pronóstico por hora',
      'search_city': 'Buscar ciudad...', 'enter_city': 'Introduce el nombre.',
      'city_not_found': 'Ciudad no encontrada.', 'humidity': 'Humedad', 'wind': 'Viento',
      'outfit_suggestion': 'Sugerencia de outfit', 'country': 'País', 'city': 'Ciudad', 'district': 'Distrito', 'language': 'Idioma',
      'customize': 'Personaliza tu experiencia',
      'temp_unit': 'Unidad de temperatura', 'celsius': 'Celsius (°C)', 'fahrenheit': 'Fahrenheit (°F)',
      'favourite_cities': 'Ciudades favoritas', 'saved_cities_count': 'ciudades guardadas',
      'no_favourites': 'Sin ciudades favoritas.\nToca el corazón en la pantalla principal.',
      'currently_viewing': 'Vista actual', 'tap_to_view': 'Toca para ver',
      'version': 'Versión', 'dark_mode': 'Modo oscuro', 'light_mode': 'Modo claro', 'appearance': 'Apariencia',
      'male': 'Hombre', 'female': 'Mujer', 'gender': 'Estilo',
      'seasonal_colors': 'Colores de temporada', 'color_palette': 'Paleta',
      'winter': 'Invierno', 'spring': 'Primavera', 'summer': 'Verano', 'autumn': 'Otoño', 'now': 'Ahora',
      'mon': 'Lun', 'tue': 'Mar', 'wed': 'Mié', 'thu': 'Jue', 'fri': 'Vie', 'sat': 'Sáb', 'sun': 'Dom',
      'clr_burgundy': 'Burdeos', 'clr_navy': 'Marino', 'clr_forest': 'Bosque', 'clr_charcoal': 'Carbón', 'clr_ivory': 'Marfil',
      'clr_burnt_orange': 'Naranja quemado', 'clr_mustard': 'Mostaza', 'clr_olive': 'Oliva', 'clr_saddle_brown': 'Marrón',
      'clr_pastel_pink': 'Rosa pastel', 'clr_lavender': 'Lavanda', 'clr_mint': 'Menta', 'clr_soft_yellow': 'Amarillo suave', 'clr_sky_blue': 'Azul cielo',
      'clr_coral': 'Coral', 'clr_turquoise': 'Turquesa', 'clr_white': 'Blanco', 'clr_sand': 'Arena', 'clr_gold': 'Dorado',
      'outfit_snow_m': 'Abrigo pesado, capas térmicas, bufanda, guantes y botas de nieve.',
      'outfit_snow_f': 'Chaqueta acolchada, bufanda de cachemira, leggings cálidos y botas forradas.',
      'outfit_heavy_cold_m': 'Abrigo de lana, suéter en capas, jeans oscuros y botas de cuero.',
      'outfit_heavy_cold_f': 'Trench largo, cuello alto, pantalón slim y botines.',
      'outfit_cool_rain_m': 'Parka impermeable, sudadera, cargo y botas de lluvia.',
      'outfit_cool_rain_f': 'Trench con cinturón, vestido de punto, medias y botas Chelsea.',
      'outfit_cool_m': 'Bomber, suéter, chinos y zapatillas.',
      'outfit_cool_f': 'Cárdigan, blusa, falda midi y mocasines.',
      'outfit_mild_rain_m': 'Chaqueta ligera, camiseta, jeans y zapatos impermeables.',
      'outfit_mild_rain_f': 'Impermeable ligero, vestido floral y zapatos planos.',
      'outfit_mild_m': 'Camisa, chinos ligeros y zapatillas blancas.',
      'outfit_mild_f': 'Blusa fluida, pantalón de lino y sandalias.',
      'outfit_hot_rain_m': 'Bermudas de secado rápido, camiseta y sandalias con paraguas.',
      'outfit_hot_rain_f': 'Vestido veraniego, cárdigan y sandalias impermeables.',
      'outfit_hot_m': 'Camisa de lino, bermudas, gafas de sol y zapatillas.',
      'outfit_hot_f': 'Vestido de verano, sombrero, gafas de sol y alpargatas.',
      'sunny': 'Soleado', 'rainy': 'Lluvioso', 'cloudy': 'Nublado', 'snowy': 'Nevado', 'partly_cloudy': 'Parcialmente nublado',
    },
    'it': {
      'home': 'Home', 'forecast': 'Previsioni', 'favourites': 'Preferiti', 'settings': 'Impostazioni',
      'seven_day_forecast': 'Previsioni 7 giorni', 'five_day_forecast': 'Previsioni 7 giorni',
      'hourly_forecast': 'Previsioni orarie',
      'search_city': 'Cerca città...', 'enter_city': 'Inserisci il nome della città.',
      'city_not_found': 'Città non trovata.', 'humidity': 'Umidità', 'wind': 'Vento',
      'outfit_suggestion': 'Suggerimento outfit', 'country': 'Paese', 'city': 'Città', 'district': 'Distretto', 'language': 'Lingua',
      'customize': 'Personalizza la tua esperienza',
      'temp_unit': 'Unità di temperatura', 'celsius': 'Celsius (°C)', 'fahrenheit': 'Fahrenheit (°F)',
      'favourite_cities': 'Città preferite', 'saved_cities_count': 'città salvate',
      'no_favourites': 'Nessuna città preferita.\nTocca il cuore nella schermata principale.',
      'currently_viewing': 'Visualizzazione attuale', 'tap_to_view': 'Tocca per vedere',
      'version': 'Versione', 'dark_mode': 'Modalità scura', 'light_mode': 'Modalità chiara', 'appearance': 'Aspetto',
      'male': 'Uomo', 'female': 'Donna', 'gender': 'Stile',
      'seasonal_colors': 'Colori stagionali', 'color_palette': 'Palette',
      'winter': 'Inverno', 'spring': 'Primavera', 'summer': 'Estate', 'autumn': 'Autunno', 'now': 'Ora',
      'mon': 'Lun', 'tue': 'Mar', 'wed': 'Mer', 'thu': 'Gio', 'fri': 'Ven', 'sat': 'Sab', 'sun': 'Dom',
      'clr_burgundy': 'Borgogna', 'clr_navy': 'Blu navy', 'clr_forest': 'Verde foresta', 'clr_charcoal': 'Carbone', 'clr_ivory': 'Avorio',
      'clr_burnt_orange': 'Arancione bruciato', 'clr_mustard': 'Senape', 'clr_olive': 'Oliva', 'clr_saddle_brown': 'Marrone',
      'clr_pastel_pink': 'Rosa pastello', 'clr_lavender': 'Lavanda', 'clr_mint': 'Menta', 'clr_soft_yellow': 'Giallo tenue', 'clr_sky_blue': 'Azzurro cielo',
      'clr_coral': 'Corallo', 'clr_turquoise': 'Turchese', 'clr_white': 'Bianco', 'clr_sand': 'Sabbia', 'clr_gold': 'Oro',
      'outfit_snow_m': 'Cappotto invernale pesante, strati termici, sciarpa, guanti e stivali da neve.',
      'outfit_snow_f': 'Piumino elegante, sciarpa in cashmere, leggings caldi e stivali foderati.',
      'outfit_heavy_cold_m': 'Cappotto in lana, maglione a strati, jeans scuri e stivali in pelle.',
      'outfit_heavy_cold_f': 'Trench lungo, dolcevita, pantaloni slim e stivaletti.',
      'outfit_cool_rain_m': 'Parka impermeabile, felpa, cargo e stivali da pioggia.',
      'outfit_cool_rain_f': 'Trench con cintura, abito in maglia, collant e stivali Chelsea.',
      'outfit_cool_m': 'Bomber, maglione girocollo, chinos e sneakers.',
      'outfit_cool_f': 'Cardigan, camicetta, gonna midi e mocassini.',
      'outfit_mild_rain_m': 'Giacca antipioggia leggera, maglietta, jeans e scarpe impermeabili.',
      'outfit_mild_rain_f': 'Impermeabile leggero, vestito a fiori e ballerine resistenti.',
      'outfit_mild_m': 'Camicia con bottoni, chinos leggeri e sneakers bianche.',
      'outfit_mild_f': 'Camicetta fluida, pantaloni in lino e sandali.',
      'outfit_hot_rain_m': 'Bermuda ad asciugatura rapida, maglietta e sandali con ombrello.',
      'outfit_hot_rain_f': 'Vestito estivo leggero, cardigan e sandali impermeabili.',
      'outfit_hot_m': 'Camicia in lino, bermuda, occhiali da sole e sneakers.',
      'outfit_hot_f': 'Abito estivo, cappello a tesa larga, occhiali da sole ed espadrillas.',
      'sunny': 'Soleggiato', 'rainy': 'Piovoso', 'cloudy': 'Nuvoloso', 'snowy': 'Nevoso', 'partly_cloudy': 'Parzialmente nuvoloso',
    },
  };

  // ─── 7-Day Forecast Generator ──────────────────────────────────────

  static List<ForecastDay> _generateForecast(WeatherData base) {
    final days = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];
    final conditions = ['Sunny', 'Cloudy', 'Rainy', 'Partly Cloudy', 'Sunny', 'Cloudy', 'Sunny'];
    final icons = ['☀️', '☁️', '🌧️', '⛅', '☀️', '☁️', '☀️'];
    return List.generate(7, (i) {
      final v = (i - 3) * 1.8;
      return ForecastDay(
        day: days[i], highTemp: base.temperature + v + 3,
        lowTemp: base.temperature + v - 4, condition: conditions[i], icon: icons[i],
      );
    });
  }

  // ─── Hourly Forecast Generator ─────────────────────────────────────

  static List<HourlyForecast> _generateHourly(WeatherData base) {
    final icons = ['☀️', '⛅', '☁️', '🌧️', '⛅', '☀️'];
    final conds = ['Sunny', 'Partly Cloudy', 'Cloudy', 'Rainy', 'Partly Cloudy', 'Sunny'];
    return List.generate(24, (i) {
      final hour = (8 + i) % 24;
      final timeStr = i == 0
          ? 'now'
          : (hour < 12
              ? '${hour == 0 ? 12 : hour}AM'
              : '${hour == 12 ? 12 : hour - 12}PM');
      final tempVar = (i < 6 ? i * 0.8 : (12 - i) * 0.6);
      return HourlyForecast(
        time: timeStr,
        temperature: base.temperature + tempVar,
        icon: icons[i % icons.length],
        condition: conds[i % conds.length],
      );
    });
  }
}
