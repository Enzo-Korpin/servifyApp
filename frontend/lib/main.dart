import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:frontend/Access/login_screens/select_type.dart';
import 'package:frontend/core/network/dio_client.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: '.env');

  await FMTCObjectBoxBackend().initialise();
  await FMTCStore('mapStore').manage.create();

  await DioClient.init();

  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SelectType(),
    ),
  );
}