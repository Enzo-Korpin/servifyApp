import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppMapConfig {
  static const String userAgent = 'com.servify.app';
  static const String storeName = 'mapStore';

  static String get mapTilerKey => dotenv.env['MAPTILER_KEY'] ?? '';

  static String get tileUrl =>
      'https://api.maptiler.com/maps/streets/{z}/{x}/{y}.png?key=$mapTilerKey';
}