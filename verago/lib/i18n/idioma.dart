import 'package:flutter/foundation.dart' show ValueNotifier;
import 'package:shared_preferences/shared_preferences.dart';

import 'traducciones.dart';

/// IDIOMA DE LA APP (reto "Atraca un crucero": visitantes que no hablan español).
///
/// Qué es: un diccionario propio, sin paquetes nuevos.
/// - Los textos de la app se escriben en español dentro de `tr('...')`.
/// - `traducciones.dart` tiene, para cada texto en español, su versión en
///   inglés, francés, alemán y portugués.
/// - `tr` busca el texto en el idioma elegido; si no lo encuentra, deja el
///   español (la app nunca se queda sin texto).
///
/// Variables dentro del texto: se escriben entre llaves y se pasan aparte.
///   tr('Visita sugerida: {min} min', {'min': 30})
///
/// El idioma elegido se guarda en el celular (shared_preferences).
/// Las pantallas de comerciante y de administración se quedan en español:
/// las usan personas de Veracruz.
class Idioma {
  /// Idiomas disponibles: código → nombre (escrito en su propio idioma).
  static const disponibles = {
    'es': 'Español',
    'en': 'English',
    'fr': 'Français',
    'de': 'Deutsch',
    'pt': 'Português',
  };

  /// Nombre del idioma en inglés (para pedirle traducciones a Gemini).
  static const nombreParaIa = {
    'es': 'Spanish',
    'en': 'English',
    'fr': 'French',
    'de': 'German',
    'pt': 'Portuguese',
  };

  /// Orden de las traducciones en cada lista de `traducciones.dart`.
  static const orden = ['en', 'fr', 'de', 'pt'];

  /// Idioma actual. `ValueNotifier` = cajita que avisa cuando cambia.
  static final actual = ValueNotifier<String>('es');

  static const _clave = 'idioma';

  static String get codigo => actual.value;
  static bool get esEspanol => actual.value == 'es';

  /// Lee el idioma guardado (al abrir la app).
  static Future<void> cargar() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final guardado = prefs.getString(_clave);
      if (guardado != null && disponibles.containsKey(guardado)) actual.value = guardado;
    } catch (_) {
      // Sin almacenamiento (ej. modo privado del navegador): se queda en español.
    }
  }

  /// Cambia y guarda el idioma.
  static Future<void> cambiar(String codigo) async {
    if (!disponibles.containsKey(codigo)) return;
    actual.value = codigo;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_clave, codigo);
    } catch (_) {}
  }

  /// Nombres de días y meses (para fechas como "sábado 14 de noviembre").
  static const _dias = {
    'es': ['domingo', 'lunes', 'martes', 'miércoles', 'jueves', 'viernes', 'sábado'],
    'en': ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'],
    'fr': ['dimanche', 'lundi', 'mardi', 'mercredi', 'jeudi', 'vendredi', 'samedi'],
    'de': ['Sonntag', 'Montag', 'Dienstag', 'Mittwoch', 'Donnerstag', 'Freitag', 'Samstag'],
    'pt': ['domingo', 'segunda-feira', 'terça-feira', 'quarta-feira', 'quinta-feira', 'sexta-feira', 'sábado'],
  };
  static const _meses = {
    'es': ['enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio', 'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'],
    'en': ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'],
    'fr': ['janvier', 'février', 'mars', 'avril', 'mai', 'juin', 'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre'],
    'de': ['Januar', 'Februar', 'März', 'April', 'Mai', 'Juni', 'Juli', 'August', 'September', 'Oktober', 'November', 'Dezember'],
    'pt': ['janeiro', 'fevereiro', 'março', 'abril', 'maio', 'junho', 'julho', 'agosto', 'setembro', 'outubro', 'novembro', 'dezembro'],
  };

  /// Día de la semana: 0 = domingo … 6 = sábado.
  static String dia(int indice) => _dias[codigo]![indice % 7];

  /// Mes: 1 = enero … 12 = diciembre.
  static String mes(int numero) => _meses[codigo]![numero - 1];

  /// "sábado 14 de noviembre" / "Saturday, November 14" / ...
  static String fechaLarga(DateTime f) {
    final d = dia(f.weekday % 7);
    final m = mes(f.month);
    return switch (codigo) {
      'en' => '$d, $m ${f.day}',
      'de' => '$d, ${f.day}. $m',
      'fr' => '$d ${f.day} $m',
      'pt' => '$d, ${f.day} de $m',
      _ => '$d ${f.day} de $m',
    };
  }
}

/// Traduce un texto escrito en español al idioma actual.
String tr(String espanol, [Map<String, Object?> datos = const {}]) {
  var texto = espanol;
  final i = Idioma.orden.indexOf(Idioma.actual.value);
  if (i >= 0) {
    final t = traducciones[espanol];
    if (t != null && i < t.length) texto = t[i];
  }
  datos.forEach((clave, valor) => texto = texto.replaceAll('{$clave}', '$valor'));
  return texto;
}
