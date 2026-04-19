import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/weather_provider.dart';

/// Settings Screen — "Select Language" button + modal, F/C unit switcher,
/// Dark/Light mode toggle, Version v1.0.1.
/// Removed: Saved Cities, Current City, Available Cities, inline lang list.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = Provider.of<WeatherProvider>(context);
    final topPad = MediaQuery.of(context).padding.top;
    final dark = p.isDarkMode;
    final fg = dark ? Colors.white : Colors.black87;
    final fgSub = dark ? Colors.white60 : Colors.black45;
    final accent = const Color(0xFF3B82F6);

    // Current language info
    final langInfo = WeatherProvider.supportedLanguages
        .firstWhere((l) => l['code'] == p.language);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.fromLTRB(20, topPad + 16, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──
            Text(p.tr('settings'), style: TextStyle(
                fontSize: 28, fontWeight: FontWeight.w300, color: fg)),
            const SizedBox(height: 4),
            Text(p.tr('customize'), style: TextStyle(
                fontSize: 14, color: fgSub)),
            const SizedBox(height: 24),

            // ═══════════════════════════════════════════════════════
            // 1) LANGUAGE — "Select Language" button → opens modal
            // ═══════════════════════════════════════════════════════
            _glassCard(dark, child: Column(children: [
              _settingsRow(
                icon: Icons.translate, fg: fg, fgSub: fgSub,
                title: p.tr('language'),
                subtitle: '${langInfo['flag']} ${langInfo['name']}',
                trailing: _actionButton(
                  label: p.tr('language'),
                  dark: dark,
                  accent: accent,
                  onTap: () => _showLanguageModal(context, p, dark, accent),
                ),
              ),
            ])),
            const SizedBox(height: 16),

            // ═══════════════════════════════════════════════════════
            // 2) APPEARANCE — Dark Mode / Light Mode
            // ═══════════════════════════════════════════════════════
            _glassCard(dark, child: Column(children: [
              _settingsRow(
                icon: Icons.dark_mode, fg: fg, fgSub: fgSub,
                title: p.tr('appearance'),
                subtitle: p.isDarkMode
                    ? p.tr('dark_mode')
                    : p.tr('light_mode'),
                trailing: Switch(
                  value: p.isDarkMode,
                  activeTrackColor: accent,
                  activeThumbColor: Colors.white,
                  inactiveTrackColor: dark
                      ? Colors.white24
                      : Colors.grey.shade300,
                  inactiveThumbColor: Colors.grey.shade600,
                  onChanged: (_) => p.toggleDarkMode(),
                ),
              ),
              Divider(color: dark
                  ? Colors.white.withOpacity(0.1)
                  : Colors.grey.shade200, height: 1),

              // ═════════════════════════════════════════════════════
              // 3) TEMPERATURE UNIT — F left, C right toggle
              // ═════════════════════════════════════════════════════
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Row(children: [
                  Icon(Icons.thermostat, color: fgSub, size: 22),
                  const SizedBox(width: 14),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.tr('temp_unit'), style: TextStyle(
                          color: fg, fontWeight: FontWeight.w500, fontSize: 15)),
                      const SizedBox(height: 2),
                      Text(p.useCelsius
                              ? p.tr('celsius')
                              : p.tr('fahrenheit'),
                          style: TextStyle(color: fgSub, fontSize: 13)),
                    ],
                  )),
                  // ── F / C segmented toggle ──
                  _buildUnitToggle(p, dark, accent),
                ]),
              ),
            ])),
            const SizedBox(height: 16),

            // ═══════════════════════════════════════════════════════
            // 4) VERSION — v1.0.1
            // ═══════════════════════════════════════════════════════
            _glassCard(dark, child: _settingsRow(
              icon: Icons.info_outline, fg: fg, fgSub: fgSub,
              title: p.tr('version'),
              subtitle: 'v1.0.1',
            )),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // F on left, C on right — stylish segmented toggle
  // ═══════════════════════════════════════════════════════════════════

  Widget _buildUnitToggle(WeatherProvider p, bool dark, Color accent) {
    return Container(
      decoration: BoxDecoration(
        color: dark
            ? Colors.white.withOpacity(0.1)
            : Colors.black.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        // F button (left)
        GestureDetector(
          onTap: () => p.setCelsius(false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: !p.useCelsius ? accent : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text('°F', style: TextStyle(
              color: !p.useCelsius
                  ? Colors.white
                  : (dark ? Colors.white54 : Colors.black45),
              fontWeight: FontWeight.w700, fontSize: 15,
            )),
          ),
        ),
        // C button (right)
        GestureDetector(
          onTap: () => p.setCelsius(true),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: p.useCelsius ? accent : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text('°C', style: TextStyle(
              color: p.useCelsius
                  ? Colors.white
                  : (dark ? Colors.white54 : Colors.black45),
              fontWeight: FontWeight.w700, fontSize: 15,
            )),
          ),
        ),
      ]),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // LANGUAGE MODAL — opened from the "Select Language" button
  // ═══════════════════════════════════════════════════════════════════

  void _showLanguageModal(
      BuildContext ctx, WeatherProvider p, bool dark, Color accent) {
    showModalBottomSheet(
      context: ctx,
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
          ...WeatherProvider.supportedLanguages.map((lang) {
            final sel = lang['code'] == p.language;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    p.setLanguage(lang['code']!);
                    Navigator.pop(ctx);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(
                      color: sel
                          ? accent.withOpacity(dark ? 0.2 : 0.1)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(children: [
                      Text(lang['flag']!,
                          style: const TextStyle(fontSize: 22)),
                      const SizedBox(width: 14),
                      Expanded(child: Text(lang['name']!, style: TextStyle(
                        color: sel ? accent : (dark ? Colors.white : Colors.black87),
                        fontWeight: sel ? FontWeight.w700 : FontWeight.w400,
                        fontSize: 15,
                      ))),
                      if (sel)
                        Icon(Icons.check_circle, color: accent, size: 20),
                    ]),
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 12),
        ]),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // REUSABLE WIDGETS
  // ═══════════════════════════════════════════════════════════════════

  Widget _glassCard(bool dark, {required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: dark
                ? Colors.white.withOpacity(0.12)
                : Colors.white.withOpacity(0.7),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: dark
                  ? Colors.white.withOpacity(0.2)
                  : Colors.grey.withOpacity(0.2),
              width: 0.5,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: child,
        ),
      ),
    );
  }

  Widget _settingsRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color fg,
    required Color fgSub,
    Widget? trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(children: [
        Icon(icon, color: fgSub, size: 22),
        const SizedBox(width: 14),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(
                color: fg, fontWeight: FontWeight.w500, fontSize: 15)),
            const SizedBox(height: 2),
            Text(subtitle, style: TextStyle(color: fgSub, fontSize: 13)),
          ],
        )),
        if (trailing != null) trailing,
      ]),
    );
  }

  /// High-contrast action button for "Select Language".
  Widget _actionButton({
    required String label,
    required bool dark,
    required Color accent,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: accent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: accent.withOpacity(0.35),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.language, color: Colors.white, size: 16),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(
            color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600,
          )),
        ]),
      ),
    );
  }
}
