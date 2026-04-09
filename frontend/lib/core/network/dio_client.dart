import 'package:dio/dio.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:path_provider/path_provider.dart';
// http://10.0.2.2:5000
class DioClient {
  static late Dio dio;

  static Future<void> init() async {
    dio = Dio(
      BaseOptions(
        baseUrl: 'http://10.0.2.2:5000',
        headers: {
          'Content-Type': 'application/json',
        },
      ),
    );

    final dir = await getApplicationDocumentsDirectory();

    final cookieJar = PersistCookieJar(
      storage: FileStorage("${dir.path}/.cookies/"),
    );

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
}