import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/weather_provider.dart';
import 'screens/home_screen.dart';
import 'screens/forecast_screen.dart';
import 'screens/favourites_screen.dart';
import 'screens/settings_screen.dart';

/// Entry point — wraps the app in a ChangeNotifierProvider so every screen
/// can access the global WeatherProvider state.
void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => WeatherProvider(),
      child: const WeatherApp(),
    ),
  );
}

/// Root widget — configures the theme and launches the main shell.
class WeatherApp extends StatelessWidget {
  const WeatherApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Weather & Outfit Suggester',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        scaffoldBackgroundColor: const Color(0xFFF5F5FA),
        useMaterial3: true,
      ),
      // ── Named Routes for multi-screen navigation ──
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

/// Main Shell — houses the AppBar and Bottom Navigation Bar.
/// Switches between the four primary screens.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  // Current tab index — managed locally with setState()
  int _currentIndex = 0;

  // Page titles for the AppBar
  static const List<String> _titles = [
    'Weather & Outfit',
    '5-Day Forecast',
    'Favourites',
    'Settings',
  ];

  @override
  Widget build(BuildContext context) {
    // Build screens list here so we can pass the tab-switch callback
    final List<Widget> screens = [
      const HomeScreen(),
      const ForecastScreen(),
      FavouritesScreen(
        onCitySelected: () => setState(() => _currentIndex = 0),
      ),
      const SettingsScreen(),
    ];

    return Scaffold(
      // ── App Bar ──
      appBar: AppBar(
        title: Text(
          _titles[_currentIndex],
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.deepPurple,
        elevation: 0,
      ),

      // ── Body — displays the selected screen ──
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),

      // ── Bottom Navigation Bar ──
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
        backgroundColor: Colors.white,
        indicatorColor: Colors.deepPurple.withValues(alpha: 30),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home, color: Colors.deepPurple),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_today_outlined),
            selectedIcon: Icon(Icons.calendar_today, color: Colors.deepPurple),
            label: 'Forecast',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_outline),
            selectedIcon: Icon(Icons.favorite, color: Colors.deepPurple),
            label: 'Favourites',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings, color: Colors.deepPurple),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
