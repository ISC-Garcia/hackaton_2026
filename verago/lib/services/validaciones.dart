/// Validaciones de formularios. Cada función devuelve null si el valor es
/// correcto, o el mensaje de error en español.
///
/// Estas validaciones son COMODIDAD (avisar rápido al usuario). La
/// seguridad real está en Supabase y en las reglas de la base de datos.
class Validaciones {
  /// Correo con forma algo@algo.algo
  static String? correo(String? v) {
    final t = (v ?? '').trim();
    final valido = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(t);
    return valido ? null : 'Escribe un correo válido (ej. nombre@correo.com)';
  }

  /// Contraseña segura: al menos 8 caracteres, con letras y números.
  static String? contrasenaSegura(String? v) {
    final t = v ?? '';
    if (t.length < 8) return 'Usa al menos 8 caracteres';
    if (!RegExp(r'[A-Za-zÁÉÍÓÚáéíóúÑñ]').hasMatch(t)) return 'Incluye al menos una letra';
    if (!RegExp(r'\d').hasMatch(t)) return 'Incluye al menos un número';
    return null;
  }

  /// Teléfono de 10 dígitos (se ignoran espacios y guiones).
  static String? telefono(String? v) {
    final digitos = (v ?? '').replaceAll(RegExp(r'[\s-]'), '');
    return RegExp(r'^\d{10}$').hasMatch(digitos) ? null : 'Escribe un teléfono de 10 dígitos';
  }

  /// Texto obligatorio con un mínimo de letras.
  static String? Function(String?) obligatorio(String campo, {int minimo = 2}) =>
      (v) => (v ?? '').trim().length < minimo ? 'Escribe $campo' : null;
}
