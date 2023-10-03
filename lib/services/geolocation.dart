import 'package:geolocator/geolocator.dart';

Future<Position> getPosition() async {
  bool serviceEnabled;
  LocationPermission permission;

  // Test if location services are enabled.
  serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    // Location services are not enabled don't continue
    // accessing the position and request users of the
    // App to enable the location services.
    return Future.error(
        'A localização do dispositivo está desabilitada.\n\nAtive a localização e tente novamente.');
  }

  permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      // Permissions are denied, next time you could try
      // requesting permissions again (this is also where
      // Android's shouldShowRequestPermissionRationale
      // returned true. According to Android guidelines
      // your App should show an explanatory UI now.
      return Future.error(
          'A aplicação não tem permissão para acessar a localização do dispositivo.\n\nTente novamente e autorize o acesso à localização quando requisitado.');
    }
  }

  if (permission == LocationPermission.deniedForever) {
    // Permissions are denied forever, handle appropriately.
    //Geolocator.openAppSettings();
    return Future.error(
        'O acesso à localização do dispositivo foi desabilitado permanentemente.\n\nHabilite o acesso à localização nas configurações do app.');
  }

  // When we reach here, permissions are granted and we can
  // continue accessing the position of the device.
  return await Geolocator.getCurrentPosition();
}
