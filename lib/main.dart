import 'package:flutter/material.dart';
import 'package:routesapp/ui/screens/mapviewer.dart';
import 'package:google_maps_flutter_android/google_maps_flutter_android.dart';
import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart';

void main() async {
  final GoogleMapsFlutterPlatform mapsImplementation =
      GoogleMapsFlutterPlatform.instance;
  if (mapsImplementation is GoogleMapsFlutterAndroid) {
    mapsImplementation.useAndroidViewSurface = true;
    WidgetsFlutterBinding.ensureInitialized();
    await GoogleMapsFlutterAndroid()
        .initializeWithRenderer(AndroidMapRenderer.latest);
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Geolocalização',
      theme: ThemeData(
        useMaterial3: false,
        fontFamily: 'Lato',
        colorScheme: const ColorScheme(
          brightness: Brightness.light,
          primary: Color(0XFFA0BF7F),
          onPrimary: Color(0XFF1d1b19),
          background: Color(0XFFA0BF7F),
          onBackground: Color(0XFF1d1b19),
          secondary: Color(0XFFDDC9BF),
          onSecondary: Color(0XFF1d1b19),
          tertiary: Color(0XFFE77573),
          onTertiary: Color(0XFFFFFFFF),
          surface: Color(0XFFDDC9BF),
          onSurface: Color(0XFF1d1b19),
          error: Color(0XFFff9090),
          onError: Color(0XFFC6504E),
        ),
        scaffoldBackgroundColor: const Color(0XFFfcf5ef),
      ),
      home: const MapViewer(),
    );
  }
}
