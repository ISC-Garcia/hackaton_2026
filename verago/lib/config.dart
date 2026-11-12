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

  /// ¿Están las dos claves? Si no, la app muestra cómo configurarlas.
  static bool get estaConfigurado =>
      supabaseUrl.isNotEmpty && supabaseKey.isNotEmpty;
}
