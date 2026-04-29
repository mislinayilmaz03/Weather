import 'package:flutter/material.dart';
import '../models/weather_model.dart';

/// WeatherProvider manages global app state: weather data, forecasts,
/// favourites, settings, localization, gender, dark mode, and outfits.
class WeatherProvider extends ChangeNotifier {
  // ─── Current Weather ───────────────────────────────────────────────

  WeatherData _currentWeather = _cityWeatherDB['Amman']!;
  WeatherData get currentWeather => _currentWeather;

  // ─── Weather Scenario Switcher ──────────────────────────────────────

  String? _activeScenarioKey;
  String? get activeScenarioKey => _activeScenarioKey;

  List<WeatherScenario> get scenarios => weatherScenarios;

  void setScenario(String? key) {
    _activeScenarioKey = key;
    if (key != null) {
      final s = weatherScenarios.firstWhere((sc) => sc.key == key);
      _currentWeather = WeatherData(
        cityName: _currentWeather.cityName,
        country: _currentWeather.country,
        region: _currentWeather.region,
        temperature: s.temp,
        humidity: s.humidity,
        windSpeed: s.windSpeed,
        condition: s.condition,
        icon: s.icon,
      );
      _forecast = _generateForecast(_currentWeather);
      _hourlyForecast = _generateHourly(_currentWeather);
    } else {
      _updateWeatherForSelection();
    }
    notifyListeners();
  }

  /// Mesh gradient colors for the current weather scenario.
  List<Color> get meshGradientColors {
    if (_activeScenarioKey != null) {
      final s = weatherScenarios.firstWhere((sc) => sc.key == _activeScenarioKey);
      return s.meshColors.map((c) => Color(c)).toList();
    }
    final cond = _currentWeather.condition.toLowerCase();
    if (cond.contains('fog')) return const [Color(0xFF9E9E9E), Color(0xFFBDBDBD), Color(0xFFE0E0E0), Color(0xFFCFD8DC)];
    if (cond.contains('storm')) return const [Color(0xFF1A1A2E), Color(0xFF16213E), Color(0xFF0F3460), Color(0xFF533483)];
    if (cond.contains('humid')) return const [Color(0xFF2E7D32), Color(0xFF66BB6A), Color(0xFF81C784), Color(0xFFA5D6A7)];
    if (cond.contains('frost')) return const [Color(0xFFB3E5FC), Color(0xFF81D4FA), Color(0xFFE1F5FE), Color(0xFFCCE5FF)];
    if (cond.contains('spring evening')) return const [Color(0xFFFF8A65), Color(0xFFFFAB91), Color(0xFFCE93D8), Color(0xFF90CAF9)];
    if (cond.contains('snow')) return const [Color(0xFF90A4AE), Color(0xFFB0BEC5), Color(0xFFCFD8DC), Color(0xFFECEFF1)];
    if (cond.contains('rain')) return const [Color(0xFF37474F), Color(0xFF455A64), Color(0xFF546E7A), Color(0xFF607D8B)];
    if (cond.contains('cloud')) return const [Color(0xFF5C6BC0), Color(0xFF7986CB), Color(0xFF9FA8DA), Color(0xFFC5CAE9)];
    return const [Color(0xFF42A5F5), Color(0xFF64B5F6), Color(0xFFFFB74D), Color(0xFFFFF176)];
  }

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
    {'code': 'de', 'name': 'Deutsch', 'flag': '🇩🇪'},
    {'code': 'pt', 'name': 'Português', 'flag': '🇧🇷'},
    {'code': 'ja', 'name': '日本語', 'flag': '🇯🇵'},
    {'code': 'zh', 'name': '中文', 'flag': '🇨🇳'},
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

  /// Local asset path for outfit images.
  String _outfitAsset(String key) => 'assets/outfits/$key.jpg';

  OutfitSuggestion getOutfitSuggestion() {
    final temp = _currentWeather.temperature;
    final cond = _currentWeather.condition.toLowerCase();
    final m = _selectedGender == 'male';
    final colors = seasonalColors;
    final season = currentSeason;

    // ── If a scenario is active, use its outfit items directly ──
    if (_activeScenarioKey != null) {
      final sc = weatherScenarios.firstWhere((s) => s.key == _activeScenarioKey);
      final items = m ? sc.menOutfit : sc.womenOutfit;
      final descKey = '${sc.key}_${m ? 'm' : 'f'}';
      return OutfitSuggestion(
        description: tr(descKey),
        imageUrl: _outfitAsset(descKey),
        seasonalColors: colors, seasonName: season,
        items: items,
      );
    }

    // ── New conditions: Foggy, Stormy, Humid, Frosty, Spring Evening ──
    if (cond.contains('fog')) {
      return OutfitSuggestion(
        description: tr(m ? 'outfit_foggy_m' : 'outfit_foggy_f'),
        imageUrl: _outfitAsset(m ? 'foggy_m' : 'foggy_f'),
        seasonalColors: colors, seasonName: season,
        items: m
            ? const [OutfitItem(nameKey: 'item_peacoat', category: OutfitCategory.outerwear), OutfitItem(nameKey: 'item_dark_jeans', category: OutfitCategory.bottom), OutfitItem(nameKey: 'item_leather_boots', category: OutfitCategory.shoes), OutfitItem(nameKey: 'item_beanie', category: OutfitCategory.headwear)]
            : const [OutfitItem(nameKey: 'item_trench', category: OutfitCategory.outerwear), OutfitItem(nameKey: 'item_wool_pants', category: OutfitCategory.bottom), OutfitItem(nameKey: 'item_ankle_boots', category: OutfitCategory.shoes), OutfitItem(nameKey: 'item_scarf', category: OutfitCategory.accessory)],
      );
    }
    if (cond.contains('storm')) {
      return OutfitSuggestion(
        description: tr(m ? 'outfit_stormy_m' : 'outfit_stormy_f'),
        imageUrl: _outfitAsset(m ? 'stormy_m' : 'stormy_f'),
        seasonalColors: colors, seasonName: season,
        items: m
            ? const [OutfitItem(nameKey: 'item_storm_jacket', category: OutfitCategory.outerwear), OutfitItem(nameKey: 'item_cargo_pants', category: OutfitCategory.bottom), OutfitItem(nameKey: 'item_rain_boots', category: OutfitCategory.shoes), OutfitItem(nameKey: 'item_umbrella', category: OutfitCategory.accessory)]
            : const [OutfitItem(nameKey: 'item_rain_parka', category: OutfitCategory.outerwear), OutfitItem(nameKey: 'item_leggings', category: OutfitCategory.bottom), OutfitItem(nameKey: 'item_waterproof_boots', category: OutfitCategory.shoes), OutfitItem(nameKey: 'item_umbrella', category: OutfitCategory.accessory)],
      );
    }
    if (cond.contains('humid')) {
      return OutfitSuggestion(
        description: tr(m ? 'outfit_humid_m' : 'outfit_humid_f'),
        imageUrl: _outfitAsset(m ? 'humid_m' : 'humid_f'),
        seasonalColors: colors, seasonName: season,
        items: m
            ? const [OutfitItem(nameKey: 'item_linen_shirt', category: OutfitCategory.top), OutfitItem(nameKey: 'item_shorts', category: OutfitCategory.bottom), OutfitItem(nameKey: 'item_sandals', category: OutfitCategory.shoes), OutfitItem(nameKey: 'item_sunglasses', category: OutfitCategory.accessory)]
            : const [OutfitItem(nameKey: 'item_cotton_dress', category: OutfitCategory.top), OutfitItem(nameKey: 'item_light_skirt', category: OutfitCategory.bottom), OutfitItem(nameKey: 'item_open_sandals', category: OutfitCategory.shoes), OutfitItem(nameKey: 'item_sun_hat', category: OutfitCategory.headwear)],
      );
    }
    if (cond.contains('frost')) {
      return OutfitSuggestion(
        description: tr(m ? 'outfit_frosty_m' : 'outfit_frosty_f'),
        imageUrl: _outfitAsset(m ? 'frosty_m' : 'frosty_f'),
        seasonalColors: colors, seasonName: season,
        items: m
            ? const [OutfitItem(nameKey: 'item_down_jacket', category: OutfitCategory.outerwear), OutfitItem(nameKey: 'item_thermal_pants', category: OutfitCategory.bottom), OutfitItem(nameKey: 'item_insulated_boots', category: OutfitCategory.shoes), OutfitItem(nameKey: 'item_gloves', category: OutfitCategory.accessory)]
            : const [OutfitItem(nameKey: 'item_puffer_coat', category: OutfitCategory.outerwear), OutfitItem(nameKey: 'item_warm_leggings', category: OutfitCategory.bottom), OutfitItem(nameKey: 'item_fur_boots', category: OutfitCategory.shoes), OutfitItem(nameKey: 'item_cashmere_scarf', category: OutfitCategory.accessory)],
      );
    }
    if (cond.contains('spring evening')) {
      return OutfitSuggestion(
        description: tr(m ? 'outfit_spring_eve_m' : 'outfit_spring_eve_f'),
        imageUrl: _outfitAsset(m ? 'spring_eve_m' : 'spring_eve_f'),
        seasonalColors: colors, seasonName: season,
        items: m
            ? const [OutfitItem(nameKey: 'item_light_jacket', category: OutfitCategory.outerwear), OutfitItem(nameKey: 'item_chinos', category: OutfitCategory.bottom), OutfitItem(nameKey: 'item_loafers', category: OutfitCategory.shoes), OutfitItem(nameKey: 'item_watch', category: OutfitCategory.accessory)]
            : const [OutfitItem(nameKey: 'item_cardigan', category: OutfitCategory.outerwear), OutfitItem(nameKey: 'item_floral_dress', category: OutfitCategory.top), OutfitItem(nameKey: 'item_ballet_flats', category: OutfitCategory.shoes), OutfitItem(nameKey: 'item_clutch', category: OutfitCategory.accessory)],
      );
    }

    // ── Original conditions ──
    if (temp < 5) {
      if (cond.contains('snow')) {
        return OutfitSuggestion(
          description: tr(m ? 'outfit_snow_m' : 'outfit_snow_f'),
          imageUrl: _outfitAsset(m ? 'snow_m' : 'snow_f'),
          seasonalColors: colors, seasonName: season,
          items: m
              ? const [OutfitItem(nameKey: 'item_winter_coat', category: OutfitCategory.outerwear), OutfitItem(nameKey: 'item_thermal_layers', category: OutfitCategory.top), OutfitItem(nameKey: 'item_snow_boots', category: OutfitCategory.shoes), OutfitItem(nameKey: 'item_gloves', category: OutfitCategory.accessory)]
              : const [OutfitItem(nameKey: 'item_puffer_jacket', category: OutfitCategory.outerwear), OutfitItem(nameKey: 'item_warm_leggings', category: OutfitCategory.bottom), OutfitItem(nameKey: 'item_fur_boots', category: OutfitCategory.shoes), OutfitItem(nameKey: 'item_cashmere_scarf', category: OutfitCategory.accessory)],
        );
      }
      return OutfitSuggestion(
        description: tr(m ? 'outfit_heavy_cold_m' : 'outfit_heavy_cold_f'),
        imageUrl: _outfitAsset(m ? 'heavy_cold_m' : 'heavy_cold_f'),
        seasonalColors: colors, seasonName: season,
        items: m
            ? const [OutfitItem(nameKey: 'item_wool_overcoat', category: OutfitCategory.outerwear), OutfitItem(nameKey: 'item_sweater', category: OutfitCategory.top), OutfitItem(nameKey: 'item_leather_boots', category: OutfitCategory.shoes), OutfitItem(nameKey: 'item_scarf', category: OutfitCategory.accessory)]
            : const [OutfitItem(nameKey: 'item_trench', category: OutfitCategory.outerwear), OutfitItem(nameKey: 'item_turtleneck', category: OutfitCategory.top), OutfitItem(nameKey: 'item_ankle_boots', category: OutfitCategory.shoes), OutfitItem(nameKey: 'item_slim_pants', category: OutfitCategory.bottom)],
      );
    }
    if (temp < 15) {
      if (cond.contains('rain')) {
        return OutfitSuggestion(
          description: tr(m ? 'outfit_cool_rain_m' : 'outfit_cool_rain_f'),
          imageUrl: _outfitAsset(m ? 'cool_rain_m' : 'cool_rain_f'),
          seasonalColors: colors, seasonName: season,
          items: m
              ? const [OutfitItem(nameKey: 'item_waterproof_parka', category: OutfitCategory.outerwear), OutfitItem(nameKey: 'item_hoodie', category: OutfitCategory.top), OutfitItem(nameKey: 'item_rain_boots', category: OutfitCategory.shoes), OutfitItem(nameKey: 'item_cargo_pants', category: OutfitCategory.bottom)]
              : const [OutfitItem(nameKey: 'item_trench', category: OutfitCategory.outerwear), OutfitItem(nameKey: 'item_knit_dress', category: OutfitCategory.top), OutfitItem(nameKey: 'item_chelsea_boots', category: OutfitCategory.shoes), OutfitItem(nameKey: 'item_tights', category: OutfitCategory.bottom)],
        );
      }
      return OutfitSuggestion(
        description: tr(m ? 'outfit_cool_m' : 'outfit_cool_f'),
        imageUrl: _outfitAsset(m ? 'cool_m' : 'cool_f'),
        seasonalColors: colors, seasonName: season,
        items: m
            ? const [OutfitItem(nameKey: 'item_bomber', category: OutfitCategory.outerwear), OutfitItem(nameKey: 'item_sweater', category: OutfitCategory.top), OutfitItem(nameKey: 'item_sneakers', category: OutfitCategory.shoes), OutfitItem(nameKey: 'item_chinos', category: OutfitCategory.bottom)]
            : const [OutfitItem(nameKey: 'item_cardigan', category: OutfitCategory.outerwear), OutfitItem(nameKey: 'item_blouse', category: OutfitCategory.top), OutfitItem(nameKey: 'item_loafers', category: OutfitCategory.shoes), OutfitItem(nameKey: 'item_midi_skirt', category: OutfitCategory.bottom)],
      );
    }
    if (temp < 25) {
      if (cond.contains('rain')) {
        return OutfitSuggestion(
          description: tr(m ? 'outfit_mild_rain_m' : 'outfit_mild_rain_f'),
          imageUrl: _outfitAsset(m ? 'mild_rain_m' : 'mild_rain_f'),
          seasonalColors: colors, seasonName: season,
          items: m
              ? const [OutfitItem(nameKey: 'item_rain_jacket', category: OutfitCategory.outerwear), OutfitItem(nameKey: 'item_tshirt', category: OutfitCategory.top), OutfitItem(nameKey: 'item_waterproof_shoes', category: OutfitCategory.shoes), OutfitItem(nameKey: 'item_jeans', category: OutfitCategory.bottom)]
              : const [OutfitItem(nameKey: 'item_raincoat', category: OutfitCategory.outerwear), OutfitItem(nameKey: 'item_floral_dress', category: OutfitCategory.top), OutfitItem(nameKey: 'item_rain_flats', category: OutfitCategory.shoes), OutfitItem(nameKey: 'item_umbrella', category: OutfitCategory.accessory)],
        );
      }
      return OutfitSuggestion(
        description: tr(m ? 'outfit_mild_m' : 'outfit_mild_f'),
        imageUrl: _outfitAsset(m ? 'mild_m' : 'mild_f'),
        seasonalColors: colors, seasonName: season,
        items: m
            ? const [OutfitItem(nameKey: 'item_button_shirt', category: OutfitCategory.top), OutfitItem(nameKey: 'item_chinos', category: OutfitCategory.bottom), OutfitItem(nameKey: 'item_white_sneakers', category: OutfitCategory.shoes)]
            : const [OutfitItem(nameKey: 'item_blouse', category: OutfitCategory.top), OutfitItem(nameKey: 'item_linen_pants', category: OutfitCategory.bottom), OutfitItem(nameKey: 'item_strappy_sandals', category: OutfitCategory.shoes)],
      );
    }
    if (cond.contains('rain')) {
      return OutfitSuggestion(
        description: tr(m ? 'outfit_hot_rain_m' : 'outfit_hot_rain_f'),
        imageUrl: _outfitAsset(m ? 'hot_rain_m' : 'hot_rain_f'),
        seasonalColors: colors, seasonName: season,
        items: m
            ? const [OutfitItem(nameKey: 'item_tshirt', category: OutfitCategory.top), OutfitItem(nameKey: 'item_quick_dry_shorts', category: OutfitCategory.bottom), OutfitItem(nameKey: 'item_sport_sandals', category: OutfitCategory.shoes), OutfitItem(nameKey: 'item_umbrella', category: OutfitCategory.accessory)]
            : const [OutfitItem(nameKey: 'item_summer_dress', category: OutfitCategory.top), OutfitItem(nameKey: 'item_light_cardigan', category: OutfitCategory.outerwear), OutfitItem(nameKey: 'item_waterproof_sandals', category: OutfitCategory.shoes), OutfitItem(nameKey: 'item_umbrella', category: OutfitCategory.accessory)],
      );
    }
    return OutfitSuggestion(
      description: tr(m ? 'outfit_hot_m' : 'outfit_hot_f'),
      imageUrl: _outfitAsset(m ? 'hot_m' : 'hot_f'),
      seasonalColors: colors, seasonName: season,
      items: m
          ? const [OutfitItem(nameKey: 'item_linen_shirt', category: OutfitCategory.top), OutfitItem(nameKey: 'item_shorts', category: OutfitCategory.bottom), OutfitItem(nameKey: 'item_breathable_sneakers', category: OutfitCategory.shoes), OutfitItem(nameKey: 'item_sunglasses', category: OutfitCategory.accessory)]
          : const [OutfitItem(nameKey: 'item_sundress', category: OutfitCategory.top), OutfitItem(nameKey: 'item_espadrilles', category: OutfitCategory.shoes), OutfitItem(nameKey: 'item_sun_hat', category: OutfitCategory.headwear), OutfitItem(nameKey: 'item_sunglasses', category: OutfitCategory.accessory)],
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
      if (c.contains('fog')) return const [Color(0xFF37474F), Color(0xFF546E7A), Color(0xFF78909C)];
      if (c.contains('storm')) return const [Color(0xFF0D0D1A), Color(0xFF1A1A2E), Color(0xFF2D1B4E)];
      if (c.contains('humid')) return const [Color(0xFF1B3A2D), Color(0xFF2E5B3F), Color(0xFF3E7251)];
      if (c.contains('frost')) return const [Color(0xFF1A2A3A), Color(0xFF2C4A6A), Color(0xFF4A7A9A)];
      if (c.contains('spring evening')) return const [Color(0xFF2D1B3E), Color(0xFF4A2D5C), Color(0xFF6B3F7A)];
      if (c.contains('snow')) return const [Color(0xFF3A3D5C), Color(0xFF6B7394), Color(0xFF8E9EAB)];
      if (c.contains('rain')) return const [Color(0xFF0D1117), Color(0xFF1A2332), Color(0xFF2D3748)];
      if (c.contains('cloud')) return const [Color(0xFF1A1F2E), Color(0xFF2C3E50), Color(0xFF4A5568)];
      return const [Color(0xFF0F1923), Color(0xFF1B3A5C), Color(0xFF2980B9)];
    } else {
      if (c.contains('fog')) return const [Color(0xFFB0BEC5), Color(0xFFCFD8DC), Color(0xFFECEFF1)];
      if (c.contains('storm')) return const [Color(0xFF455A64), Color(0xFF607D8B), Color(0xFF90A4AE)];
      if (c.contains('humid')) return const [Color(0xFF66BB6A), Color(0xFF81C784), Color(0xFFA5D6A7)];
      if (c.contains('frost')) return const [Color(0xFF81D4FA), Color(0xFFB3E5FC), Color(0xFFE1F5FE)];
      if (c.contains('spring evening')) return const [Color(0xFFFFAB91), Color(0xFFCE93D8), Color(0xFFB39DDB)];
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
    // ── Jordan ──
    'Amman': WeatherData(cityName: 'Amman', country: 'Jordan', temperature: 22, humidity: 45, windSpeed: 12, condition: 'Sunny', icon: '☀️'),
    'Irbid': WeatherData(cityName: 'Irbid', country: 'Jordan', temperature: 8, humidity: 80, windSpeed: 6, condition: 'Foggy', icon: '🌫️'),
    'Aqaba': WeatherData(cityName: 'Aqaba', country: 'Jordan', temperature: 34, humidity: 75, windSpeed: 5, condition: 'Humid', icon: '💧'),
    'Zarqa': WeatherData(cityName: 'Zarqa', country: 'Jordan', temperature: 23, humidity: 40, windSpeed: 14, condition: 'Sunny', icon: '☀️'),
    // ── Turkey ──
    'Istanbul': WeatherData(cityName: 'Istanbul', country: 'Turkey', temperature: 12, humidity: 72, windSpeed: 22, condition: 'Stormy', icon: '⛈️'),
    'Ankara': WeatherData(cityName: 'Ankara', country: 'Turkey', temperature: -8, humidity: 55, windSpeed: 15, condition: 'Frosty', icon: '🥶'),
    'Izmir': WeatherData(cityName: 'Izmir', country: 'Turkey', temperature: 16, humidity: 60, windSpeed: 8, condition: 'Spring Evening', icon: '🌸'),
    'Antalya': WeatherData(cityName: 'Antalya', country: 'Turkey', temperature: 30, humidity: 65, windSpeed: 10, condition: 'Sunny', icon: '☀️'),
    'Bursa': WeatherData(cityName: 'Bursa', country: 'Turkey', temperature: 15, humidity: 68, windSpeed: 12, condition: 'Rainy', icon: '🌧️'),
    // ── UK ──
    'London': WeatherData(cityName: 'London', country: 'UK', temperature: 8, humidity: 85, windSpeed: 10, condition: 'Foggy', icon: '�️'),
    'Manchester': WeatherData(cityName: 'Manchester', country: 'UK', temperature: 10, humidity: 82, windSpeed: 28, condition: 'Stormy', icon: '⛈️'),
    'Birmingham': WeatherData(cityName: 'Birmingham', country: 'UK', temperature: 11, humidity: 75, windSpeed: 18, condition: 'Rainy', icon: '🌧️'),
    // ── Japan ──
    'Tokyo': WeatherData(cityName: 'Tokyo', country: 'Japan', temperature: 18, humidity: 65, windSpeed: 10, condition: 'Rainy', icon: '🌧️'),
    'Osaka': WeatherData(cityName: 'Osaka', country: 'Japan', temperature: 32, humidity: 85, windSpeed: 5, condition: 'Humid', icon: '💧'),
    'Kyoto': WeatherData(cityName: 'Kyoto', country: 'Japan', temperature: 16, humidity: 60, windSpeed: 7, condition: 'Spring Evening', icon: '🌸'),
    // ── UAE ──
    'Dubai': WeatherData(cityName: 'Dubai', country: 'UAE', temperature: 38, humidity: 80, windSpeed: 8, condition: 'Humid', icon: '💧'),
    'Abu Dhabi': WeatherData(cityName: 'Abu Dhabi', country: 'UAE', temperature: 37, humidity: 32, windSpeed: 10, condition: 'Sunny', icon: '☀️'),
    // ── USA ──
    'New York': WeatherData(cityName: 'New York', country: 'USA', temperature: 4, humidity: 60, windSpeed: 18, condition: 'Snowy', icon: '❄️'),
    'Los Angeles': WeatherData(cityName: 'Los Angeles', country: 'USA', temperature: 28, humidity: 40, windSpeed: 12, condition: 'Sunny', icon: '☀️'),
    'Chicago': WeatherData(cityName: 'Chicago', country: 'USA', temperature: -6, humidity: 65, windSpeed: 30, condition: 'Frosty', icon: '🥶'),
    // ── France ──
    'Paris': WeatherData(cityName: 'Paris', country: 'France', temperature: 16, humidity: 70, windSpeed: 8, condition: 'Spring Evening', icon: '�'),
    'Lyon': WeatherData(cityName: 'Lyon', country: 'France', temperature: 7, humidity: 78, windSpeed: 5, condition: 'Foggy', icon: '🌫️'),
    'Marseille': WeatherData(cityName: 'Marseille', country: 'France', temperature: 26, humidity: 55, windSpeed: 14, condition: 'Sunny', icon: '☀️'),
    // ── Russia ──
    'Moscow': WeatherData(cityName: 'Moscow', country: 'Russia', temperature: -8, humidity: 85, windSpeed: 25, condition: 'Frosty', icon: '🥶'),
    'St. Petersburg': WeatherData(cityName: 'St. Petersburg', country: 'Russia', temperature: -2, humidity: 80, windSpeed: 20, condition: 'Snowy', icon: '❄️'),
    // ── Australia ──
    'Sydney': WeatherData(cityName: 'Sydney', country: 'Australia', temperature: 30, humidity: 55, windSpeed: 14, condition: 'Rainy', icon: '🌧️'),
    'Melbourne': WeatherData(cityName: 'Melbourne', country: 'Australia', temperature: 10, humidity: 60, windSpeed: 16, condition: 'Cloudy', icon: '☁️'),
  };

  static final Map<String, Map<String, String>> _countryTranslations = {
    'tr': {'Jordan': 'Ürdün', 'Turkey': 'Türkiye', 'UK': 'Birleşik Krallık', 'Japan': 'Japonya', 'UAE': 'BAE', 'USA': 'ABD', 'France': 'Fransa', 'Russia': 'Rusya', 'Australia': 'Avustralya'},
    'ar': {'Jordan': 'الأردن', 'Turkey': 'تركيا', 'UK': 'المملكة المتحدة', 'Japan': 'اليابان', 'UAE': 'الإمارات', 'USA': 'الولايات المتحدة', 'France': 'فرنسا', 'Russia': 'روسيا', 'Australia': 'أستراليا'},
    'ru': {'Jordan': 'Иордания', 'Turkey': 'Турция', 'UK': 'Великобритания', 'Japan': 'Япония', 'UAE': 'ОАЭ', 'USA': 'США', 'France': 'Франция', 'Russia': 'Россия', 'Australia': 'Австралия'},
    'es': {'Jordan': 'Jordania', 'Turkey': 'Turquía', 'UK': 'Reino Unido', 'Japan': 'Japón', 'UAE': 'EAU', 'USA': 'EE.UU.', 'France': 'Francia', 'Russia': 'Rusia', 'Australia': 'Australia'},
    'it': {'Jordan': 'Giordania', 'Turkey': 'Turchia', 'UK': 'Regno Unito', 'Japan': 'Giappone', 'UAE': 'EAU', 'USA': 'USA', 'France': 'Francia', 'Russia': 'Russia', 'Australia': 'Australia'},
    'de': {'Jordan': 'Jordanien', 'Turkey': 'Türkei', 'UK': 'Vereinigtes Königreich', 'Japan': 'Japan', 'UAE': 'VAE', 'USA': 'USA', 'France': 'Frankreich', 'Russia': 'Russland', 'Australia': 'Australien'},
    'pt': {'Jordan': 'Jordânia', 'Turkey': 'Turquia', 'UK': 'Reino Unido', 'Japan': 'Japão', 'UAE': 'EAU', 'USA': 'EUA', 'France': 'França', 'Russia': 'Rússia', 'Australia': 'Austrália'},
    'ja': {'Jordan': 'ヨルダン', 'Turkey': 'トルコ', 'UK': 'イギリス', 'Japan': '日本', 'UAE': 'UAE', 'USA': 'アメリカ', 'France': 'フランス', 'Russia': 'ロシア', 'Australia': 'オーストラリア'},
    'zh': {'Jordan': '约旦', 'Turkey': '土耳其', 'UK': '英国', 'Japan': '日本', 'UAE': '阿联酋', 'USA': '美国', 'France': '法国', 'Russia': '俄罗斯', 'Australia': '澳大利亚'},
  };

  // ─── UI Translations (10 languages) ────────────────────────────────

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
      'foggy': 'Foggy', 'stormy': 'Stormy', 'humid': 'Humid', 'frosty': 'Frosty', 'spring_evening': 'Spring Evening',
      // New outfit descriptions
      'outfit_foggy_m': 'Peacoat, dark jeans, leather boots, and a beanie for the misty weather.',
      'outfit_foggy_f': 'Elegant trench coat, wool pants, ankle boots, and a warm scarf.',
      'outfit_stormy_m': 'Heavy-duty storm jacket, cargo pants, rain boots, and an umbrella.',
      'outfit_stormy_f': 'Waterproof parka, warm leggings, high boots, and a sturdy umbrella.',
      'outfit_humid_m': 'Breathable linen shirt, light shorts, open sandals, and sunglasses.',
      'outfit_humid_f': 'Airy cotton dress, light skirt, open sandals, and a sun hat.',
      'outfit_frosty_m': 'Insulated down jacket, thermal pants, heavy-duty boots, and lined gloves.',
      'outfit_frosty_f': 'Luxe puffer coat, warm leggings, fur-lined boots, and cashmere scarf.',
      'outfit_spring_eve_m': 'Light jacket, slim chinos, suede loafers, and a stylish watch.',
      'outfit_spring_eve_f': 'Soft cardigan, floral midi dress, ballet flats, and an evening clutch.',
      // Scenario switcher descriptions (used when scenario is active)
      'foggy_m': 'Peacoat, dark jeans, leather boots, and a beanie for the misty weather.',
      'foggy_f': 'Elegant trench coat, wool pants, ankle boots, and a warm scarf.',
      'stormy_m': 'Heavy-duty storm jacket, cargo pants, rain boots, and an umbrella.',
      'stormy_f': 'Waterproof parka, warm leggings, high boots, and a sturdy umbrella.',
      'humid_m': 'Breathable linen shirt, light shorts, open sandals, and sunglasses.',
      'humid_f': 'Airy cotton dress, light skirt, open sandals, and a sun hat.',
      'frosty_m': 'Insulated down jacket, thermal pants, heavy-duty boots, and lined gloves.',
      'frosty_f': 'Luxe puffer coat, warm leggings, fur-lined boots, and cashmere scarf.',
      'spring_evening_m': 'Light jacket, slim chinos, suede loafers, and a stylish watch.',
      'spring_evening_f': 'Soft cardigan, floral midi dress, ballet flats, and an evening clutch.',
      'sunny_m': 'Linen shirt, shorts, sunglasses, and breathable sneakers.',
      'sunny_f': 'Sundress, wide-brim hat, sunglasses, and espadrilles.',
      'rainy_m': 'Waterproof parka, hoodie, cargo pants, and rain boots.',
      'rainy_f': 'Trench coat with belt, knit dress, tights, and waterproof Chelsea boots.',
      'cloudy_m': 'Bomber jacket, crew-neck sweater, chinos, and sneakers.',
      'cloudy_f': 'Cardigan, blouse, midi skirt, and loafers.',
      'snowy_m': 'Heavy winter coat, thermal layers, scarf, gloves, and snow boots.',
      'snowy_f': 'Elegant puffer jacket, cashmere scarf, warm leggings, and fur-lined boots.',
      'partly_cloudy_m': 'Button-up shirt, light chinos, and clean white sneakers.',
      'partly_cloudy_f': 'Flowy blouse, linen pants, and strappy sandals.',
      // Outfit item translations
      'item_peacoat': 'Peacoat', 'item_dark_jeans': 'Dark Jeans', 'item_leather_boots': 'Leather Boots',
      'item_beanie': 'Beanie', 'item_trench': 'Trench Coat', 'item_wool_pants': 'Wool Pants',
      'item_ankle_boots': 'Ankle Boots', 'item_scarf': 'Scarf', 'item_storm_jacket': 'Storm Jacket',
      'item_cargo_pants': 'Cargo Pants', 'item_rain_boots': 'Rain Boots', 'item_umbrella': 'Umbrella',
      'item_rain_parka': 'Rain Parka', 'item_leggings': 'Leggings', 'item_waterproof_boots': 'Waterproof Boots',
      'item_linen_shirt': 'Linen Shirt', 'item_shorts': 'Shorts', 'item_sandals': 'Sandals',
      'item_sunglasses': 'Sunglasses', 'item_cotton_dress': 'Cotton Dress', 'item_light_skirt': 'Light Skirt',
      'item_open_sandals': 'Open Sandals', 'item_sun_hat': 'Sun Hat', 'item_down_jacket': 'Down Jacket',
      'item_thermal_pants': 'Thermal Pants', 'item_insulated_boots': 'Insulated Boots', 'item_gloves': 'Gloves',
      'item_puffer_coat': 'Puffer Coat', 'item_warm_leggings': 'Warm Leggings', 'item_fur_boots': 'Fur Boots',
      'item_cashmere_scarf': 'Cashmere Scarf', 'item_light_jacket': 'Light Jacket', 'item_chinos': 'Chinos',
      'item_loafers': 'Loafers', 'item_watch': 'Watch', 'item_cardigan': 'Cardigan',
      'item_floral_dress': 'Floral Dress', 'item_ballet_flats': 'Ballet Flats', 'item_clutch': 'Clutch',
      'item_winter_coat': 'Winter Coat', 'item_thermal_layers': 'Thermal Layers', 'item_snow_boots': 'Snow Boots',
      'item_puffer_jacket': 'Puffer Jacket', 'item_wool_overcoat': 'Wool Overcoat', 'item_sweater': 'Sweater',
      'item_turtleneck': 'Turtleneck', 'item_slim_pants': 'Slim Pants',
      'item_waterproof_parka': 'Waterproof Parka', 'item_hoodie': 'Hoodie', 'item_knit_dress': 'Knit Dress',
      'item_chelsea_boots': 'Chelsea Boots', 'item_tights': 'Tights', 'item_bomber': 'Bomber Jacket',
      'item_sneakers': 'Sneakers', 'item_blouse': 'Blouse', 'item_midi_skirt': 'Midi Skirt',
      'item_rain_jacket': 'Rain Jacket', 'item_tshirt': 'T-Shirt', 'item_waterproof_shoes': 'Waterproof Shoes',
      'item_jeans': 'Jeans', 'item_raincoat': 'Raincoat', 'item_rain_flats': 'Rain Flats',
      'item_button_shirt': 'Button Shirt', 'item_white_sneakers': 'White Sneakers',
      'item_linen_pants': 'Linen Pants', 'item_strappy_sandals': 'Strappy Sandals',
      'item_quick_dry_shorts': 'Quick-Dry Shorts', 'item_sport_sandals': 'Sport Sandals',
      'item_summer_dress': 'Summer Dress', 'item_light_cardigan': 'Light Cardigan',
      'item_waterproof_sandals': 'Waterproof Sandals', 'item_breathable_sneakers': 'Breathable Sneakers',
      'item_sundress': 'Sundress', 'item_espadrilles': 'Espadrilles',
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
      'foggy': 'Sisli', 'stormy': 'Fırtınalı', 'humid': 'Nemli', 'frosty': 'Ayaz', 'spring_evening': 'Bahar Akşamı',
      'outfit_foggy_m': 'Kaban, koyu kot, deri bot ve bere — sisli hava için ideal.',
      'outfit_foggy_f': 'Şık trençkot, yünlü pantolon, bilekte bot ve sıcak atkı.',
      'outfit_stormy_m': 'Ağır fırtına ceketi, kargo pantolon, yağmur botu ve şemsiye.',
      'outfit_stormy_f': 'Su geçirmez parka, sıcak tayt, yüksek bot ve sağlam şemsiye.',
      'outfit_humid_m': 'Nefes alan keten gömlek, hafif şort, açık sandalet ve güneş gözlüğü.',
      'outfit_humid_f': 'Havadar pamuklu elbise, hafif etek, açık sandalet ve güneş şapkası.',
      'outfit_frosty_m': 'Yalıtımlı şişme mont, termal pantolon, ağır bot ve astarlı eldiven.',
      'outfit_frosty_f': 'Lüks kaz tüyü mont, sıcak tayt, kürklü bot ve kaşmir atkı.',
      'outfit_spring_eve_m': 'Hafif ceket, slim chino, süet loafer ve şık saat.',
      'outfit_spring_eve_f': 'Yumuşak hırka, çiçekli midi elbise, babet ve gece çantası.',
      'foggy_m': 'Kaban, koyu kot, deri bot ve bere — sisli hava için ideal.',
      'foggy_f': 'Şık trençkot, yünlü pantolon, bilekte bot ve sıcak atkı.',
      'stormy_m': 'Ağır fırtına ceketi, kargo pantolon, yağmur botu ve şemsiye.',
      'stormy_f': 'Su geçirmez parka, sıcak tayt, yüksek bot ve sağlam şemsiye.',
      'humid_m': 'Nefes alan keten gömlek, hafif şort, açık sandalet ve güneş gözlüğü.',
      'humid_f': 'Havadar pamuklu elbise, hafif etek, açık sandalet ve güneş şapkası.',
      'frosty_m': 'Yalıtımlı şişme mont, termal pantolon, ağır bot ve astarlı eldiven.',
      'frosty_f': 'Lüks kaz tüyü mont, sıcak tayt, kürklü bot ve kaşmir atkı.',
      'spring_evening_m': 'Hafif ceket, slim chino, süet loafer ve şık saat.',
      'spring_evening_f': 'Yumuşak hırka, çiçekli midi elbise, babet ve gece çantası.',
      'sunny_m': 'Keten gömlek, şort, güneş gözlüğü ve nefes alan spor ayakkabı.',
      'sunny_f': 'Yazlık elbise, geniş kenarlı şapka, güneş gözlüğü ve espadril.',
      'rainy_m': 'Su geçirmez parka, kapüşonlu, kargo pantolon ve yağmur botu.',
      'rainy_f': 'Kemerli trençkot, örgü elbise, tayt ve su geçirmez Chelsea bot.',
      'cloudy_m': 'Bomber ceket, bisiklet yaka kazak, chino ve spor ayakkabı.',
      'cloudy_f': 'Hırka, bluz, midi etek ve loafer.',
      'snowy_m': 'Kalın kışlık mont, termal iç giyim, atkı, eldiven ve kar botu.',
      'snowy_f': 'Şık şişme mont, kaşmir atkı, sıcak tayt ve kürklü bot.',
      'partly_cloudy_m': 'Düğmeli gömlek, hafif chino ve beyaz spor ayakkabı.',
      'partly_cloudy_f': 'Akışkan bluz, keten pantolon ve bantlı sandalet.',
      'item_peacoat': 'Kaban', 'item_dark_jeans': 'Koyu Kot', 'item_leather_boots': 'Deri Bot',
      'item_beanie': 'Bere', 'item_trench': 'Trençkot', 'item_wool_pants': 'Yünlü Pantolon',
      'item_ankle_boots': 'Bilekte Bot', 'item_scarf': 'Atkı', 'item_storm_jacket': 'Fırtına Ceketi',
      'item_cargo_pants': 'Kargo Pantolon', 'item_rain_boots': 'Yağmur Botu', 'item_umbrella': 'Şemsiye',
      'item_rain_parka': 'Yağmur Parka', 'item_leggings': 'Tayt', 'item_waterproof_boots': 'Su Geçirmez Bot',
      'item_linen_shirt': 'Keten Gömlek', 'item_shorts': 'Şort', 'item_sandals': 'Sandalet',
      'item_sunglasses': 'Güneş Gözlüğü', 'item_cotton_dress': 'Pamuklu Elbise', 'item_light_skirt': 'Hafif Etek',
      'item_open_sandals': 'Açık Sandalet', 'item_sun_hat': 'Güneş Şapkası', 'item_down_jacket': 'Şişme Mont',
      'item_thermal_pants': 'Termal Pantolon', 'item_insulated_boots': 'Yalıtımlı Bot', 'item_gloves': 'Eldiven',
      'item_puffer_coat': 'Kaz Tüyü Mont', 'item_warm_leggings': 'Sıcak Tayt', 'item_fur_boots': 'Kürklü Bot',
      'item_cashmere_scarf': 'Kaşmir Atkı', 'item_light_jacket': 'Hafif Ceket', 'item_chinos': 'Chino',
      'item_loafers': 'Loafer', 'item_watch': 'Saat', 'item_cardigan': 'Hırka',
      'item_floral_dress': 'Çiçekli Elbise', 'item_ballet_flats': 'Babet', 'item_clutch': 'El Çantası',
      'item_winter_coat': 'Kışlık Mont', 'item_thermal_layers': 'Termal İç Giyim', 'item_snow_boots': 'Kar Botu',
      'item_puffer_jacket': 'Şişme Mont', 'item_wool_overcoat': 'Yünlü Palto', 'item_sweater': 'Kazak',
      'item_turtleneck': 'Balıkçı Yaka', 'item_slim_pants': 'Slim Pantolon',
      'item_waterproof_parka': 'Su Geçirmez Parka', 'item_hoodie': 'Kapüşonlu', 'item_knit_dress': 'Örgü Elbise',
      'item_chelsea_boots': 'Chelsea Bot', 'item_tights': 'Külotlu Çorap', 'item_bomber': 'Bomber Ceket',
      'item_sneakers': 'Spor Ayakkabı', 'item_blouse': 'Bluz', 'item_midi_skirt': 'Midi Etek',
      'item_rain_jacket': 'Yağmurluk', 'item_tshirt': 'Tişört', 'item_waterproof_shoes': 'Su Geçirmez Ayakkabı',
      'item_jeans': 'Kot', 'item_raincoat': 'Yağmurluk', 'item_rain_flats': 'Yağmur Babeti',
      'item_button_shirt': 'Düğmeli Gömlek', 'item_white_sneakers': 'Beyaz Spor Ayakkabı',
      'item_linen_pants': 'Keten Pantolon', 'item_strappy_sandals': 'Bantlı Sandalet',
      'item_quick_dry_shorts': 'Çabuk Kuruyan Şort', 'item_sport_sandals': 'Spor Sandalet',
      'item_summer_dress': 'Yazlık Elbise', 'item_light_cardigan': 'Hafif Hırka',
      'item_waterproof_sandals': 'Su Geçirmez Sandalet', 'item_breathable_sneakers': 'Nefes Alan Ayakkabı',
      'item_sundress': 'Yazlık Elbise', 'item_espadrilles': 'Espadril',
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
      'foggy': 'ضبابي', 'stormy': 'عاصف', 'humid': 'رطب', 'frosty': 'صقيعي', 'spring_evening': 'مساء ربيعي',
      'outfit_foggy_m': 'معطف بحري وجينز داكن وحذاء جلد وقبعة صوف.',
      'outfit_foggy_f': 'ترنش كوت أنيق وبنطلون صوف وبوت كاحل ووشاح دافئ.',
      'outfit_stormy_m': 'جاكيت مقاوم للعواصف وبنطلون كارجو وحذاء مطر ومظلة.',
      'outfit_stormy_f': 'باركا مقاومة للماء وتايت دافئ وحذاء عالي ومظلة متينة.',
      'outfit_humid_m': 'قميص كتان خفيف وشورت وصندل مفتوح ونظارات شمسية.',
      'outfit_humid_f': 'فستان قطني خفيف وتنورة خفيفة وصندل مفتوح وقبعة شمسية.',
      'outfit_frosty_m': 'جاكيت ريشي وبنطلون حراري وحذاء معزول وقفازات مبطنة.',
      'outfit_frosty_f': 'معطف ريشي فاخر وتايت دافئ وحذاء فرو ووشاح كشمير.',
      'outfit_spring_eve_m': 'جاكيت خفيف وتشينو رفيع ولوفر وساعة أنيقة.',
      'outfit_spring_eve_f': 'كارديجان ناعم وفستان زهري ميدي وبالرينا وحقيبة سهرة.',
      'foggy_m': 'معطف بحري وجينز داكن وحذاء جلد وقبعة صوف.',
      'foggy_f': 'ترنش كوت أنيق وبنطلون صوف وبوت كاحل ووشاح دافئ.',
      'stormy_m': 'جاكيت مقاوم للعواصف وبنطلون كارجو وحذاء مطر ومظلة.',
      'stormy_f': 'باركا مقاومة للماء وتايت دافئ وحذاء عالي ومظلة متينة.',
      'humid_m': 'قميص كتان خفيف وشورت وصندل مفتوح ونظارات شمسية.',
      'humid_f': 'فستان قطني خفيف وتنورة خفيفة وصندل مفتوح وقبعة شمسية.',
      'frosty_m': 'جاكيت ريشي وبنطلون حراري وحذاء معزول وقفازات مبطنة.',
      'frosty_f': 'معطف ريشي فاخر وتايت دافئ وحذاء فرو ووشاح كشمير.',
      'spring_evening_m': 'جاكيت خفيف وتشينو رفيع ولوفر وساعة أنيقة.',
      'spring_evening_f': 'كارديجان ناعم وفستان زهري ميدي وبالرينا وحقيبة سهرة.',
      'sunny_m': 'قميص كتان وشورت ونظارات شمسية وحذاء خفيف.',
      'sunny_f': 'فستان شمسي وقبعة واسعة ونظارات شمسية وإسبادريل.',
      'rainy_m': 'باركا مقاومة للماء وهودي وبنطلون كارجو وحذاء مطر.',
      'rainy_f': 'ترنش كوت بحزام وفستان محبوك وجوارب وبوت تشيلسي مقاوم للماء.',
      'cloudy_m': 'جاكيت بومبر وكنزة وتشينو وحذاء رياضي.',
      'cloudy_f': 'كارديجان وبلوزة وتنورة ميدي ولوفر.',
      'snowy_m': 'معطف شتوي ثقيل وطبقات حرارية ووشاح وقفازات وأحذية ثلج.',
      'snowy_f': 'جاكيت منفوخ أنيق ووشاح كشمير وبنطلون دافئ وحذاء مبطن بالفرو.',
      'partly_cloudy_m': 'قميص بأزرار وتشينو خفيف وحذاء رياضي أبيض.',
      'partly_cloudy_f': 'بلوزة انسيابية وبنطلون كتان وصندل بأشرطة.',
      // Outfit item translations
      'item_peacoat': 'معطف بحري', 'item_dark_jeans': 'جينز داكن', 'item_leather_boots': 'حذاء جلد',
      'item_beanie': 'قبعة صوف', 'item_trench': 'ترنش كوت', 'item_wool_pants': 'بنطلون صوف',
      'item_ankle_boots': 'بوت كاحل', 'item_scarf': 'وشاح', 'item_storm_jacket': 'جاكيت عواصف',
      'item_cargo_pants': 'بنطلون كارجو', 'item_rain_boots': 'حذاء مطر', 'item_umbrella': 'مظلة',
      'item_rain_parka': 'باركا مطر', 'item_leggings': 'تايت', 'item_waterproof_boots': 'حذاء مقاوم للماء',
      'item_linen_shirt': 'قميص كتان', 'item_shorts': 'شورت', 'item_sandals': 'صندل',
      'item_sunglasses': 'نظارات شمسية', 'item_cotton_dress': 'فستان قطني', 'item_light_skirt': 'تنورة خفيفة',
      'item_open_sandals': 'صندل مفتوح', 'item_sun_hat': 'قبعة شمسية', 'item_down_jacket': 'جاكيت ريشي',
      'item_thermal_pants': 'بنطلون حراري', 'item_insulated_boots': 'حذاء معزول', 'item_gloves': 'قفازات',
      'item_puffer_coat': 'معطف منفوخ', 'item_warm_leggings': 'تايت دافئ', 'item_fur_boots': 'حذاء فرو',
      'item_cashmere_scarf': 'وشاح كشمير', 'item_light_jacket': 'جاكيت خفيف', 'item_chinos': 'تشينو',
      'item_loafers': 'لوفر', 'item_watch': 'ساعة', 'item_cardigan': 'كارديجان',
      'item_floral_dress': 'فستان زهري', 'item_ballet_flats': 'بالرينا', 'item_clutch': 'حقيبة سهرة',
      'item_winter_coat': 'معطف شتوي', 'item_thermal_layers': 'طبقات حرارية', 'item_snow_boots': 'حذاء ثلج',
      'item_puffer_jacket': 'جاكيت منفوخ', 'item_wool_overcoat': 'معطف صوف', 'item_sweater': 'كنزة',
      'item_turtleneck': 'ياقة عالية', 'item_slim_pants': 'بنطلون ضيق',
      'item_waterproof_parka': 'باركا مقاومة للماء', 'item_hoodie': 'هودي', 'item_knit_dress': 'فستان محبوك',
      'item_chelsea_boots': 'بوت تشيلسي', 'item_tights': 'جوارب', 'item_bomber': 'جاكيت بومبر',
      'item_sneakers': 'حذاء رياضي', 'item_blouse': 'بلوزة', 'item_midi_skirt': 'تنورة ميدي',
      'item_rain_jacket': 'جاكيت مطر', 'item_tshirt': 'تيشيرت', 'item_waterproof_shoes': 'حذاء مقاوم للماء',
      'item_jeans': 'جينز', 'item_raincoat': 'معطف مطر', 'item_rain_flats': 'حذاء مسطح مقاوم',
      'item_button_shirt': 'قميص بأزرار', 'item_white_sneakers': 'حذاء رياضي أبيض',
      'item_linen_pants': 'بنطلون كتان', 'item_strappy_sandals': 'صندل بأشرطة',
      'item_quick_dry_shorts': 'شورت سريع الجفاف', 'item_sport_sandals': 'صندل رياضي',
      'item_summer_dress': 'فستان صيفي', 'item_light_cardigan': 'كارديجان خفيف',
      'item_waterproof_sandals': 'صندل مقاوم للماء', 'item_breathable_sneakers': 'حذاء خفيف',
      'item_sundress': 'فستان شمسي', 'item_espadrilles': 'إسبادريل',
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
      'foggy': 'Туманно', 'stormy': 'Штормовой', 'humid': 'Влажно', 'frosty': 'Морозно', 'spring_evening': 'Весенний вечер',
      'outfit_foggy_m': 'Бушлат, тёмные джинсы, кожаные ботинки и шапка-бини.',
      'outfit_foggy_f': 'Элегантный тренч, шерстяные брюки, ботильоны и тёплый шарф.',
      'outfit_stormy_m': 'Штормовая куртка, карго, резиновые ботинки и зонт.',
      'outfit_stormy_f': 'Водонепроницаемая парка, тёплые леггинсы, высокие ботинки и зонт.',
      'outfit_humid_m': 'Льняная рубашка, шорты, сандалии и солнечные очки.',
      'outfit_humid_f': 'Хлопковое платье, лёгкая юбка, сандалии и шляпа от солнца.',
      'outfit_frosty_m': 'Пуховик, термобрюки, утеплённые ботинки и перчатки.',
      'outfit_frosty_f': 'Роскошный пуховик, тёплые леггинсы, сапоги с мехом и кашемировый шарф.',
      'outfit_spring_eve_m': 'Лёгкая куртка, чиносы, замшевые лоферы и стильные часы.',
      'outfit_spring_eve_f': 'Мягкий кардиган, цветочное миди-платье, балетки и клатч.',
      'foggy_m': 'Бушлат, тёмные джинсы, кожаные ботинки и шапка-бини.',
      'foggy_f': 'Элегантный тренч, шерстяные брюки, ботильоны и тёплый шарф.',
      'stormy_m': 'Штормовая куртка, карго, резиновые ботинки и зонт.',
      'stormy_f': 'Водонепроницаемая парка, тёплые леггинсы, высокие ботинки и зонт.',
      'humid_m': 'Льняная рубашка, шорты, сандалии и солнечные очки.',
      'humid_f': 'Хлопковое платье, лёгкая юбка, сандалии и шляпа от солнца.',
      'frosty_m': 'Пуховик, термобрюки, утеплённые ботинки и перчатки.',
      'frosty_f': 'Роскошный пуховик, тёплые леггинсы, сапоги с мехом и кашемировый шарф.',
      'spring_evening_m': 'Лёгкая куртка, чиносы, замшевые лоферы и стильные часы.',
      'spring_evening_f': 'Мягкий кардиган, цветочное миди-платье, балетки и клатч.',
      'sunny_m': 'Льняная рубашка, шорты, очки и лёгкие кроссовки.',
      'sunny_f': 'Сарафан, широкополая шляпа, очки и эспадрильи.',
      'rainy_m': 'Водонепроницаемая парка, худи, карго и резиновые ботинки.',
      'rainy_f': 'Тренч с поясом, вязаное платье, колготки и ботинки Челси.',
      'cloudy_m': 'Бомбер, свитер, чиносы и кроссовки.',
      'cloudy_f': 'Кардиган, блузка, миди-юбка и лоферы.',
      'snowy_m': 'Тёплое зимнее пальто, термобельё, шарф, перчатки и зимние ботинки.',
      'snowy_f': 'Элегантный пуховик, кашемировый шарф, утеплённые леггинсы и ботинки с мехом.',
      'partly_cloudy_m': 'Рубашка на пуговицах, лёгкие чиносы и белые кроссовки.',
      'partly_cloudy_f': 'Лёгкая блузка, льняные брюки и босоножки.',
      // Outfit item translations
      'item_peacoat': 'Бушлат', 'item_dark_jeans': 'Тёмные джинсы', 'item_leather_boots': 'Кожаные ботинки',
      'item_beanie': 'Шапка-бини', 'item_trench': 'Тренч', 'item_wool_pants': 'Шерстяные брюки',
      'item_ankle_boots': 'Ботильоны', 'item_scarf': 'Шарф', 'item_storm_jacket': 'Штормовка',
      'item_cargo_pants': 'Карго', 'item_rain_boots': 'Резиновые ботинки', 'item_umbrella': 'Зонт',
      'item_rain_parka': 'Дождевая парка', 'item_leggings': 'Леггинсы', 'item_waterproof_boots': 'Водонепр. ботинки',
      'item_linen_shirt': 'Льняная рубашка', 'item_shorts': 'Шорты', 'item_sandals': 'Сандалии',
      'item_sunglasses': 'Солнечные очки', 'item_cotton_dress': 'Хлопковое платье', 'item_light_skirt': 'Лёгкая юбка',
      'item_open_sandals': 'Открытые сандалии', 'item_sun_hat': 'Шляпа от солнца', 'item_down_jacket': 'Пуховик',
      'item_thermal_pants': 'Термобрюки', 'item_insulated_boots': 'Утеплённые ботинки', 'item_gloves': 'Перчатки',
      'item_puffer_coat': 'Пуховое пальто', 'item_warm_leggings': 'Тёплые леггинсы', 'item_fur_boots': 'Сапоги с мехом',
      'item_cashmere_scarf': 'Кашемировый шарф', 'item_light_jacket': 'Лёгкая куртка', 'item_chinos': 'Чиносы',
      'item_loafers': 'Лоферы', 'item_watch': 'Часы', 'item_cardigan': 'Кардиган',
      'item_floral_dress': 'Цветочное платье', 'item_ballet_flats': 'Балетки', 'item_clutch': 'Клатч',
      'item_winter_coat': 'Зимнее пальто', 'item_thermal_layers': 'Термобельё', 'item_snow_boots': 'Зимние ботинки',
      'item_puffer_jacket': 'Пуховик', 'item_wool_overcoat': 'Шерстяное пальто', 'item_sweater': 'Свитер',
      'item_turtleneck': 'Водолазка', 'item_slim_pants': 'Узкие брюки',
      'item_waterproof_parka': 'Водонепр. парка', 'item_hoodie': 'Худи', 'item_knit_dress': 'Вязаное платье',
      'item_chelsea_boots': 'Ботинки Челси', 'item_tights': 'Колготки', 'item_bomber': 'Бомбер',
      'item_sneakers': 'Кроссовки', 'item_blouse': 'Блузка', 'item_midi_skirt': 'Миди-юбка',
      'item_rain_jacket': 'Дождевик', 'item_tshirt': 'Футболка', 'item_waterproof_shoes': 'Непромок. обувь',
      'item_jeans': 'Джинсы', 'item_raincoat': 'Плащ', 'item_rain_flats': 'Непромок. балетки',
      'item_button_shirt': 'Рубашка', 'item_white_sneakers': 'Белые кроссовки',
      'item_linen_pants': 'Льняные брюки', 'item_strappy_sandals': 'Босоножки',
      'item_quick_dry_shorts': 'Быстросохн. шорты', 'item_sport_sandals': 'Спорт. сандалии',
      'item_summer_dress': 'Летнее платье', 'item_light_cardigan': 'Лёгкий кардиган',
      'item_waterproof_sandals': 'Водонепр. сандалии', 'item_breathable_sneakers': 'Лёгкие кроссовки',
      'item_sundress': 'Сарафан', 'item_espadrilles': 'Эспадрильи',
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
      'foggy': 'Niebla', 'stormy': 'Tormentoso', 'humid': 'Húmedo', 'frosty': 'Helado', 'spring_evening': 'Tarde de primavera',
      'outfit_foggy_m': 'Chaquetón, vaqueros oscuros, botas de cuero y gorro.',
      'outfit_foggy_f': 'Trench elegante, pantalón de lana, botines y bufanda cálida.',
      'outfit_stormy_m': 'Chaqueta de tormenta, pantalones cargo, botas de lluvia y paraguas.',
      'outfit_stormy_f': 'Parka impermeable, leggins cálidos, botas altas y paraguas resistente.',
      'outfit_humid_m': 'Camisa de lino, bermudas, sandalias abiertas y gafas de sol.',
      'outfit_humid_f': 'Vestido de algodón ligero, falda ligera, sandalias y sombrero de sol.',
      'outfit_frosty_m': 'Plumífero, pantalón térmico, botas aislantes y guantes forrados.',
      'outfit_frosty_f': 'Abrigo plumífero de lujo, leggins cálidos, botas con pelo y bufanda de cachemira.',
      'outfit_spring_eve_m': 'Chaqueta ligera, chinos slim, mocasines de ante y reloj elegante.',
      'outfit_spring_eve_f': 'Cárdigan suave, vestido floral midi, bailarinas y bolso de noche.',
      'foggy_m': 'Chaquetón, vaqueros oscuros, botas de cuero y gorro.',
      'foggy_f': 'Trench elegante, pantalón de lana, botines y bufanda cálida.',
      'stormy_m': 'Chaqueta de tormenta, pantalones cargo, botas de lluvia y paraguas.',
      'stormy_f': 'Parka impermeable, leggins cálidos, botas altas y paraguas resistente.',
      'humid_m': 'Camisa de lino, bermudas, sandalias abiertas y gafas de sol.',
      'humid_f': 'Vestido de algodón ligero, falda ligera, sandalias y sombrero de sol.',
      'frosty_m': 'Plumífero, pantalón térmico, botas aislantes y guantes forrados.',
      'frosty_f': 'Abrigo plumífero de lujo, leggins cálidos, botas con pelo y bufanda de cachemira.',
      'spring_evening_m': 'Chaqueta ligera, chinos slim, mocasines de ante y reloj elegante.',
      'spring_evening_f': 'Cárdigan suave, vestido floral midi, bailarinas y bolso de noche.',
      'sunny_m': 'Camisa de lino, bermudas, gafas de sol y zapatillas.',
      'sunny_f': 'Vestido de verano, sombrero, gafas de sol y alpargatas.',
      'rainy_m': 'Parka impermeable, sudadera, cargo y botas de lluvia.',
      'rainy_f': 'Trench con cinturón, vestido de punto, medias y botas Chelsea.',
      'cloudy_m': 'Bomber, suéter, chinos y zapatillas.',
      'cloudy_f': 'Cárdigan, blusa, falda midi y mocasines.',
      'snowy_m': 'Abrigo de invierno, capas térmicas, bufanda, guantes y botas de nieve.',
      'snowy_f': 'Plumífero elegante, bufanda de cachemira, leggins cálidos y botas forradas.',
      'partly_cloudy_m': 'Camisa, chinos ligeros y zapatillas blancas.',
      'partly_cloudy_f': 'Blusa fluida, pantalón de lino y sandalias.',
      // Outfit item translations
      'item_peacoat': 'Chaquetón', 'item_dark_jeans': 'Vaqueros oscuros', 'item_leather_boots': 'Botas de cuero',
      'item_beanie': 'Gorro', 'item_trench': 'Trench', 'item_wool_pants': 'Pantalón de lana',
      'item_ankle_boots': 'Botines', 'item_scarf': 'Bufanda', 'item_storm_jacket': 'Chaqueta tormenta',
      'item_cargo_pants': 'Pantalón cargo', 'item_rain_boots': 'Botas de lluvia', 'item_umbrella': 'Paraguas',
      'item_rain_parka': 'Parka de lluvia', 'item_leggings': 'Leggins', 'item_waterproof_boots': 'Botas impermeables',
      'item_linen_shirt': 'Camisa de lino', 'item_shorts': 'Bermudas', 'item_sandals': 'Sandalias',
      'item_sunglasses': 'Gafas de sol', 'item_cotton_dress': 'Vestido algodón', 'item_light_skirt': 'Falda ligera',
      'item_open_sandals': 'Sandalias abiertas', 'item_sun_hat': 'Sombrero de sol', 'item_down_jacket': 'Plumífero',
      'item_thermal_pants': 'Pantalón térmico', 'item_insulated_boots': 'Botas aislantes', 'item_gloves': 'Guantes',
      'item_puffer_coat': 'Abrigo plumífero', 'item_warm_leggings': 'Leggins cálidos', 'item_fur_boots': 'Botas con pelo',
      'item_cashmere_scarf': 'Bufanda cachemira', 'item_light_jacket': 'Chaqueta ligera', 'item_chinos': 'Chinos',
      'item_loafers': 'Mocasines', 'item_watch': 'Reloj', 'item_cardigan': 'Cárdigan',
      'item_floral_dress': 'Vestido floral', 'item_ballet_flats': 'Bailarinas', 'item_clutch': 'Bolso de noche',
      'item_winter_coat': 'Abrigo invierno', 'item_thermal_layers': 'Capas térmicas', 'item_snow_boots': 'Botas de nieve',
      'item_puffer_jacket': 'Chaqueta acolchada', 'item_wool_overcoat': 'Abrigo de lana', 'item_sweater': 'Suéter',
      'item_turtleneck': 'Cuello alto', 'item_slim_pants': 'Pantalón slim',
      'item_waterproof_parka': 'Parka impermeable', 'item_hoodie': 'Sudadera', 'item_knit_dress': 'Vestido de punto',
      'item_chelsea_boots': 'Botas Chelsea', 'item_tights': 'Medias', 'item_bomber': 'Bomber',
      'item_sneakers': 'Zapatillas', 'item_blouse': 'Blusa', 'item_midi_skirt': 'Falda midi',
      'item_rain_jacket': 'Chaqueta lluvia', 'item_tshirt': 'Camiseta', 'item_waterproof_shoes': 'Zapatos impermeables',
      'item_jeans': 'Vaqueros', 'item_raincoat': 'Impermeable', 'item_rain_flats': 'Zapatos planos',
      'item_button_shirt': 'Camisa', 'item_white_sneakers': 'Zapatillas blancas',
      'item_linen_pants': 'Pantalón de lino', 'item_strappy_sandals': 'Sandalias con tiras',
      'item_quick_dry_shorts': 'Bermudas secado rápido', 'item_sport_sandals': 'Sandalias deporte',
      'item_summer_dress': 'Vestido veraniego', 'item_light_cardigan': 'Cárdigan ligero',
      'item_waterproof_sandals': 'Sandalias impermeables', 'item_breathable_sneakers': 'Zapatillas ligeras',
      'item_sundress': 'Vestido de verano', 'item_espadrilles': 'Alpargatas',
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
      'foggy': 'Nebbioso', 'stormy': 'Tempestoso', 'humid': 'Umido', 'frosty': 'Gelido', 'spring_evening': 'Sera di primavera',
      'outfit_foggy_m': 'Cappotto, jeans scuri, stivali in pelle e berretto.',
      'outfit_foggy_f': 'Trench elegante, pantaloni di lana, stivaletti e sciarpa calda.',
      'outfit_stormy_m': 'Giacca da tempesta, pantaloni cargo, stivali da pioggia e ombrello.',
      'outfit_stormy_f': 'Parka impermeabile, leggings caldi, stivali alti e ombrello robusto.',
      'outfit_humid_m': 'Camicia in lino, bermuda, sandali aperti e occhiali da sole.',
      'outfit_humid_f': 'Vestito in cotone leggero, gonna leggera, sandali e cappello da sole.',
      'outfit_frosty_m': 'Piumino, pantaloni termici, stivali isolanti e guanti foderati.',
      'outfit_frosty_f': 'Piumino di lusso, leggings caldi, stivali con pelliccia e sciarpa in cashmere.',
      'outfit_spring_eve_m': 'Giacca leggera, chinos slim, mocassini in camoscio e orologio elegante.',
      'outfit_spring_eve_f': 'Cardigan morbido, vestito a fiori midi, ballerine e pochette da sera.',
      'foggy_m': 'Cappotto, jeans scuri, stivali in pelle e berretto.',
      'foggy_f': 'Trench elegante, pantaloni di lana, stivaletti e sciarpa calda.',
      'stormy_m': 'Giacca da tempesta, pantaloni cargo, stivali da pioggia e ombrello.',
      'stormy_f': 'Parka impermeabile, leggings caldi, stivali alti e ombrello robusto.',
      'humid_m': 'Camicia in lino, bermuda, sandali aperti e occhiali da sole.',
      'humid_f': 'Vestito in cotone leggero, gonna leggera, sandali e cappello da sole.',
      'frosty_m': 'Piumino, pantaloni termici, stivali isolanti e guanti foderati.',
      'frosty_f': 'Piumino di lusso, leggings caldi, stivali con pelliccia e sciarpa in cashmere.',
      'spring_evening_m': 'Giacca leggera, chinos slim, mocassini in camoscio e orologio elegante.',
      'spring_evening_f': 'Cardigan morbido, vestito a fiori midi, ballerine e pochette da sera.',
      'sunny_m': 'Camicia in lino, bermuda, occhiali da sole e sneakers.',
      'sunny_f': 'Abito estivo, cappello a tesa larga, occhiali da sole ed espadrillas.',
      'rainy_m': 'Parka impermeabile, felpa, cargo e stivali da pioggia.',
      'rainy_f': 'Trench con cintura, abito in maglia, collant e stivali Chelsea.',
      'cloudy_m': 'Bomber, maglione girocollo, chinos e sneakers.',
      'cloudy_f': 'Cardigan, camicetta, gonna midi e mocassini.',
      'snowy_m': 'Cappotto invernale pesante, strati termici, sciarpa, guanti e stivali da neve.',
      'snowy_f': 'Piumino elegante, sciarpa in cashmere, leggings caldi e stivali foderati.',
      'partly_cloudy_m': 'Camicia con bottoni, chinos leggeri e sneakers bianche.',
      'partly_cloudy_f': 'Camicetta fluida, pantaloni in lino e sandali.',
      // Outfit item translations
      'item_peacoat': 'Cappotto', 'item_dark_jeans': 'Jeans scuri', 'item_leather_boots': 'Stivali in pelle',
      'item_beanie': 'Berretto', 'item_trench': 'Trench', 'item_wool_pants': 'Pantaloni di lana',
      'item_ankle_boots': 'Stivaletti', 'item_scarf': 'Sciarpa', 'item_storm_jacket': 'Giacca tempesta',
      'item_cargo_pants': 'Pantaloni cargo', 'item_rain_boots': 'Stivali pioggia', 'item_umbrella': 'Ombrello',
      'item_rain_parka': 'Parka pioggia', 'item_leggings': 'Leggings', 'item_waterproof_boots': 'Stivali impermeabili',
      'item_linen_shirt': 'Camicia in lino', 'item_shorts': 'Bermuda', 'item_sandals': 'Sandali',
      'item_sunglasses': 'Occhiali da sole', 'item_cotton_dress': 'Vestito cotone', 'item_light_skirt': 'Gonna leggera',
      'item_open_sandals': 'Sandali aperti', 'item_sun_hat': 'Cappello da sole', 'item_down_jacket': 'Piumino',
      'item_thermal_pants': 'Pantaloni termici', 'item_insulated_boots': 'Stivali isolanti', 'item_gloves': 'Guanti',
      'item_puffer_coat': 'Piumino lungo', 'item_warm_leggings': 'Leggings caldi', 'item_fur_boots': 'Stivali pelliccia',
      'item_cashmere_scarf': 'Sciarpa cashmere', 'item_light_jacket': 'Giacca leggera', 'item_chinos': 'Chinos',
      'item_loafers': 'Mocassini', 'item_watch': 'Orologio', 'item_cardigan': 'Cardigan',
      'item_floral_dress': 'Vestito a fiori', 'item_ballet_flats': 'Ballerine', 'item_clutch': 'Pochette',
      'item_winter_coat': 'Cappotto invernale', 'item_thermal_layers': 'Strati termici', 'item_snow_boots': 'Stivali neve',
      'item_puffer_jacket': 'Piumino', 'item_wool_overcoat': 'Cappotto lana', 'item_sweater': 'Maglione',
      'item_turtleneck': 'Dolcevita', 'item_slim_pants': 'Pantaloni slim',
      'item_waterproof_parka': 'Parka impermeabile', 'item_hoodie': 'Felpa', 'item_knit_dress': 'Abito in maglia',
      'item_chelsea_boots': 'Stivali Chelsea', 'item_tights': 'Collant', 'item_bomber': 'Bomber',
      'item_sneakers': 'Sneakers', 'item_blouse': 'Camicetta', 'item_midi_skirt': 'Gonna midi',
      'item_rain_jacket': 'Giacca antipioggia', 'item_tshirt': 'Maglietta', 'item_waterproof_shoes': 'Scarpe impermeabili',
      'item_jeans': 'Jeans', 'item_raincoat': 'Impermeabile', 'item_rain_flats': 'Ballerine impermeabili',
      'item_button_shirt': 'Camicia', 'item_white_sneakers': 'Sneakers bianche',
      'item_linen_pants': 'Pantaloni in lino', 'item_strappy_sandals': 'Sandali con cinturino',
      'item_quick_dry_shorts': 'Bermuda asciugatura rapida', 'item_sport_sandals': 'Sandali sportivi',
      'item_summer_dress': 'Vestito estivo', 'item_light_cardigan': 'Cardigan leggero',
      'item_waterproof_sandals': 'Sandali impermeabili', 'item_breathable_sneakers': 'Sneakers leggere',
      'item_sundress': 'Abito estivo', 'item_espadrilles': 'Espadrillas',
    },
    'de': {
      'home': 'Start', 'forecast': 'Vorhersage', 'favourites': 'Favoriten', 'settings': 'Einstellungen',
      'seven_day_forecast': '7-Tage-Vorhersage', 'five_day_forecast': '7-Tage-Vorhersage',
      'hourly_forecast': 'Stündliche Vorhersage',
      'search_city': 'Stadt suchen...', 'enter_city': 'Bitte Stadtnamen eingeben.',
      'city_not_found': 'Stadt nicht gefunden.', 'humidity': 'Feuchtigkeit', 'wind': 'Wind',
      'outfit_suggestion': 'Outfit-Vorschlag', 'country': 'Land', 'city': 'Stadt', 'district': 'Bezirk', 'language': 'Sprache',
      'customize': 'Passe dein Erlebnis an',
      'temp_unit': 'Temperatureinheit', 'celsius': 'Celsius (°C)', 'fahrenheit': 'Fahrenheit (°F)',
      'favourite_cities': 'Lieblingsstädte', 'saved_cities_count': 'gespeicherte Städte',
      'no_favourites': 'Keine Lieblingsstädte.\nTippe auf das Herz auf der Startseite.',
      'currently_viewing': 'Aktuelle Ansicht', 'tap_to_view': 'Tippen zum Anzeigen',
      'version': 'Version', 'dark_mode': 'Dunkelmodus', 'light_mode': 'Hellmodus', 'appearance': 'Erscheinungsbild',
      'male': 'Herren', 'female': 'Damen', 'gender': 'Stil',
      'seasonal_colors': 'Saisonfarben', 'color_palette': 'Farbpalette',
      'winter': 'Winter', 'spring': 'Frühling', 'summer': 'Sommer', 'autumn': 'Herbst', 'now': 'Jetzt',
      'mon': 'Mo', 'tue': 'Di', 'wed': 'Mi', 'thu': 'Do', 'fri': 'Fr', 'sat': 'Sa', 'sun': 'So',
      'clr_burgundy': 'Burgunder', 'clr_navy': 'Marine', 'clr_forest': 'Waldgrün', 'clr_charcoal': 'Anthrazit', 'clr_ivory': 'Elfenbein',
      'clr_burnt_orange': 'Branntorange', 'clr_mustard': 'Senf', 'clr_olive': 'Oliv', 'clr_saddle_brown': 'Braun',
      'clr_pastel_pink': 'Pastellrosa', 'clr_lavender': 'Lavendel', 'clr_mint': 'Minze', 'clr_soft_yellow': 'Sanftgelb', 'clr_sky_blue': 'Himmelblau',
      'clr_coral': 'Koralle', 'clr_turquoise': 'Türkis', 'clr_white': 'Weiß', 'clr_sand': 'Sand', 'clr_gold': 'Gold',
      'outfit_snow_m': 'Schwerer Wintermantel, Thermounterwäsche, Schal, Handschuhe und Schneestiefel.',
      'outfit_snow_f': 'Elegante Daunenjacke, Kaschmirschal, warme Leggings und Fellstiefel.',
      'outfit_heavy_cold_m': 'Wollmantel, Pullover, dunkle Jeans und Lederstiefel.',
      'outfit_heavy_cold_f': 'Langer Trenchcoat, Rollkragenpullover, Slim-Hose und Stiefeletten.',
      'outfit_cool_rain_m': 'Wasserdichter Parka, Hoodie, Cargohose und Regenstiefel.',
      'outfit_cool_rain_f': 'Trenchcoat mit Gürtel, Strickkleid, Strumpfhose und Chelsea-Boots.',
      'outfit_cool_m': 'Bomberjacke, Pullover, Chinos und Sneakers.',
      'outfit_cool_f': 'Strickjacke, Bluse, Midirock und Loafer.',
      'outfit_mild_rain_m': 'Leichte Regenjacke, T-Shirt, Jeans und wasserfeste Schuhe.',
      'outfit_mild_rain_f': 'Leichter Regenmantel, Blumenkleid und wasserabweisende Ballerinas.',
      'outfit_mild_m': 'Hemd, leichte Chinos und weiße Sneakers.',
      'outfit_mild_f': 'Fließende Bluse, Leinenhose und Riemchensandalen.',
      'outfit_hot_rain_m': 'Schnelltrocknende Shorts, T-Shirt und Sportsandalen mit Regenschirm.',
      'outfit_hot_rain_f': 'Luftiges Sommerkleid, leichte Strickjacke und wasserfeste Sandalen.',
      'outfit_hot_m': 'Leinenhemd, Shorts, Sonnenbrille und leichte Sneakers.',
      'outfit_hot_f': 'Sommerkleid, Strohhut, Sonnenbrille und Espadrilles.',
      'sunny': 'Sonnig', 'rainy': 'Regnerisch', 'cloudy': 'Bewölkt', 'snowy': 'Schneeig', 'partly_cloudy': 'Teilweise bewölkt',
      'foggy': 'Neblig', 'stormy': 'Stürmisch', 'humid': 'Schwül', 'frosty': 'Frostig', 'spring_evening': 'Frühlingsabend',
      'outfit_foggy_m': 'Cabanjacke, dunkle Jeans, Lederstiefel und Mütze.',
      'outfit_foggy_f': 'Eleganter Trench, Wollhose, Stiefeletten und warmer Schal.',
      'outfit_stormy_m': 'Sturmjacke, Cargohose, Regenstiefel und Regenschirm.',
      'outfit_stormy_f': 'Wasserdichter Parka, warme Leggings, hohe Stiefel und stabiler Schirm.',
      'outfit_humid_m': 'Leinenhemd, leichte Shorts, offene Sandalen und Sonnenbrille.',
      'outfit_humid_f': 'Luftiges Baumwollkleid, leichter Rock, Sandalen und Sonnenhut.',
      'outfit_frosty_m': 'Daunenjacke, Thermohose, isolierte Stiefel und gefütterte Handschuhe.',
      'outfit_frosty_f': 'Luxus-Daunenmantel, warme Leggings, Fellstiefel und Kaschmirschal.',
      'outfit_spring_eve_m': 'Leichte Jacke, Slim-Chinos, Wildleder-Loafer und elegante Uhr.',
      'outfit_spring_eve_f': 'Weiche Strickjacke, Blumen-Midikleid, Ballerinas und Abendtasche.',
      'foggy_m': 'Cabanjacke, dunkle Jeans, Lederstiefel und Mütze.',
      'foggy_f': 'Eleganter Trench, Wollhose, Stiefeletten und warmer Schal.',
      'stormy_m': 'Sturmjacke, Cargohose, Regenstiefel und Regenschirm.',
      'stormy_f': 'Wasserdichter Parka, warme Leggings, hohe Stiefel und stabiler Schirm.',
      'humid_m': 'Leinenhemd, leichte Shorts, offene Sandalen und Sonnenbrille.',
      'humid_f': 'Luftiges Baumwollkleid, leichter Rock, Sandalen und Sonnenhut.',
      'frosty_m': 'Daunenjacke, Thermohose, isolierte Stiefel und gefütterte Handschuhe.',
      'frosty_f': 'Luxus-Daunenmantel, warme Leggings, Fellstiefel und Kaschmirschal.',
      'spring_evening_m': 'Leichte Jacke, Slim-Chinos, Wildleder-Loafer und elegante Uhr.',
      'spring_evening_f': 'Weiche Strickjacke, Blumen-Midikleid, Ballerinas und Abendtasche.',
      'sunny_m': 'Leinenhemd, Shorts, Sonnenbrille und leichte Sneakers.',
      'sunny_f': 'Sommerkleid, Strohhut, Sonnenbrille und Espadrilles.',
      'rainy_m': 'Wasserdichter Parka, Hoodie, Cargohose und Regenstiefel.',
      'rainy_f': 'Trenchcoat mit Gürtel, Strickkleid, Strumpfhose und Chelsea-Boots.',
      'cloudy_m': 'Bomberjacke, Pullover, Chinos und Sneakers.',
      'cloudy_f': 'Strickjacke, Bluse, Midirock und Loafer.',
      'snowy_m': 'Schwerer Wintermantel, Thermounterwäsche, Schal, Handschuhe und Schneestiefel.',
      'snowy_f': 'Elegante Daunenjacke, Kaschmirschal, warme Leggings und Fellstiefel.',
      'partly_cloudy_m': 'Hemd, leichte Chinos und weiße Sneakers.',
      'partly_cloudy_f': 'Fließende Bluse, Leinenhose und Riemchensandalen.',
      'item_peacoat': 'Cabanjacke', 'item_dark_jeans': 'Dunkle Jeans', 'item_leather_boots': 'Lederstiefel',
      'item_beanie': 'Mütze', 'item_trench': 'Trenchcoat', 'item_wool_pants': 'Wollhose',
      'item_ankle_boots': 'Stiefeletten', 'item_scarf': 'Schal', 'item_storm_jacket': 'Sturmjacke',
      'item_cargo_pants': 'Cargohose', 'item_rain_boots': 'Regenstiefel', 'item_umbrella': 'Regenschirm',
      'item_rain_parka': 'Regenparka', 'item_leggings': 'Leggings', 'item_waterproof_boots': 'Wasserdichte Stiefel',
      'item_linen_shirt': 'Leinenhemd', 'item_shorts': 'Shorts', 'item_sandals': 'Sandalen',
      'item_sunglasses': 'Sonnenbrille', 'item_cotton_dress': 'Baumwollkleid', 'item_light_skirt': 'Leichter Rock',
      'item_open_sandals': 'Offene Sandalen', 'item_sun_hat': 'Sonnenhut', 'item_down_jacket': 'Daunenjacke',
      'item_thermal_pants': 'Thermohose', 'item_insulated_boots': 'Isolierte Stiefel', 'item_gloves': 'Handschuhe',
      'item_puffer_coat': 'Daunenmantel', 'item_warm_leggings': 'Warme Leggings', 'item_fur_boots': 'Fellstiefel',
      'item_cashmere_scarf': 'Kaschmirschal', 'item_light_jacket': 'Leichte Jacke', 'item_chinos': 'Chinos',
      'item_loafers': 'Loafer', 'item_watch': 'Uhr', 'item_cardigan': 'Strickjacke',
      'item_floral_dress': 'Blumenkleid', 'item_ballet_flats': 'Ballerinas', 'item_clutch': 'Abendtasche',
      'item_winter_coat': 'Wintermantel', 'item_thermal_layers': 'Thermounterwäsche', 'item_snow_boots': 'Schneestiefel',
      'item_puffer_jacket': 'Daunenjacke', 'item_wool_overcoat': 'Wollmantel', 'item_sweater': 'Pullover',
      'item_turtleneck': 'Rollkragen', 'item_slim_pants': 'Slim-Hose',
      'item_waterproof_parka': 'Wasserd. Parka', 'item_hoodie': 'Hoodie', 'item_knit_dress': 'Strickkleid',
      'item_chelsea_boots': 'Chelsea-Boots', 'item_tights': 'Strumpfhose', 'item_bomber': 'Bomberjacke',
      'item_sneakers': 'Sneakers', 'item_blouse': 'Bluse', 'item_midi_skirt': 'Midirock',
      'item_rain_jacket': 'Regenjacke', 'item_tshirt': 'T-Shirt', 'item_waterproof_shoes': 'Wasserd. Schuhe',
      'item_jeans': 'Jeans', 'item_raincoat': 'Regenmantel', 'item_rain_flats': 'Wasserd. Ballerinas',
      'item_button_shirt': 'Hemd', 'item_white_sneakers': 'Weiße Sneakers',
      'item_linen_pants': 'Leinenhose', 'item_strappy_sandals': 'Riemchensandalen',
      'item_quick_dry_shorts': 'Schnelltr. Shorts', 'item_sport_sandals': 'Sportsandalen',
      'item_summer_dress': 'Sommerkleid', 'item_light_cardigan': 'Leichte Strickjacke',
      'item_waterproof_sandals': 'Wasserd. Sandalen', 'item_breathable_sneakers': 'Leichte Sneakers',
      'item_sundress': 'Sommerkleid', 'item_espadrilles': 'Espadrilles',
    },
    'pt': {
      'home': 'Início', 'forecast': 'Previsão', 'favourites': 'Favoritos', 'settings': 'Configurações',
      'seven_day_forecast': 'Previsão 7 dias', 'five_day_forecast': 'Previsão 7 dias',
      'hourly_forecast': 'Previsão por hora',
      'search_city': 'Buscar cidade...', 'enter_city': 'Digite o nome da cidade.',
      'city_not_found': 'Cidade não encontrada.', 'humidity': 'Umidade', 'wind': 'Vento',
      'outfit_suggestion': 'Sugestão de look', 'country': 'País', 'city': 'Cidade', 'district': 'Distrito', 'language': 'Idioma',
      'customize': 'Personalize sua experiência',
      'temp_unit': 'Unidade de temperatura', 'celsius': 'Celsius (°C)', 'fahrenheit': 'Fahrenheit (°F)',
      'favourite_cities': 'Cidades favoritas', 'saved_cities_count': 'cidades salvas',
      'no_favourites': 'Sem cidades favoritas.\nToque no coração na tela inicial.',
      'currently_viewing': 'Visualizando', 'tap_to_view': 'Toque para ver',
      'version': 'Versão', 'dark_mode': 'Modo escuro', 'light_mode': 'Modo claro', 'appearance': 'Aparência',
      'male': 'Masculino', 'female': 'Feminino', 'gender': 'Estilo',
      'seasonal_colors': 'Cores da estação', 'color_palette': 'Paleta',
      'winter': 'Inverno', 'spring': 'Primavera', 'summer': 'Verão', 'autumn': 'Outono', 'now': 'Agora',
      'mon': 'Seg', 'tue': 'Ter', 'wed': 'Qua', 'thu': 'Qui', 'fri': 'Sex', 'sat': 'Sáb', 'sun': 'Dom',
      'clr_burgundy': 'Bordô', 'clr_navy': 'Marinho', 'clr_forest': 'Floresta', 'clr_charcoal': 'Carvão', 'clr_ivory': 'Marfim',
      'clr_burnt_orange': 'Laranja queimado', 'clr_mustard': 'Mostarda', 'clr_olive': 'Oliva', 'clr_saddle_brown': 'Marrom',
      'clr_pastel_pink': 'Rosa pastel', 'clr_lavender': 'Lavanda', 'clr_mint': 'Menta', 'clr_soft_yellow': 'Amarelo suave', 'clr_sky_blue': 'Azul céu',
      'clr_coral': 'Coral', 'clr_turquoise': 'Turquesa', 'clr_white': 'Branco', 'clr_sand': 'Areia', 'clr_gold': 'Dourado',
      'outfit_snow_m': 'Casacão pesado, camadas térmicas, cachecol, luvas e botas de neve.',
      'outfit_snow_f': 'Jaqueta puffer elegante, cachecol de cashmere, leggings quentes e botas forradas.',
      'outfit_heavy_cold_m': 'Sobretudo de lã, suéter, jeans escuro e botas de couro.',
      'outfit_heavy_cold_f': 'Trench longo, gola alta, calça slim e botins.',
      'outfit_cool_rain_m': 'Parka impermeável, moletom, calça cargo e botas de chuva.',
      'outfit_cool_rain_f': 'Trench com cinto, vestido de tricô, meia-calça e botas Chelsea.',
      'outfit_cool_m': 'Jaqueta bomber, suéter, chinos e tênis.',
      'outfit_cool_f': 'Cardigan, blusa, saia midi e mocassins.',
      'outfit_mild_rain_m': 'Jaqueta de chuva leve, camiseta, jeans e sapatos impermeáveis.',
      'outfit_mild_rain_f': 'Capa de chuva leve, vestido floral e sapatilhas resistentes.',
      'outfit_mild_m': 'Camisa social, chinos leves e tênis brancos.',
      'outfit_mild_f': 'Blusa fluida, calça de linho e sandálias de tira.',
      'outfit_hot_rain_m': 'Bermuda de secagem rápida, camiseta e sandálias esportivas com guarda-chuva.',
      'outfit_hot_rain_f': 'Vestido de verão leve, cardigan e sandálias impermeáveis.',
      'outfit_hot_m': 'Camisa de linho, bermuda, óculos de sol e tênis leves.',
      'outfit_hot_f': 'Vestido de verão, chapéu, óculos de sol e alpargatas.',
      'sunny': 'Ensolarado', 'rainy': 'Chuvoso', 'cloudy': 'Nublado', 'snowy': 'Nevado', 'partly_cloudy': 'Parcialmente nublado',
      'foggy': 'Nevoeiro', 'stormy': 'Tempestuoso', 'humid': 'Úmido', 'frosty': 'Gelado', 'spring_evening': 'Noite de primavera',
      'outfit_foggy_m': 'Casacão, jeans escuro, botas de couro e gorro.',
      'outfit_foggy_f': 'Trench elegante, calça de lã, botins e cachecol quente.',
      'outfit_stormy_m': 'Jaqueta de tempestade, calça cargo, botas de chuva e guarda-chuva.',
      'outfit_stormy_f': 'Parka impermeável, leggings quentes, botas altas e guarda-chuva resistente.',
      'outfit_humid_m': 'Camisa de linho, bermuda, sandálias abertas e óculos de sol.',
      'outfit_humid_f': 'Vestido de algodão leve, saia leve, sandálias e chapéu de sol.',
      'outfit_frosty_m': 'Jaqueta puffer, calça térmica, botas isoladas e luvas forradas.',
      'outfit_frosty_f': 'Casaco puffer luxo, leggings quentes, botas com pelo e cachecol cashmere.',
      'outfit_spring_eve_m': 'Jaqueta leve, chinos slim, mocassins de camurça e relógio elegante.',
      'outfit_spring_eve_f': 'Cardigan macio, vestido floral midi, sapatilhas e clutch.',
      'foggy_m': 'Casacão, jeans escuro, botas de couro e gorro.',
      'foggy_f': 'Trench elegante, calça de lã, botins e cachecol quente.',
      'stormy_m': 'Jaqueta de tempestade, calça cargo, botas de chuva e guarda-chuva.',
      'stormy_f': 'Parka impermeável, leggings quentes, botas altas e guarda-chuva resistente.',
      'humid_m': 'Camisa de linho, bermuda, sandálias abertas e óculos de sol.',
      'humid_f': 'Vestido de algodão leve, saia leve, sandálias e chapéu de sol.',
      'frosty_m': 'Jaqueta puffer, calça térmica, botas isoladas e luvas forradas.',
      'frosty_f': 'Casaco puffer luxo, leggings quentes, botas com pelo e cachecol cashmere.',
      'spring_evening_m': 'Jaqueta leve, chinos slim, mocassins de camurça e relógio elegante.',
      'spring_evening_f': 'Cardigan macio, vestido floral midi, sapatilhas e clutch.',
      'sunny_m': 'Camisa de linho, bermuda, óculos de sol e tênis leves.',
      'sunny_f': 'Vestido de verão, chapéu, óculos de sol e alpargatas.',
      'rainy_m': 'Parka impermeável, moletom, calça cargo e botas de chuva.',
      'rainy_f': 'Trench com cinto, vestido de tricô, meia-calça e botas Chelsea.',
      'cloudy_m': 'Jaqueta bomber, suéter, chinos e tênis.',
      'cloudy_f': 'Cardigan, blusa, saia midi e mocassins.',
      'snowy_m': 'Casacão de inverno, camadas térmicas, cachecol, luvas e botas de neve.',
      'snowy_f': 'Jaqueta puffer elegante, cachecol cashmere, leggings quentes e botas forradas.',
      'partly_cloudy_m': 'Camisa social, chinos leves e tênis brancos.',
      'partly_cloudy_f': 'Blusa fluida, calça de linho e sandálias de tira.',
      'item_peacoat': 'Casacão', 'item_dark_jeans': 'Jeans escuro', 'item_leather_boots': 'Botas de couro',
      'item_beanie': 'Gorro', 'item_trench': 'Trench', 'item_wool_pants': 'Calça de lã',
      'item_ankle_boots': 'Botins', 'item_scarf': 'Cachecol', 'item_storm_jacket': 'Jaqueta tempestade',
      'item_cargo_pants': 'Calça cargo', 'item_rain_boots': 'Botas de chuva', 'item_umbrella': 'Guarda-chuva',
      'item_rain_parka': 'Parka chuva', 'item_leggings': 'Leggings', 'item_waterproof_boots': 'Botas impermeáveis',
      'item_linen_shirt': 'Camisa de linho', 'item_shorts': 'Bermuda', 'item_sandals': 'Sandálias',
      'item_sunglasses': 'Óculos de sol', 'item_cotton_dress': 'Vestido algodão', 'item_light_skirt': 'Saia leve',
      'item_open_sandals': 'Sandálias abertas', 'item_sun_hat': 'Chapéu de sol', 'item_down_jacket': 'Jaqueta puffer',
      'item_thermal_pants': 'Calça térmica', 'item_insulated_boots': 'Botas isoladas', 'item_gloves': 'Luvas',
      'item_puffer_coat': 'Casaco puffer', 'item_warm_leggings': 'Leggings quentes', 'item_fur_boots': 'Botas com pelo',
      'item_cashmere_scarf': 'Cachecol cashmere', 'item_light_jacket': 'Jaqueta leve', 'item_chinos': 'Chinos',
      'item_loafers': 'Mocassins', 'item_watch': 'Relógio', 'item_cardigan': 'Cardigan',
      'item_floral_dress': 'Vestido floral', 'item_ballet_flats': 'Sapatilhas', 'item_clutch': 'Clutch',
      'item_winter_coat': 'Casaco inverno', 'item_thermal_layers': 'Camadas térmicas', 'item_snow_boots': 'Botas de neve',
      'item_puffer_jacket': 'Jaqueta puffer', 'item_wool_overcoat': 'Sobretudo lã', 'item_sweater': 'Suéter',
      'item_turtleneck': 'Gola alta', 'item_slim_pants': 'Calça slim',
      'item_waterproof_parka': 'Parka impermeável', 'item_hoodie': 'Moletom', 'item_knit_dress': 'Vestido tricô',
      'item_chelsea_boots': 'Botas Chelsea', 'item_tights': 'Meia-calça', 'item_bomber': 'Jaqueta bomber',
      'item_sneakers': 'Tênis', 'item_blouse': 'Blusa', 'item_midi_skirt': 'Saia midi',
      'item_rain_jacket': 'Jaqueta chuva', 'item_tshirt': 'Camiseta', 'item_waterproof_shoes': 'Sapatos impermeáveis',
      'item_jeans': 'Jeans', 'item_raincoat': 'Capa de chuva', 'item_rain_flats': 'Sapatilhas impermeáveis',
      'item_button_shirt': 'Camisa social', 'item_white_sneakers': 'Tênis brancos',
      'item_linen_pants': 'Calça de linho', 'item_strappy_sandals': 'Sandálias de tira',
      'item_quick_dry_shorts': 'Bermuda secagem rápida', 'item_sport_sandals': 'Sandálias esportivas',
      'item_summer_dress': 'Vestido de verão', 'item_light_cardigan': 'Cardigan leve',
      'item_waterproof_sandals': 'Sandálias impermeáveis', 'item_breathable_sneakers': 'Tênis leves',
      'item_sundress': 'Vestido de verão', 'item_espadrilles': 'Alpargatas',
    },
    'ja': {
      'home': 'ホーム', 'forecast': '予報', 'favourites': 'お気に入り', 'settings': '設定',
      'seven_day_forecast': '7日間予報', 'five_day_forecast': '7日間予報',
      'hourly_forecast': '1時間ごとの予報',
      'search_city': '都市を検索...', 'enter_city': '都市名を入力してください。',
      'city_not_found': '都市が見つかりません。', 'humidity': '湿度', 'wind': '風速',
      'outfit_suggestion': 'コーデ提案', 'country': '国', 'city': '都市', 'district': '地区', 'language': '言語',
      'customize': '設定をカスタマイズ',
      'temp_unit': '温度単位', 'celsius': '摂氏 (°C)', 'fahrenheit': '華氏 (°F)',
      'favourite_cities': 'お気に入りの都市', 'saved_cities_count': '件の都市',
      'no_favourites': 'お気に入りの都市がありません。\nホーム画面のハートアイコンをタップ。',
      'currently_viewing': '表示中', 'tap_to_view': 'タップして表示',
      'version': 'バージョン', 'dark_mode': 'ダークモード', 'light_mode': 'ライトモード', 'appearance': '外観',
      'male': 'メンズ', 'female': 'レディース', 'gender': 'スタイル',
      'seasonal_colors': '季節の色', 'color_palette': 'カラーパレット',
      'winter': '冬', 'spring': '春', 'summer': '夏', 'autumn': '秋', 'now': '現在',
      'mon': '月', 'tue': '火', 'wed': '水', 'thu': '木', 'fri': '金', 'sat': '土', 'sun': '日',
      'clr_burgundy': 'バーガンディ', 'clr_navy': 'ネイビー', 'clr_forest': 'フォレスト', 'clr_charcoal': 'チャコール', 'clr_ivory': 'アイボリー',
      'clr_burnt_orange': 'バーントオレンジ', 'clr_mustard': 'マスタード', 'clr_olive': 'オリーブ', 'clr_saddle_brown': 'ブラウン',
      'clr_pastel_pink': 'パステルピンク', 'clr_lavender': 'ラベンダー', 'clr_mint': 'ミント', 'clr_soft_yellow': 'ソフトイエロー', 'clr_sky_blue': 'スカイブルー',
      'clr_coral': 'コーラル', 'clr_turquoise': 'ターコイズ', 'clr_white': 'ホワイト', 'clr_sand': 'サンド', 'clr_gold': 'ゴールド',
      'outfit_snow_m': '厚手のコート、サーマルインナー、マフラー、手袋、スノーブーツ。',
      'outfit_snow_f': 'エレガントなダウン、カシミヤマフラー、暖かいレギンス、ファーブーツ。',
      'outfit_heavy_cold_m': 'ウールコート、レイヤードニット、ダークジーンズ、レザーブーツ。',
      'outfit_heavy_cold_f': 'ロングトレンチ、タートルネック、スリムパンツ、アンクルブーツ。',
      'outfit_cool_rain_m': '防水パーカー、パーカー、カーゴパンツ、レインブーツ。',
      'outfit_cool_rain_f': 'ベルト付きトレンチ、ニットワンピ、タイツ、チェルシーブーツ。',
      'outfit_cool_m': 'ボンバージャケット、ニット、チノパン、スニーカー。',
      'outfit_cool_f': 'カーディガン、ブラウス、ミディスカート、ローファー。',
      'outfit_mild_rain_m': '軽いレインジャケット、Tシャツ、ジーンズ、防水シューズ。',
      'outfit_mild_rain_f': '軽いレインコート、花柄ワンピ、防水フラットシューズ。',
      'outfit_mild_m': 'ボタンシャツ、軽いチノパン、白スニーカー。',
      'outfit_mild_f': 'ふんわりブラウス、リネンパンツ、ストラップサンダル。',
      'outfit_hot_rain_m': '速乾ショーツ、Tシャツ、スポーツサンダルと傘。',
      'outfit_hot_rain_f': '爽やかなサマードレス、軽いカーディガン、防水サンダル。',
      'outfit_hot_m': 'リネンシャツ、ショーツ、サングラス、通気性スニーカー。',
      'outfit_hot_f': 'サンドレス、つば広帽子、サングラス、エスパドリーユ。',
      'sunny': '晴れ', 'rainy': '雨', 'cloudy': '曇り', 'snowy': '雪', 'partly_cloudy': 'ところにより曇り',
      'foggy': '霧', 'stormy': '嵐', 'humid': '蒸し暑い', 'frosty': '極寒', 'spring_evening': '春の夕べ',
      'outfit_foggy_m': 'ピーコート、ダークジーンズ、レザーブーツ、ニット帽。',
      'outfit_foggy_f': 'エレガントなトレンチ、ウールパンツ、アンクルブーツ、暖かいマフラー。',
      'outfit_stormy_m': 'ストームジャケット、カーゴパンツ、レインブーツ、傘。',
      'outfit_stormy_f': '防水パーカー、暖かいレギンス、ハイブーツ、頑丈な傘。',
      'outfit_humid_m': 'リネンシャツ、ショーツ、オープンサンダル、サングラス。',
      'outfit_humid_f': 'コットンワンピース、軽いスカート、サンダル、日よけ帽。',
      'outfit_frosty_m': 'ダウンジャケット、サーマルパンツ、断熱ブーツ、裏起毛手袋。',
      'outfit_frosty_f': '高級ダウンコート、暖かいレギンス、ファーブーツ、カシミヤマフラー。',
      'outfit_spring_eve_m': '軽いジャケット、スリムチノ、スエードローファー、おしゃれな時計。',
      'outfit_spring_eve_f': 'ソフトカーディガン、花柄ミディワンピ、バレエシューズ、クラッチ。',
      'foggy_m': 'ピーコート、ダークジーンズ、レザーブーツ、ニット帽。',
      'foggy_f': 'エレガントなトレンチ、ウールパンツ、アンクルブーツ、暖かいマフラー。',
      'stormy_m': 'ストームジャケット、カーゴパンツ、レインブーツ、傘。',
      'stormy_f': '防水パーカー、暖かいレギンス、ハイブーツ、頑丈な傘。',
      'humid_m': 'リネンシャツ、ショーツ、オープンサンダル、サングラス。',
      'humid_f': 'コットンワンピース、軽いスカート、サンダル、日よけ帽。',
      'frosty_m': 'ダウンジャケット、サーマルパンツ、断熱ブーツ、裏起毛手袋。',
      'frosty_f': '高級ダウンコート、暖かいレギンス、ファーブーツ、カシミヤマフラー。',
      'spring_evening_m': '軽いジャケット、スリムチノ、スエードローファー、おしゃれな時計。',
      'spring_evening_f': 'ソフトカーディガン、花柄ミディワンピ、バレエシューズ、クラッチ。',
      'sunny_m': 'リネンシャツ、ショーツ、サングラス、通気性スニーカー。',
      'sunny_f': 'サンドレス、つば広帽子、サングラス、エスパドリーユ。',
      'rainy_m': '防水パーカー、パーカー、カーゴパンツ、レインブーツ。',
      'rainy_f': 'ベルト付きトレンチ、ニットワンピ、タイツ、チェルシーブーツ。',
      'cloudy_m': 'ボンバージャケット、ニット、チノパン、スニーカー。',
      'cloudy_f': 'カーディガン、ブラウス、ミディスカート、ローファー。',
      'snowy_m': '厚手のコート、サーマルインナー、マフラー、手袋、スノーブーツ。',
      'snowy_f': 'エレガントなダウン、カシミヤマフラー、暖かいレギンス、ファーブーツ。',
      'partly_cloudy_m': 'ボタンシャツ、軽いチノパン、白スニーカー。',
      'partly_cloudy_f': 'ふんわりブラウス、リネンパンツ、ストラップサンダル。',
      'item_peacoat': 'ピーコート', 'item_dark_jeans': 'ダークジーンズ', 'item_leather_boots': 'レザーブーツ',
      'item_beanie': 'ニット帽', 'item_trench': 'トレンチコート', 'item_wool_pants': 'ウールパンツ',
      'item_ankle_boots': 'アンクルブーツ', 'item_scarf': 'マフラー', 'item_storm_jacket': 'ストームジャケット',
      'item_cargo_pants': 'カーゴパンツ', 'item_rain_boots': 'レインブーツ', 'item_umbrella': '傘',
      'item_rain_parka': 'レインパーカー', 'item_leggings': 'レギンス', 'item_waterproof_boots': '防水ブーツ',
      'item_linen_shirt': 'リネンシャツ', 'item_shorts': 'ショーツ', 'item_sandals': 'サンダル',
      'item_sunglasses': 'サングラス', 'item_cotton_dress': 'コットンワンピ', 'item_light_skirt': '軽いスカート',
      'item_open_sandals': 'オープンサンダル', 'item_sun_hat': '日よけ帽', 'item_down_jacket': 'ダウンジャケット',
      'item_thermal_pants': 'サーマルパンツ', 'item_insulated_boots': '断熱ブーツ', 'item_gloves': '手袋',
      'item_puffer_coat': 'ダウンコート', 'item_warm_leggings': '暖かいレギンス', 'item_fur_boots': 'ファーブーツ',
      'item_cashmere_scarf': 'カシミヤマフラー', 'item_light_jacket': '軽いジャケット', 'item_chinos': 'チノパン',
      'item_loafers': 'ローファー', 'item_watch': '時計', 'item_cardigan': 'カーディガン',
      'item_floral_dress': '花柄ワンピ', 'item_ballet_flats': 'バレエシューズ', 'item_clutch': 'クラッチ',
      'item_winter_coat': 'ウィンターコート', 'item_thermal_layers': 'サーマルインナー', 'item_snow_boots': 'スノーブーツ',
      'item_puffer_jacket': 'ダウンジャケット', 'item_wool_overcoat': 'ウールコート', 'item_sweater': 'ニット',
      'item_turtleneck': 'タートルネック', 'item_slim_pants': 'スリムパンツ',
      'item_waterproof_parka': '防水パーカー', 'item_hoodie': 'パーカー', 'item_knit_dress': 'ニットワンピ',
      'item_chelsea_boots': 'チェルシーブーツ', 'item_tights': 'タイツ', 'item_bomber': 'ボンバージャケット',
      'item_sneakers': 'スニーカー', 'item_blouse': 'ブラウス', 'item_midi_skirt': 'ミディスカート',
      'item_rain_jacket': 'レインジャケット', 'item_tshirt': 'Tシャツ', 'item_waterproof_shoes': '防水シューズ',
      'item_jeans': 'ジーンズ', 'item_raincoat': 'レインコート', 'item_rain_flats': '防水フラット',
      'item_button_shirt': 'ボタンシャツ', 'item_white_sneakers': '白スニーカー',
      'item_linen_pants': 'リネンパンツ', 'item_strappy_sandals': 'ストラップサンダル',
      'item_quick_dry_shorts': '速乾ショーツ', 'item_sport_sandals': 'スポーツサンダル',
      'item_summer_dress': 'サマードレス', 'item_light_cardigan': '軽いカーディガン',
      'item_waterproof_sandals': '防水サンダル', 'item_breathable_sneakers': '通気性スニーカー',
      'item_sundress': 'サンドレス', 'item_espadrilles': 'エスパドリーユ',
    },
    'zh': {
      'home': '首页', 'forecast': '预报', 'favourites': '收藏', 'settings': '设置',
      'seven_day_forecast': '7天预报', 'five_day_forecast': '7天预报',
      'hourly_forecast': '逐时预报',
      'search_city': '搜索城市...', 'enter_city': '请输入城市名称。',
      'city_not_found': '未找到城市。', 'humidity': '湿度', 'wind': '风速',
      'outfit_suggestion': '穿搭建议', 'country': '国家', 'city': '城市', 'district': '区域', 'language': '语言',
      'customize': '自定义您的体验',
      'temp_unit': '温度单位', 'celsius': '摄氏 (°C)', 'fahrenheit': '华氏 (°F)',
      'favourite_cities': '收藏城市', 'saved_cities_count': '个已保存城市',
      'no_favourites': '暂无收藏城市。\n在首页点击心形图标。',
      'currently_viewing': '当前查看', 'tap_to_view': '点击查看',
      'version': '版本', 'dark_mode': '深色模式', 'light_mode': '浅色模式', 'appearance': '外观',
      'male': '男士', 'female': '女士', 'gender': '风格',
      'seasonal_colors': '季节色彩', 'color_palette': '色卡',
      'winter': '冬季', 'spring': '春季', 'summer': '夏季', 'autumn': '秋季', 'now': '现在',
      'mon': '周一', 'tue': '周二', 'wed': '周三', 'thu': '周四', 'fri': '周五', 'sat': '周六', 'sun': '周日',
      'clr_burgundy': '酒红', 'clr_navy': '藏青', 'clr_forest': '森林绿', 'clr_charcoal': '炭灰', 'clr_ivory': '象牙白',
      'clr_burnt_orange': '焦橙', 'clr_mustard': '芥末黄', 'clr_olive': '橄榄绿', 'clr_saddle_brown': '棕色',
      'clr_pastel_pink': '粉彩粉', 'clr_lavender': '薰衣草', 'clr_mint': '薄荷绿', 'clr_soft_yellow': '柔黄', 'clr_sky_blue': '天蓝',
      'clr_coral': '珊瑚', 'clr_turquoise': '绿松石', 'clr_white': '白色', 'clr_sand': '沙色', 'clr_gold': '金色',
      'outfit_snow_m': '厚重冬大衣、保暖内衣、围巾、手套和雪地靴。',
      'outfit_snow_f': '优雅羽绒服、羊绒围巾、保暖打底裤和毛绒靴。',
      'outfit_heavy_cold_m': '羊毛大衣、叠穿毛衣、深色牛仔裤和皮靴。',
      'outfit_heavy_cold_f': '长款风衣、高领毛衣、修身裤和短靴。',
      'outfit_cool_rain_m': '防水派克大衣、卫衣、工装裤和雨靴。',
      'outfit_cool_rain_f': '腰带风衣、针织连衣裙、连裤袜和切尔西靴。',
      'outfit_cool_m': '飞行夹克、圆领毛衣、休闲裤和运动鞋。',
      'outfit_cool_f': '开衫、衬衫、半身裙和乐福鞋。',
      'outfit_mild_rain_m': '轻便雨衣、T恤、牛仔裤和防水鞋。',
      'outfit_mild_rain_f': '轻薄雨衣、碎花裙和防水平底鞋。',
      'outfit_mild_m': '衬衫、轻便休闲裤和白色运动鞋。',
      'outfit_mild_f': '飘逸衬衫、亚麻裤和绑带凉鞋。',
      'outfit_hot_rain_m': '速干短裤、T恤和运动凉鞋加雨伞。',
      'outfit_hot_rain_f': '清凉夏裙、薄开衫和防水凉鞋。',
      'outfit_hot_m': '亚麻衬衫、短裤、墨镜和透气运动鞋。',
      'outfit_hot_f': '太阳裙、宽檐帽、墨镜和草编鞋。',
      'sunny': '晴天', 'rainy': '雨天', 'cloudy': '阴天', 'snowy': '雪天', 'partly_cloudy': '多云',
      'foggy': '雾天', 'stormy': '暴风雨', 'humid': '闷热', 'frosty': '严寒', 'spring_evening': '春夜',
      'outfit_foggy_m': '海军大衣、深色牛仔裤、皮靴和毛线帽。',
      'outfit_foggy_f': '优雅风衣、羊毛裤、短靴和保暖围巾。',
      'outfit_stormy_m': '暴风夹克、工装裤、雨靴和雨伞。',
      'outfit_stormy_f': '防水派克、保暖打底裤、高筒靴和结实雨伞。',
      'outfit_humid_m': '亚麻衬衫、短裤、凉鞋和墨镜。',
      'outfit_humid_f': '棉质连衣裙、轻薄裙、凉鞋和遮阳帽。',
      'outfit_frosty_m': '羽绒夹克、保暖裤、隔热靴和内衬手套。',
      'outfit_frosty_f': '奢华羽绒服、保暖打底裤、毛绒靴和羊绒围巾。',
      'outfit_spring_eve_m': '轻薄夹克、修身休闲裤、麂皮乐福鞋和精致手表。',
      'outfit_spring_eve_f': '柔软开衫、碎花连衣裙、芭蕾平底鞋和晚宴包。',
      'foggy_m': '海军大衣、深色牛仔裤、皮靴和毛线帽。',
      'foggy_f': '优雅风衣、羊毛裤、短靴和保暖围巾。',
      'stormy_m': '暴风夹克、工装裤、雨靴和雨伞。',
      'stormy_f': '防水派克、保暖打底裤、高筒靴和结实雨伞。',
      'humid_m': '亚麻衬衫、短裤、凉鞋和墨镜。',
      'humid_f': '棉质连衣裙、轻薄裙、凉鞋和遮阳帽。',
      'frosty_m': '羽绒夹克、保暖裤、隔热靴和内衬手套。',
      'frosty_f': '奢华羽绒服、保暖打底裤、毛绒靴和羊绒围巾。',
      'spring_evening_m': '轻薄夹克、修身休闲裤、麂皮乐福鞋和精致手表。',
      'spring_evening_f': '柔软开衫、碎花连衣裙、芭蕾平底鞋和晚宴包。',
      'sunny_m': '亚麻衬衫、短裤、墨镜和透气运动鞋。',
      'sunny_f': '太阳裙、宽檐帽、墨镜和草编鞋。',
      'rainy_m': '防水派克大衣、卫衣、工装裤和雨靴。',
      'rainy_f': '腰带风衣、针织连衣裙、连裤袜和切尔西靴。',
      'cloudy_m': '飞行夹克、圆领毛衣、休闲裤和运动鞋。',
      'cloudy_f': '开衫、衬衫、半身裙和乐福鞋。',
      'snowy_m': '厚重冬大衣、保暖内衣、围巾、手套和雪地靴。',
      'snowy_f': '优雅羽绒服、羊绒围巾、保暖打底裤和毛绒靴。',
      'partly_cloudy_m': '衬衫、轻便休闲裤和白色运动鞋。',
      'partly_cloudy_f': '飘逸衬衫、亚麻裤和绑带凉鞋。',
      'item_peacoat': '海军大衣', 'item_dark_jeans': '深色牛仔裤', 'item_leather_boots': '皮靴',
      'item_beanie': '毛线帽', 'item_trench': '风衣', 'item_wool_pants': '羊毛裤',
      'item_ankle_boots': '短靴', 'item_scarf': '围巾', 'item_storm_jacket': '暴风夹克',
      'item_cargo_pants': '工装裤', 'item_rain_boots': '雨靴', 'item_umbrella': '雨伞',
      'item_rain_parka': '雨衣派克', 'item_leggings': '打底裤', 'item_waterproof_boots': '防水靴',
      'item_linen_shirt': '亚麻衬衫', 'item_shorts': '短裤', 'item_sandals': '凉鞋',
      'item_sunglasses': '墨镜', 'item_cotton_dress': '棉质裙', 'item_light_skirt': '轻薄裙',
      'item_open_sandals': '凉鞋', 'item_sun_hat': '遮阳帽', 'item_down_jacket': '羽绒夹克',
      'item_thermal_pants': '保暖裤', 'item_insulated_boots': '隔热靴', 'item_gloves': '手套',
      'item_puffer_coat': '羽绒服', 'item_warm_leggings': '保暖打底裤', 'item_fur_boots': '毛绒靴',
      'item_cashmere_scarf': '羊绒围巾', 'item_light_jacket': '轻薄夹克', 'item_chinos': '休闲裤',
      'item_loafers': '乐福鞋', 'item_watch': '手表', 'item_cardigan': '开衫',
      'item_floral_dress': '碎花裙', 'item_ballet_flats': '芭蕾平底鞋', 'item_clutch': '晚宴包',
      'item_winter_coat': '冬大衣', 'item_thermal_layers': '保暖内衣', 'item_snow_boots': '雪地靴',
      'item_puffer_jacket': '羽绒服', 'item_wool_overcoat': '羊毛大衣', 'item_sweater': '毛衣',
      'item_turtleneck': '高领毛衣', 'item_slim_pants': '修身裤',
      'item_waterproof_parka': '防水派克', 'item_hoodie': '卫衣', 'item_knit_dress': '针织裙',
      'item_chelsea_boots': '切尔西靴', 'item_tights': '连裤袜', 'item_bomber': '飞行夹克',
      'item_sneakers': '运动鞋', 'item_blouse': '衬衫', 'item_midi_skirt': '半身裙',
      'item_rain_jacket': '雨衣', 'item_tshirt': 'T恤', 'item_waterproof_shoes': '防水鞋',
      'item_jeans': '牛仔裤', 'item_raincoat': '雨衣', 'item_rain_flats': '防水平底鞋',
      'item_button_shirt': '衬衫', 'item_white_sneakers': '白色运动鞋',
      'item_linen_pants': '亚麻裤', 'item_strappy_sandals': '绑带凉鞋',
      'item_quick_dry_shorts': '速干短裤', 'item_sport_sandals': '运动凉鞋',
      'item_summer_dress': '夏裙', 'item_light_cardigan': '薄开衫',
      'item_waterproof_sandals': '防水凉鞋', 'item_breathable_sneakers': '透气运动鞋',
      'item_sundress': '太阳裙', 'item_espadrilles': '草编鞋',
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

  // ═══════════════════════════════════════════════════════════════════
  // WEATHER SCENARIOS — preset weather states for the scenario switcher
  // ═══════════════════════════════════════════════════════════════════

  static const List<WeatherScenario> weatherScenarios = [
    WeatherScenario(
      key: 'sunny', labelKey: 'sunny', icon: '☀️',
      temp: 28, condition: 'Sunny', humidity: 35, windSpeed: 8,
      darkGradient: [0xFF0F1923, 0xFF1B3A5C, 0xFF2980B9],
      lightGradient: [0xFF2E86DE, 0xFF54A0FF, 0xFF8CC0FF],
      meshColors: [0xFF42A5F5, 0xFF64B5F6, 0xFFFFB74D, 0xFFFFF176],
      womenOutfit: [OutfitItem(nameKey: 'item_sundress', category: OutfitCategory.top), OutfitItem(nameKey: 'item_espadrilles', category: OutfitCategory.shoes), OutfitItem(nameKey: 'item_sun_hat', category: OutfitCategory.headwear), OutfitItem(nameKey: 'item_sunglasses', category: OutfitCategory.accessory)],
      menOutfit: [OutfitItem(nameKey: 'item_linen_shirt', category: OutfitCategory.top), OutfitItem(nameKey: 'item_shorts', category: OutfitCategory.bottom), OutfitItem(nameKey: 'item_breathable_sneakers', category: OutfitCategory.shoes), OutfitItem(nameKey: 'item_sunglasses', category: OutfitCategory.accessory)],
    ),
    WeatherScenario(
      key: 'rainy', labelKey: 'rainy', icon: '🌧️',
      temp: 12, condition: 'Rainy', humidity: 85, windSpeed: 20,
      darkGradient: [0xFF0D1117, 0xFF1A2332, 0xFF2D3748],
      lightGradient: [0xFF636E72, 0xFF95A5A6, 0xFFBDC3C7],
      meshColors: [0xFF37474F, 0xFF455A64, 0xFF546E7A, 0xFF607D8B],
      womenOutfit: [OutfitItem(nameKey: 'item_trench', category: OutfitCategory.outerwear), OutfitItem(nameKey: 'item_knit_dress', category: OutfitCategory.top), OutfitItem(nameKey: 'item_chelsea_boots', category: OutfitCategory.shoes), OutfitItem(nameKey: 'item_umbrella', category: OutfitCategory.accessory)],
      menOutfit: [OutfitItem(nameKey: 'item_waterproof_parka', category: OutfitCategory.outerwear), OutfitItem(nameKey: 'item_hoodie', category: OutfitCategory.top), OutfitItem(nameKey: 'item_rain_boots', category: OutfitCategory.shoes), OutfitItem(nameKey: 'item_umbrella', category: OutfitCategory.accessory)],
    ),
    WeatherScenario(
      key: 'cloudy', labelKey: 'cloudy', icon: '☁️',
      temp: 18, condition: 'Cloudy', humidity: 60, windSpeed: 14,
      darkGradient: [0xFF1A1F2E, 0xFF2C3E50, 0xFF4A5568],
      lightGradient: [0xFF74B9FF, 0xFFA8D8EA, 0xFFD6EAF8],
      meshColors: [0xFF5C6BC0, 0xFF7986CB, 0xFF9FA8DA, 0xFFC5CAE9],
      womenOutfit: [OutfitItem(nameKey: 'item_cardigan', category: OutfitCategory.outerwear), OutfitItem(nameKey: 'item_blouse', category: OutfitCategory.top), OutfitItem(nameKey: 'item_loafers', category: OutfitCategory.shoes), OutfitItem(nameKey: 'item_midi_skirt', category: OutfitCategory.bottom)],
      menOutfit: [OutfitItem(nameKey: 'item_bomber', category: OutfitCategory.outerwear), OutfitItem(nameKey: 'item_sweater', category: OutfitCategory.top), OutfitItem(nameKey: 'item_sneakers', category: OutfitCategory.shoes), OutfitItem(nameKey: 'item_chinos', category: OutfitCategory.bottom)],
    ),
    WeatherScenario(
      key: 'snowy', labelKey: 'snowy', icon: '❄️',
      temp: -3, condition: 'Snowy', humidity: 80, windSpeed: 18,
      darkGradient: [0xFF3A3D5C, 0xFF6B7394, 0xFF8E9EAB],
      lightGradient: [0xFFBDC3C7, 0xFFD5DDE8, 0xFFECF0F1],
      meshColors: [0xFF90A4AE, 0xFFB0BEC5, 0xFFCFD8DC, 0xFFECEFF1],
      womenOutfit: [OutfitItem(nameKey: 'item_puffer_jacket', category: OutfitCategory.outerwear), OutfitItem(nameKey: 'item_warm_leggings', category: OutfitCategory.bottom), OutfitItem(nameKey: 'item_fur_boots', category: OutfitCategory.shoes), OutfitItem(nameKey: 'item_cashmere_scarf', category: OutfitCategory.accessory)],
      menOutfit: [OutfitItem(nameKey: 'item_winter_coat', category: OutfitCategory.outerwear), OutfitItem(nameKey: 'item_thermal_layers', category: OutfitCategory.top), OutfitItem(nameKey: 'item_snow_boots', category: OutfitCategory.shoes), OutfitItem(nameKey: 'item_gloves', category: OutfitCategory.accessory)],
    ),
    WeatherScenario(
      key: 'partly_cloudy', labelKey: 'partly_cloudy', icon: '⛅',
      temp: 22, condition: 'Partly Cloudy', humidity: 50, windSpeed: 10,
      darkGradient: [0xFF1A1F2E, 0xFF2C3E50, 0xFF4A5568],
      lightGradient: [0xFF74B9FF, 0xFFA8D8EA, 0xFFD6EAF8],
      meshColors: [0xFF64B5F6, 0xFF90CAF9, 0xFFBBDEFB, 0xFFE3F2FD],
      womenOutfit: [OutfitItem(nameKey: 'item_blouse', category: OutfitCategory.top), OutfitItem(nameKey: 'item_linen_pants', category: OutfitCategory.bottom), OutfitItem(nameKey: 'item_strappy_sandals', category: OutfitCategory.shoes)],
      menOutfit: [OutfitItem(nameKey: 'item_button_shirt', category: OutfitCategory.top), OutfitItem(nameKey: 'item_chinos', category: OutfitCategory.bottom), OutfitItem(nameKey: 'item_white_sneakers', category: OutfitCategory.shoes)],
    ),
    // ── NEW SCENARIOS ──
    WeatherScenario(
      key: 'foggy', labelKey: 'foggy', icon: '🌫️',
      temp: 8, condition: 'Foggy', humidity: 92, windSpeed: 5,
      darkGradient: [0xFF37474F, 0xFF546E7A, 0xFF78909C],
      lightGradient: [0xFFB0BEC5, 0xFFCFD8DC, 0xFFECEFF1],
      meshColors: [0xFF9E9E9E, 0xFFBDBDBD, 0xFFE0E0E0, 0xFFCFD8DC],
      womenOutfit: [OutfitItem(nameKey: 'item_trench', category: OutfitCategory.outerwear), OutfitItem(nameKey: 'item_wool_pants', category: OutfitCategory.bottom), OutfitItem(nameKey: 'item_ankle_boots', category: OutfitCategory.shoes), OutfitItem(nameKey: 'item_scarf', category: OutfitCategory.accessory)],
      menOutfit: [OutfitItem(nameKey: 'item_peacoat', category: OutfitCategory.outerwear), OutfitItem(nameKey: 'item_dark_jeans', category: OutfitCategory.bottom), OutfitItem(nameKey: 'item_leather_boots', category: OutfitCategory.shoes), OutfitItem(nameKey: 'item_beanie', category: OutfitCategory.headwear)],
    ),
    WeatherScenario(
      key: 'stormy', labelKey: 'stormy', icon: '⛈️',
      temp: 12, condition: 'Stormy', humidity: 90, windSpeed: 45,
      darkGradient: [0xFF0D0D1A, 0xFF1A1A2E, 0xFF2D1B4E],
      lightGradient: [0xFF455A64, 0xFF607D8B, 0xFF90A4AE],
      meshColors: [0xFF1A1A2E, 0xFF16213E, 0xFF0F3460, 0xFF533483],
      womenOutfit: [OutfitItem(nameKey: 'item_rain_parka', category: OutfitCategory.outerwear), OutfitItem(nameKey: 'item_leggings', category: OutfitCategory.bottom), OutfitItem(nameKey: 'item_waterproof_boots', category: OutfitCategory.shoes), OutfitItem(nameKey: 'item_umbrella', category: OutfitCategory.accessory)],
      menOutfit: [OutfitItem(nameKey: 'item_storm_jacket', category: OutfitCategory.outerwear), OutfitItem(nameKey: 'item_cargo_pants', category: OutfitCategory.bottom), OutfitItem(nameKey: 'item_rain_boots', category: OutfitCategory.shoes), OutfitItem(nameKey: 'item_umbrella', category: OutfitCategory.accessory)],
    ),
    WeatherScenario(
      key: 'humid', labelKey: 'humid', icon: '💧',
      temp: 32, condition: 'Humid', humidity: 88, windSpeed: 6,
      darkGradient: [0xFF1B3A2D, 0xFF2E5B3F, 0xFF3E7251],
      lightGradient: [0xFF66BB6A, 0xFF81C784, 0xFFA5D6A7],
      meshColors: [0xFF2E7D32, 0xFF66BB6A, 0xFF81C784, 0xFFA5D6A7],
      womenOutfit: [OutfitItem(nameKey: 'item_cotton_dress', category: OutfitCategory.top), OutfitItem(nameKey: 'item_light_skirt', category: OutfitCategory.bottom), OutfitItem(nameKey: 'item_open_sandals', category: OutfitCategory.shoes), OutfitItem(nameKey: 'item_sun_hat', category: OutfitCategory.headwear)],
      menOutfit: [OutfitItem(nameKey: 'item_linen_shirt', category: OutfitCategory.top), OutfitItem(nameKey: 'item_shorts', category: OutfitCategory.bottom), OutfitItem(nameKey: 'item_sandals', category: OutfitCategory.shoes), OutfitItem(nameKey: 'item_sunglasses', category: OutfitCategory.accessory)],
    ),
    WeatherScenario(
      key: 'frosty', labelKey: 'frosty', icon: '🥶',
      temp: -8, condition: 'Frosty', humidity: 70, windSpeed: 22,
      darkGradient: [0xFF1A2A3A, 0xFF2C4A6A, 0xFF4A7A9A],
      lightGradient: [0xFF81D4FA, 0xFFB3E5FC, 0xFFE1F5FE],
      meshColors: [0xFFB3E5FC, 0xFF81D4FA, 0xFFE1F5FE, 0xFFCCE5FF],
      womenOutfit: [OutfitItem(nameKey: 'item_puffer_coat', category: OutfitCategory.outerwear), OutfitItem(nameKey: 'item_warm_leggings', category: OutfitCategory.bottom), OutfitItem(nameKey: 'item_fur_boots', category: OutfitCategory.shoes), OutfitItem(nameKey: 'item_cashmere_scarf', category: OutfitCategory.accessory)],
      menOutfit: [OutfitItem(nameKey: 'item_down_jacket', category: OutfitCategory.outerwear), OutfitItem(nameKey: 'item_thermal_pants', category: OutfitCategory.bottom), OutfitItem(nameKey: 'item_insulated_boots', category: OutfitCategory.shoes), OutfitItem(nameKey: 'item_gloves', category: OutfitCategory.accessory)],
    ),
    WeatherScenario(
      key: 'spring_evening', labelKey: 'spring_evening', icon: '🌸',
      temp: 16, condition: 'Spring Evening', humidity: 55, windSpeed: 8,
      darkGradient: [0xFF2D1B3E, 0xFF4A2D5C, 0xFF6B3F7A],
      lightGradient: [0xFFFFAB91, 0xFFCE93D8, 0xFFB39DDB],
      meshColors: [0xFFFF8A65, 0xFFFFAB91, 0xFFCE93D8, 0xFF90CAF9],
      womenOutfit: [OutfitItem(nameKey: 'item_cardigan', category: OutfitCategory.outerwear), OutfitItem(nameKey: 'item_floral_dress', category: OutfitCategory.top), OutfitItem(nameKey: 'item_ballet_flats', category: OutfitCategory.shoes), OutfitItem(nameKey: 'item_clutch', category: OutfitCategory.accessory)],
      menOutfit: [OutfitItem(nameKey: 'item_light_jacket', category: OutfitCategory.outerwear), OutfitItem(nameKey: 'item_chinos', category: OutfitCategory.bottom), OutfitItem(nameKey: 'item_loafers', category: OutfitCategory.shoes), OutfitItem(nameKey: 'item_watch', category: OutfitCategory.accessory)],
    ),
  ];
}
