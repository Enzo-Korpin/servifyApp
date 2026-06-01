import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:frontend/Access/login_screens/select_type.dart';
import 'package:frontend/Home_pages/home_worker.dart';
import 'package:frontend/Home_pages/smart_worker_map_page.dart';
import 'package:frontend/core/network/dio_client.dart';
import 'package:frontend/core/network/socket_client.dart';
import 'package:frontend/Access/verification/reset_password.dart';
import 'package:frontend/Access/verification/forgot_password.dart';




Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: '.env');

  await FMTCObjectBoxBackend().initialise();
  await FMTCStore('mapStore').manage.create();

  await DioClient.init();

  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: AuthGate(),
    ),
  );
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    Widget next = const SelectType();

    try {
      final response = await DioClient.dio.get(
        "/api/auth/check-auth",
        options: Options(
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      final data = response.data as Map<String, dynamic>?;

      if (response.statusCode == 200 &&
          data != null &&
          data["success"] == true) {
        final userData = data["data"] as Map<String, dynamic>?;
        final currentRole =
            (userData?["currentRole"] ?? userData?["role"])?.toString();

        try {
          await SocketClient.instance.reconnectFresh();
        } catch (_) {}

        if (currentRole == "customer") {
          next = const SmartWorkerMapPage();
        } else if (currentRole == "worker") {
          next = const HomeWorker();
        }
      }
    } catch (_) {
      // Network error / no valid session: fall through to SelectType.
    }

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => next),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFEAF7FF),
      body: Center(
        child: CircularProgressIndicator(color: Color(0xFF1E40AF)),
      ),
    );
  }
}
