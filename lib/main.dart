import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'providers/weather_provider.dart';
import 'screens/home_screen.dart';
import 'screens/forecast_screen.dart';
import 'screens/favourites_screen.dart';
import 'screens/settings_screen.dart';
import 'widgets/animated_mesh_gradient.dart';

/// Entry point
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ChangeNotifierProvider(
      create: (_) => WeatherProvider(),
      child: const WeatherApp(),
    ),
  );
}

/// Root widget — supports dynamic Dark/Light mode via Provider.
class WeatherApp extends StatelessWidget {
  const WeatherApp({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<WeatherProvider>(context);
    final dark = provider.isDarkMode;

    // Update status bar based on theme
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: dark ? Brightness.light : Brightness.dark,
    ));

    return MaterialApp(
      title: 'Weather & Outfit Suggester',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: dark ? Brightness.dark : Brightness.light,
        scaffoldBackgroundColor: Colors.transparent,
        useMaterial3: true,
        textTheme: GoogleFonts.interTextTheme(
          dark ? ThemeData.dark().textTheme : ThemeData.light().textTheme,
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (_) => const MainShell(),
        '/home': (_) => const HomeScreen(),
        '/forecast': (_) => const ForecastScreen(),
        '/favourites': (_) => const FavouritesScreen(),
        '/settings': (_) => const SettingsScreen(),
      },
    );
  }
}

/// Main Shell — gradient background + premium bottom tab bar.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<WeatherProvider>(context);
    final gradient = provider.weatherGradient;
    final dark = provider.isDarkMode;

    final List<Widget> screens = [
      const HomeScreen(),
      const ForecastScreen(),
      FavouritesScreen(
        onCitySelected: () => setState(() => _currentIndex = 0),
      ),
      const SettingsScreen(),
    ];

    // Colors for bottom bar based on theme
    final barBg = dark
        ? Colors.black.withOpacity(0.45)
        : Colors.white.withOpacity(0.85);
    final barBorder = dark
        ? Colors.white.withOpacity(0.12)
        : Colors.grey.withOpacity(0.2);
    final activeColor = dark ? Colors.white : const Color(0xFF2563EB);
    final inactiveColor = dark ? Colors.white38 : Colors.grey.shade500;

    final meshColors = provider.meshGradientColors;

    return Stack(
      children: [
        // ── Animated Mesh Gradient Background ──
        Positioned.fill(
          child: AnimatedMeshGradient(
            colors: meshColors,
            duration: const Duration(seconds: 10),
          ),
        ),
        // ── Linear gradient overlay for depth ──
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  gradient[0].withOpacity(0.6),
                  gradient[1].withOpacity(0.3),
                  gradient[2].withOpacity(0.5),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ),
        Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
        body: IndexedStack(
          index: _currentIndex,
          children: screens,
        ),

        // ── Premium bottom tab bar ──
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: barBg,
            border: Border(top: BorderSide(color: barBorder, width: 0.5)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(dark ? 0.3 : 0.08),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildTabItem(Icons.cloud_outlined, Icons.cloud,
                      provider.tr('home'), 0, activeColor, inactiveColor),
                  _buildTabItem(Icons.calendar_today_outlined,
                      Icons.calendar_today, provider.tr('forecast'), 1, activeColor, inactiveColor),
                  _buildTabItem(Icons.favorite_outline, Icons.favorite,
                      provider.tr('favourites'), 2, activeColor, inactiveColor),
                  _buildTabItem(Icons.settings_outlined, Icons.settings,
                      provider.tr('settings'), 3, activeColor, inactiveColor),
                ],
              ),
            ),
          ),
        ),
      ),
      ],
    );
  }

  Widget _buildTabItem(IconData icon, IconData activeIcon, String label,
      int index, Color activeColor, Color inactiveColor) {
    final isActive = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 70,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isActive ? activeColor.withOpacity(0.15) : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isActive ? activeIcon : icon,
                color: isActive ? activeColor : inactiveColor,
                size: 22,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                color: isActive ? activeColor : inactiveColor,
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
