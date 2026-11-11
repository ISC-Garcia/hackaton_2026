import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import 'error_verago.dart';

/// SERVICIO de ubicación (paquete `geolocator`).
///
/// Privacidad: solo se llama cuando el visitante toca "Mi ubicación".
/// La ubicación se usa dentro del celular para iniciar la ruta;
/// NO se envía a Supabase ni se guarda.
class UbicacionService {
  Future<LatLng> obtenerUbicacion() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const ErrorVeraGo('Activa la ubicación (GPS) de tu celular.');
    }

    var permiso = await Geolocator.checkPermission();
    if (permiso == LocationPermission.denied) {
      permiso = await Geolocator.requestPermission(); // aquí aparece el aviso
    }
    if (permiso == LocationPermission.denied || permiso == LocationPermission.deniedForever) {
      throw const ErrorVeraGo('Sin permiso de ubicación. Puedes iniciar desde el Zócalo.');
    }

    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 15),
        ),
      );
      return LatLng(pos.latitude, pos.longitude);
    } catch (_) {
      throw const ErrorVeraGo('No pudimos obtener tu ubicación. Intenta desde el Zócalo.');
    }
  }
}
