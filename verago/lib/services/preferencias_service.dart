import 'package:shared_preferences/shared_preferences.dart';

/// Recuerda en el celular datos pequeños, aunque el visitante no tenga cuenta:
/// - si ya vio la pantalla de bienvenida,
/// - sus intereses y el tiempo de su última ruta.
///
/// Usa `shared_preferences`: un pequeño almacén de "clave → valor" dentro
/// del celular. No se envía nada a internet.
class PreferenciasService {
  static const _claveIntereses = 'intereses';
  static const _claveMinutos = 'minutos';
  static const _claveBienvenida = 'bienvenida_vista';

  Future<bool> bienvenidaVista() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_claveBienvenida) ?? false;
  }

  Future<void> marcarBienvenidaVista() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_claveBienvenida, true);
  }

  Future<Set<String>> leerIntereses() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_claveIntereses) ?? []).toSet();
  }

  Future<void> guardarIntereses(Set<String> intereses) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_claveIntereses, intereses.toList());
  }

  Future<int?> leerMinutos() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_claveMinutos);
  }

  Future<void> guardar({required Set<String> intereses, required int minutos}) async {
    await guardarIntereses(intereses);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_claveMinutos, minutos);
  }
}
