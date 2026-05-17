import 'dart:io';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:path_provider/path_provider.dart';

class DioClient {
  static late Dio dio;
  static late PersistCookieJar cookieJar;
  static late String _cookieStorePath;

  static const String baseUrl = 'http://192.168.100.9:5000';

  static Future<void> init() async {
    dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        headers: {
          'Content-Type': 'application/json',
        },
      ),
    );

    final dir = await getApplicationDocumentsDirectory();
    _cookieStorePath = "${dir.path}/.cookies/";

    cookieJar = PersistCookieJar(
      storage: FileStorage(_cookieStorePath),
    );

    _attachInterceptors();
  }

  static void _attachInterceptors() {
    dio.interceptors.clear();

    dio.interceptors.add(CookieManager(cookieJar));

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          print("➡️ REQUEST: ${options.uri}");
          return handler.next(options);
        },
        onResponse: (response, handler) {
          print("✅ RESPONSE: ${response.statusCode}");
          return handler.next(response);
        },
        onError: (error, handler) {
          print("❌ ERROR: ${error.response?.data}");
          return handler.next(error);
        },
      ),
    );
  }

  static Future<void> resetCookieJarCompletely() async {
    print("DEBUG: NUCLEAR COOKIE RESET - Deleting persistent storage...");

    final dir = Directory(_cookieStorePath);

    if (await dir.exists()) {
      print("DEBUG: Cookie storage dir exists, deleting...");
      await dir.delete(recursive: true);
      print("DEBUG: Cookie storage deleted successfully");
    }

    cookieJar = PersistCookieJar(
      storage: FileStorage(_cookieStorePath),
    );

    _attachInterceptors();

    print("DEBUG: Fresh CookieJar created and attached to Dio");

    final cookies = await cookieJar.loadForRequest(Uri.parse(baseUrl));
    print("DEBUG: After reset, cookie count: ${cookies.length} (should be 0)");
  }
}