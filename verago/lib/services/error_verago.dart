/// Error con un mensaje claro en español para mostrar al usuario.
///
/// Por qué existe: los servicios atrapan los errores técnicos (de red o de
/// la base de datos) y los convierten en este error con un texto amable.
/// Así ninguna pantalla muestra mensajes técnicos ni datos internos.
class ErrorVeraGo implements Exception {
  const ErrorVeraGo(this.mensaje);
  final String mensaje;

  @override
  String toString() => mensaje;
}
