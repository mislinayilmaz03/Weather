import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/weather_model.dart';
import '../providers/weather_provider.dart';
import '../widgets/shimmer_placeholder.dart';

/// Home Screen — Weather hero, glassmorphism details, outfit section
/// with inline gender selector and seasonal color palette.
/// NOTE: C/F toggle removed from here — now in Settings only.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchError = '';
  bool _showSearch = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearch(WeatherProvider p) {
    final q = _searchCtrl.text.trim();
    if (q.isEmpty) {
      setState(() => _searchError = p.tr('enter_city'));
      return;
    }
    final found = p.searchCity(q);
    setState(() {
      _searchError = found ? '' : p.tr('city_not_found');
      if (found) _showSearch = false;
    });
    if (found) {
      _searchCtrl.clear();
      FocusScope.of(context).unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = Provider.of<WeatherProvider>(context);
    final w = p.currentWeather;
    final dark = p.isDarkMode;
    final topPad = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              SizedBox(height: topPad + 8),

              // ── Top bar: search + language ──
              _buildTopBar(p, dark),
              const SizedBox(height: 8),

              // ── Location selectors ──
              _buildLocationSelectors(p, dark),
              const SizedBox(height: 8),

              // ── Search bar (collapsible) ──
              if (_showSearch) _buildSearchBar(p, dark),

              // ── Weather hero ──
              _buildWeatherHero(p, w, dark),
              const SizedBox(height: 24),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    // ── Humidity & Wind cards ──
                    Row(children: [
                      Expanded(child: _premiumGlassCard(dark, child: _detailTile(
                        Icons.water_drop_outlined, p.tr('humidity'),
                        '${w.humidity.toStringAsFixed(0)}%', dark,
                      ))),
                      const SizedBox(width: 12),
                      Expanded(child: _premiumGlassCard(dark, child: _detailTile(
                        Icons.air, p.tr('wind'),
                        '${w.windSpeed.toStringAsFixed(0)} km/h', dark,
                      ))),
                    ]),
                    const SizedBox(height: 16),

                    // ── Outfit suggestion card (with gender selector) ──
                    _premiumGlassCard(dark, child: _buildOutfitSection(p, dark)),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // TOP BAR — search icon + language chip
  // ═══════════════════════════════════════════════════════════════════

  Widget _buildTopBar(WeatherProvider p, bool dark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => setState(() => _showSearch = !_showSearch),
            child: Icon(_showSearch ? Icons.close : Icons.search,
                color: dark ? Colors.white70 : Colors.black54, size: 24),
          ),
          GestureDetector(
            onTap: () => _showLanguageSheet(p, dark),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: dark
                    ? Colors.white.withOpacity(0.15)
                    : Colors.black.withOpacity(0.08),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.translate, size: 16,
                    color: dark ? Colors.white70 : Colors.black54),
                const SizedBox(width: 6),
                Text(
                  WeatherProvider.supportedLanguages
                      .firstWhere((l) => l['code'] == p.language)['name']!,
                  style: TextStyle(
                    color: dark ? Colors.white : Colors.black87,
                    fontSize: 13, fontWeight: FontWeight.w500,
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // LANGUAGE SHEET
  // ═══════════════════════════════════════════════════════════════════

  void _showLanguageSheet(WeatherProvider p, bool dark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: dark ? const Color(0xFF1A1F2E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4,
              decoration: BoxDecoration(
                color: dark ? Colors.white30 : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              )),
          const SizedBox(height: 20),
          Text(p.tr('language'), style: TextStyle(
              color: dark ? Colors.white : Colors.black87,
              fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Flexible(child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          ...WeatherProvider.supportedLanguages.map((lang) {
            final sel = lang['code'] == p.language;
            return ListTile(
              onTap: () {
                p.setLanguage(lang['code']!);
                Navigator.pop(context);
              },
              leading: Text(lang['flag']!, style: const TextStyle(fontSize: 24)),
              title: Text(lang['name']!, style: TextStyle(
                color: sel ? const Color(0xFF3B82F6) : (dark ? Colors.white : Colors.black87),
                fontWeight: sel ? FontWeight.bold : FontWeight.normal,
              )),
              trailing: sel
                  ? const Icon(Icons.check_circle, color: Color(0xFF3B82F6))
                  : null,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            );
          }),
          const SizedBox(height: 12),
          ]))),
        ]),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // LOCATION SELECTORS
  // ═══════════════════════════════════════════════════════════════════

  Widget _buildLocationSelectors(WeatherProvider p, bool dark) {
    final cities = p.getCitiesForCountry(p.selectedCountry);
    final districts =
        p.getDistrictsForCity(p.selectedCountry, p.selectedCity);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(children: [
        Expanded(child: _selectorChip(
          icon: Icons.public,
          value: p.selectedCountry,
          items: p.countries,
          display: (c) => p.translateCountry(c),
          onPick: (v) => p.setCountry(v),
          dark: dark,
        )),
        const SizedBox(width: 8),
        Expanded(child: _selectorChip(
          icon: Icons.location_city,
          value: cities.contains(p.selectedCity)
              ? p.selectedCity
              : (cities.isNotEmpty ? cities.first : ''),
          items: cities,
          display: (c) => c,
          onPick: (v) => p.setCity(v),
          dark: dark,
        )),
        const SizedBox(width: 8),
        Expanded(child: _selectorChip(
          icon: Icons.map_outlined,
          value: districts.contains(p.selectedDistrict)
              ? p.selectedDistrict
              : (districts.isNotEmpty ? districts.first : ''),
          items: districts,
          display: (d) => d,
          onPick: (v) => p.setDistrict(v),
          dark: dark,
        )),
      ]),
    );
  }

  Widget _selectorChip({
    required IconData icon,
    required String value,
    required List<String> items,
    required String Function(String) display,
    required ValueChanged<String> onPick,
    required bool dark,
  }) {
    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          builder: (_) => Container(
            constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.5),
            decoration: BoxDecoration(
              color: dark ? const Color(0xFF1A1F2E) : Colors.white,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: dark ? Colors.white30 : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  )),
              const SizedBox(height: 12),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: items.length,
                  itemBuilder: (_, i) {
                    final sel = items[i] == value;
                    return ListTile(
                      onTap: () {
                        onPick(items[i]);
                        Navigator.pop(context);
                      },
                      title: Text(display(items[i]), style: TextStyle(
                        color: sel
                            ? const Color(0xFF3B82F6)
                            : (dark ? Colors.white : Colors.black87),
                        fontWeight: sel ? FontWeight.bold : FontWeight.normal,
                      )),
                      trailing: sel
                          ? const Icon(Icons.check_circle,
                              color: Color(0xFF3B82F6), size: 20)
                          : null,
                    );
                  },
                ),
              ),
            ]),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: dark
              ? Colors.white.withOpacity(0.12)
              : Colors.black.withOpacity(0.06),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(children: [
          Icon(icon, size: 14,
              color: dark ? Colors.white60 : Colors.black45),
          const SizedBox(width: 4),
          Expanded(child: Text(display(value), style: TextStyle(
            color: dark ? Colors.white : Colors.black87,
            fontSize: 11, fontWeight: FontWeight.w500,
          ), overflow: TextOverflow.ellipsis)),
          Icon(Icons.keyboard_arrow_down, size: 16,
              color: dark ? Colors.white60 : Colors.black45),
        ]),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // SEARCH BAR
  // ═══════════════════════════════════════════════════════════════════

  Widget _buildSearchBar(WeatherProvider p, bool dark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Column(children: [
        Container(
          decoration: BoxDecoration(
            color: dark
                ? Colors.white.withOpacity(0.15)
                : Colors.black.withOpacity(0.06),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(children: [
            Expanded(child: TextField(
              controller: _searchCtrl,
              style: TextStyle(color: dark ? Colors.white : Colors.black87),
              decoration: InputDecoration(
                hintText: p.tr('search_city'),
                hintStyle: TextStyle(
                    color: dark ? Colors.white54 : Colors.black38),
                prefixIcon: Icon(Icons.search,
                    color: dark ? Colors.white54 : Colors.black38),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
              ),
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _onSearch(p),
              onChanged: (_) {
                if (_searchError.isNotEmpty) setState(() => _searchError = '');
              },
            )),
            GestureDetector(
              onTap: () => _onSearch(p),
              child: Container(
                margin: const EdgeInsets.only(right: 6),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.search, color: Colors.white, size: 20),
              ),
            ),
          ]),
        ),
        if (_searchError.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 8),
            child: Text(_searchError,
                style: const TextStyle(
                    color: Colors.orangeAccent, fontSize: 12)),
          ),
      ]),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // WEATHER HERO
  // ═══════════════════════════════════════════════════════════════════

  Widget _buildWeatherHero(WeatherProvider p, dynamic w, bool dark) {
    final fg = dark ? Colors.white : Colors.black87;
    final fgSub = dark ? Colors.white70 : Colors.black54;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(children: [
        const SizedBox(height: 8),
        // City name + fav icon
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Flexible(child: Text(w.cityName,
            textAlign: TextAlign.center,
            style: GoogleFonts.playfairDisplay(
                fontSize: 32, fontWeight: FontWeight.w400,
                color: fg, letterSpacing: 0.5),
            maxLines: 2, overflow: TextOverflow.ellipsis,
          )),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              p.isFavourite(w.cityName)
                  ? p.removeFavourite(w.cityName)
                  : p.addFavourite(w.cityName);
            },
            child: Icon(
              p.isFavourite(w.cityName)
                  ? Icons.favorite
                  : Icons.favorite_border,
              color: fgSub, size: 20,
            ),
          ),
        ]),
        const SizedBox(height: 4),
        // Giant temperature
        Text(
          '${p.displayTemp(w.temperature).toStringAsFixed(0)}°',
          style: GoogleFonts.playfairDisplay(fontSize: 96, fontWeight: FontWeight.w200,
              color: fg, height: 1.1),
        ),
        // Condition text
        Text(p.translateCondition(w.condition),
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w400,
                color: fgSub)),
        const SizedBox(height: 4),
        // H / L
        Text(
          'H:${p.displayTemp(w.temperature + 3).toStringAsFixed(0)}°  '
          'L:${p.displayTemp(w.temperature - 4).toStringAsFixed(0)}°',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500,
              color: fg),
        ),
        const SizedBox(height: 4),
        Text(w.icon, style: const TextStyle(fontSize: 40)),
      ]),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // PREMIUM GLASS CARD — rounded-[2rem] + ghost border
  // ═══════════════════════════════════════════════════════════════════

  Widget _premiumGlassCard(bool dark, {required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(32), // rounded-[2rem]
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: dark
                ? Colors.white.withOpacity(0.10)
                : Colors.white.withOpacity(0.65),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
              color: dark
                  ? Colors.white.withOpacity(0.1) // ghost border
                  : Colors.white.withOpacity(0.4),
              width: 1,
            ),
          ),
          padding: const EdgeInsets.all(20),
          child: child,
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // DETAIL TILE (Humidity / Wind)
  // ═══════════════════════════════════════════════════════════════════

  Widget _detailTile(IconData icon, String label, String value, bool dark) {
    final fg = dark ? Colors.white : Colors.black87;
    final fgSub = dark ? Colors.white54 : Colors.black38;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Icon(icon, size: 14, color: fgSub),
        const SizedBox(width: 6),
        Text(label.toUpperCase(), style: TextStyle(color: fgSub,
            fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
      ]),
      const SizedBox(height: 10),
      Text(value, style: TextStyle(color: fg, fontSize: 28,
          fontWeight: FontWeight.w300)),
    ]);
  }

  // ═══════════════════════════════════════════════════════════════════
  // OUTFIT SECTION — gender selector inline + dynamic image + palette
  // ═══════════════════════════════════════════════════════════════════

  /// Map outfit category to appropriate Material icon.
  IconData _categoryIcon(OutfitCategory cat) {
    switch (cat) {
      case OutfitCategory.top: return Icons.checkroom;
      case OutfitCategory.bottom: return Icons.straighten;
      case OutfitCategory.shoes: return Icons.ice_skating;
      case OutfitCategory.accessory: return Icons.auto_awesome;
      case OutfitCategory.outerwear: return Icons.shield_outlined;
      case OutfitCategory.headwear: return Icons.face_retouching_natural;
    }
  }

  Widget _buildOutfitSection(WeatherProvider p, bool dark) {
    final outfit = p.getOutfitSuggestion();
    final fg = dark ? Colors.white : Colors.black87;
    final fgSub = dark ? Colors.white54 : Colors.black38;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // ── Title row ──
      Row(children: [
        Icon(Icons.checkroom, size: 14, color: fgSub),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            p.tr('outfit_suggestion').toUpperCase(),
            style: GoogleFonts.inter(color: fgSub, fontSize: 11,
                fontWeight: FontWeight.w600, letterSpacing: 1.2),
          ),
        ),
      ]),
      const SizedBox(height: 10),

      // ── Gender segmented control (minimalist) ──
      Container(
        decoration: BoxDecoration(
          color: dark
              ? Colors.white.withOpacity(0.08)
              : Colors.black.withOpacity(0.04),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          _genderPill(p, 'male', Icons.male, dark),
          _genderPill(p, 'female', Icons.female, dark),
        ]),
      ),

      Divider(color: dark ? Colors.white12 : Colors.grey.shade200, height: 28),

      // ── Dynamic outfit image with Shimmer placeholder ──
      ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: SizedBox(
          width: double.infinity, height: 200,
          child: Image.asset(
            outfit.imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => ShimmerPlaceholder(
              height: 200, borderRadius: 24, isDark: dark,
            ),
          ),
        ),
      ),
      const SizedBox(height: 16),

      // ── Outfit Item Icons (Kombin Detay Kartları) ──
      if (outfit.items.isNotEmpty) ...[
        Wrap(
          spacing: 8, runSpacing: 8,
          children: outfit.items.map((item) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: dark
                    ? Colors.white.withOpacity(0.08)
                    : Colors.black.withOpacity(0.04),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: dark
                      ? Colors.white.withOpacity(0.1)
                      : Colors.black.withOpacity(0.06),
                  width: 1,
                ),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(_categoryIcon(item.category), size: 16,
                    color: dark ? Colors.white70 : Colors.black54),
                const SizedBox(width: 6),
                Text(p.tr(item.nameKey), style: GoogleFonts.inter(
                  color: fg, fontSize: 12, fontWeight: FontWeight.w500,
                )),
              ]),
            );
          }).toList(),
        ),
        const SizedBox(height: 14),
      ],

      // ── Description text ──
      Text(outfit.description,
          style: GoogleFonts.inter(color: fg, fontSize: 14, height: 1.6)),
      const SizedBox(height: 16),

      // ── Seasonal Color Palette ──
      Row(children: [
        Icon(Icons.palette, size: 14, color: fgSub),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            '${p.tr('seasonal_colors')} — ${p.tr(outfit.seasonName)}'
                .toUpperCase(),
            style: GoogleFonts.inter(color: fgSub, fontSize: 10,
                fontWeight: FontWeight.w600, letterSpacing: 1),
          ),
        ),
      ]),
      const SizedBox(height: 10),
      Wrap(
        spacing: 10, runSpacing: 8,
        children: outfit.seasonalColors.map((sc) {
          return Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                color: Color(sc.colorValue),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: dark ? Colors.white.withOpacity(0.1) : Colors.grey.shade300,
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color(sc.colorValue).withOpacity(0.25),
                    blurRadius: 8, offset: const Offset(0, 3),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text(p.tr(sc.name), style: GoogleFonts.inter(color: fgSub,
                fontSize: 9, fontWeight: FontWeight.w500)),
          ]);
        }).toList(),
      ),
    ]);
  }

  /// Minimalist gender pill inside the outfit card.
  Widget _genderPill(
      WeatherProvider p, String gender, IconData icon, bool dark) {
    final active = p.selectedGender == gender;
    return GestureDetector(
      onTap: () => p.setGender(gender),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: active
              ? (dark ? const Color(0xFF3B82F6) : const Color(0xFF2563EB))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 18,
              color: active
                  ? Colors.white
                  : (dark ? Colors.white54 : Colors.black45)),
          const SizedBox(width: 4),
          Text(p.tr(gender), style: GoogleFonts.inter(
            fontSize: 13, fontWeight: FontWeight.w600,
            color: active
                ? Colors.white
                : (dark ? Colors.white54 : Colors.black45),
          )),
        ]),
      ),
    );
  }

}
