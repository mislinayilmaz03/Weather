// Basic smoke test for the Weather App.

import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:weather_app/main.dart';
import 'package:weather_app/providers/weather_provider.dart';

void main() {
  testWidgets('App renders Home screen with weather data',
      (WidgetTester tester) async {
    // Build the app wrapped in the Provider, just like main.dart does.
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => WeatherProvider(),
        child: const WeatherApp(),
      ),
    );

    // Verify the default city (Amman) is shown.
    expect(find.text('Amman'), findsWidgets);

    // Verify the bottom navigation bar is present.
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Forecast'), findsOneWidget);
    expect(find.text('Favourites'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
  });
}
