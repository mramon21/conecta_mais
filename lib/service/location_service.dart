import 'package:geolocator/geolocator.dart';

Future<Position> determineUserPosition() async {
  if (!await Geolocator.isLocationServiceEnabled()) {
    throw StateError('Ative a localização do dispositivo para ver eventos próximos.');
  }

  var permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
  }
  if (permission == LocationPermission.denied) {
    throw StateError('Permita o acesso à localização para ver eventos próximos.');
  }
  if (permission == LocationPermission.deniedForever) {
    throw StateError(
      'A permissão de localização está bloqueada. Altere-a nas configurações do dispositivo.',
    );
  }

  return Geolocator.getCurrentPosition(
    locationSettings: const LocationSettings(
      accuracy: LocationAccuracy.medium,
      timeLimit: Duration(seconds: 15),
    ),
  );
}
