import 'package:flutter/services.dart';

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

  /// Teléfono: exactamente 10 números, sin espacios ni guiones.
  /// (El campo además solo deja escribir números, máximo 10: ver
  /// [soloDiezDigitos]).
  static String? telefono(String? v) {
    final t = (v ?? '').trim();
    if (!RegExp(r'^\d+$').hasMatch(t)) return 'Escribe solo números';
    return t.length == 10 ? null : 'El teléfono debe tener 10 números (llevas ${t.length})';
  }

  /// Formateadores para el campo de teléfono: solo dígitos y máximo 10.
  /// Un "formateador" filtra lo que el usuario teclea antes de mostrarlo.
  static final soloDiezDigitos = <TextInputFormatter>[
    FilteringTextInputFormatter.digitsOnly,
    LengthLimitingTextInputFormatter(10),
  ];

  /// Fechas de un evento: debe terminar después de iniciar y durar máximo 30 días.
  static String? fechasEvento(DateTime inicia, DateTime termina) {
    if (!termina.isAfter(inicia)) return 'El evento debe terminar después de iniciar.';
    if (termina.difference(inicia).inDays > 30) return 'Un evento no puede durar más de 30 días.';
    return null;
  }

  /// Evento que se repite: cada 1–60 días, de 2 a 30 veces, y que una fecha
  /// no se encime con la siguiente.
  static String? repeticion({required int? cadaDias, required int? veces, required Duration duracion}) {
    if (cadaDias == null || cadaDias < 1 || cadaDias > 60) return 'Repite cada 1 a 60 días.';
    if (veces == null || veces < 2 || veces > 30) return 'Elige de 2 a 30 veces.';
    if (duracion > Duration(days: cadaDias)) {
      return 'El evento dura más que el tiempo entre repeticiones: se enciman las fechas.';
    }
    return null;
  }

  /// Costo aproximado en pesos: solo números (puede quedar vacío = "Con costo").
  static String? costo(String? v) {
    final t = (v ?? '').trim();
    if (t.isEmpty) return null;
    return RegExp(r'^\d{1,6}$').hasMatch(t) ? null : 'Escribe solo números (pesos)';
  }

  /// Texto obligatorio con un mínimo de letras.
  static String? Function(String?) obligatorio(String campo, {int minimo = 2}) =>
      (v) => (v ?? '').trim().length < minimo ? 'Escribe $campo' : null;
}
