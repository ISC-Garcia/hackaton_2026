import 'package:shared_preferences/shared_preferences.dart';

/// Recuerda en el celular lo último que el visitante eligió para su ruta
/// (intereses y tiempo), aunque no tenga cuenta.
///
/// Usa `shared_preferences`: un pequeño almacén de "clave → valor" dentro
/// del celular. No se envía nada a internet.
class PreferenciasService {
  static const _claveIntereses = 'intereses';
  static const _claveMinutos = 'minutos';

  Future<Set<String>> leerIntereses() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_claveIntereses) ?? []).toSet();
  }

  Future<int?> leerMinutos() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_claveMinutos);
  }

  Future<void> guardar({required Set<String> intereses, required int minutos}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_claveIntereses, intereses.toList());
    await prefs.setInt(_claveMinutos, minutos);
  }
}
