/// Configuración de VeraGo.
///
/// Qué hace: lee la URL y la clave pública de Supabase.
/// De dónde salen: del archivo `env.json` (que NO se sube a GitHub),
/// pasado al ejecutar:
///
///   flutter run --dart-define-from-file=env.json
///
/// `String.fromEnvironment` lee esos valores cuando se compila la app.
class Config {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');

  /// Clave PÚBLICA (publishable / anon). Está bien que vaya en la app:
  /// lo que protege los datos son las reglas RLS de la base de datos.
  /// La clave secreta (service_role) NUNCA va aquí.
  static const supabaseKey = String.fromEnvironment('SUPABASE_KEY');

  /// Correo del equipo: contraseña olvidada, reportes y derechos ARCO.
  /// No es secreto, así que tiene valor por defecto (todos lo reciben aunque
  /// su env.json no lo traiga). Se puede cambiar con "SOPORTE_CORREO".
  static const correoSoporte = String.fromEnvironment('SOPORTE_CORREO', defaultValue: 'ververagoo@gmail.com');

  /// CHAT "Pregúntale a VeraGo" (IA de Google Gemini).
  /// La clave va en env.json como "GEMINI_API_KEY" (env.json NO se sube a
  /// GitHub). OJO: queda dentro de la app compilada, por eso debe estar
  /// RESTRINGIDA en Google (solo la API de Gemini y, en web, su dominio).
  /// Acepta "GEMINI_API_KEY" o "GEMINI_KEY" (el equipo usó este nombre).
  static const _geminiApiKey = String.fromEnvironment('GEMINI_API_KEY');
  static const _geminiKey = String.fromEnvironment('GEMINI_KEY');
  static String get geminiApiKey => (_geminiApiKey.isNotEmpty ? _geminiApiKey : _geminiKey).trim();

  /// Modelo de Gemini. Se puede cambiar sin tocar código ("GEMINI_MODELO").
  /// Por defecto "gemini-flash-lite-latest": un ALIAS que Google actualiza
  /// solo al modelo ligero más nuevo (los nombres fijos como
  /// "gemini-2.5-flash" dejan de estar disponibles). Probado: ~1.5 s.
  static const geminiModelo = String.fromEnvironment('GEMINI_MODELO', defaultValue: 'gemini-flash-lite-latest');

  static bool get chatConfigurado => geminiApiKey.isNotEmpty;

  /// ¿Están las dos claves? Si no, la app muestra cómo configurarlas.
  static bool get estaConfigurado =>
      supabaseUrl.isNotEmpty && supabaseKey.isNotEmpty;
}
