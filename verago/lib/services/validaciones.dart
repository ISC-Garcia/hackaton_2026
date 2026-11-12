import 'package:flutter/services.dart';

import '../i18n/idioma.dart';

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
    return valido ? null : tr('Escribe un correo válido (ej. nombre@correo.com)');
  }

  /// Contraseña segura: al menos 8 caracteres, con letras y números.
  static String? contrasenaSegura(String? v) {
    final t = v ?? '';
    if (t.length < 8) return tr('Usa al menos 8 caracteres');
    if (!RegExp(r'[A-Za-zÁÉÍÓÚáéíóúÑñ]').hasMatch(t)) return tr('Incluye al menos una letra');
    if (!RegExp(r'\d').hasMatch(t)) return tr('Incluye al menos un número');
    return null;
  }

  /// Teléfono: exactamente 10 números, sin espacios ni guiones.
  /// (El campo además solo deja escribir números, máximo 10: ver
  /// [soloDiezDigitos]).
  static String? telefono(String? v) {
    final t = (v ?? '').trim();
    if (!RegExp(r'^\d+$').hasMatch(t)) return tr('Escribe solo números');
    return t.length == 10 ? null : tr('El teléfono debe tener 10 números (llevas {length})', {'length': t.length});
  }

  /// Formateadores para el campo de teléfono: solo dígitos y máximo 10.
  /// Un "formateador" filtra lo que el usuario teclea antes de mostrarlo.
  static final soloDiezDigitos = <TextInputFormatter>[
    FilteringTextInputFormatter.digitsOnly,
    LengthLimitingTextInputFormatter(10),
  ];

  /// Fechas de un evento: debe terminar después de iniciar y durar máximo 30 días.
  static String? fechasEvento(DateTime inicia, DateTime termina) {
    if (!termina.isAfter(inicia)) return tr('El evento debe terminar después de iniciar.');
    if (termina.difference(inicia).inDays > 30) return tr('Un evento no puede durar más de 30 días.');
    return null;
  }

  /// Evento que se repite: cada 1–60 días, de 2 a 30 veces, y que una fecha
  /// no se encime con la siguiente.
  static String? repeticion({required int? cadaDias, required int? veces, required Duration duracion}) {
    if (cadaDias == null || cadaDias < 1 || cadaDias > 60) return tr('Repite cada 1 a 60 días.');
    if (veces == null || veces < 2 || veces > 30) return tr('Elige de 2 a 30 veces.');
    if (duracion > Duration(days: cadaDias)) {
      return tr('El evento dura más que el tiempo entre repeticiones: se enciman las fechas.');
    }
    return null;
  }

  /// Costo aproximado en pesos: solo números (puede quedar vacío = "Con costo").
  static String? costo(String? v) {
    final t = (v ?? '').trim();
    if (t.isEmpty) return null;
    return RegExp(r'^\d{1,6}$').hasMatch(t) ? null : tr('Escribe solo números (pesos)');
  }

  /// Texto obligatorio con un mínimo de letras.
  static String? Function(String?) obligatorio(String campo, {int minimo = 2}) =>
      (v) => (v ?? '').trim().length < minimo ? tr('Escribe {campo}', {'campo': campo}) : null;

  // ==================================================================
  // RESTRICCIONES POR TIPO DE CAMPO
  // Dos piezas por campo:
  //  - FORMATEADOR (`TextInputFormatter`): no deja ESCRIBIR lo que no va
  //    (ej. números en un nombre de persona).
  //  - VALIDADOR: al guardar, revisa lo que quedó (largo, que tenga letras).
  // ==================================================================

  /// Letras del español (y otras con acento: À-ÿ), sin números.
  static const _letras = r'A-Za-zÀ-ÿ';
  static final _tieneLetra = RegExp('[$_letras]');

  /// NOMBRE DE PERSONA: solo letras, espacios, apóstrofo, guion y punto
  /// (ej. "María José O'Neil", "Juan Pérez-Gil"). Sin números. Máx. 60.
  static final nombrePersonaFormato = <TextInputFormatter>[
    // El guion va al final de los corchetes para que sea un guion y no un rango.
    FilteringTextInputFormatter.allow(RegExp('[$_letras' " '.-]")),
    LengthLimitingTextInputFormatter(60),
  ];

  /// `completo` = pide nombre y apellido (al menos 2 palabras).
  static String? Function(String?) nombrePersona({bool completo = false}) => (v) {
        final t = (v ?? '').trim();
        if (RegExp(r'\d').hasMatch(t)) return tr('El nombre no lleva números');
        final letras = RegExp('[$_letras]').allMatches(t).length;
        if (letras < 2) return completo ? tr('Escribe tu nombre completo') : tr('Escribe tu nombre');
        if (!RegExp('^[$_letras]').hasMatch(t)) return tr('El nombre debe empezar con una letra');
        if (completo && t.split(RegExp(r'\s+')).where((p) => p.length >= 2).length < 2) {
          return tr('Escribe nombre y apellido');
        }
        return null;
      };

  /// NOMBRE DE NEGOCIO, LUGAR, PRODUCTO O EVENTO: letras, NÚMEROS y signos
  /// comunes (ej. "Café 2 Hermanos", "La Parroquia #3", "Taco & Co.").
  static List<TextInputFormatter> nombreNegocioFormato({int maximo = 60}) => [
        FilteringTextInputFormatter.allow(RegExp('[$_letras' r"""0-9 &'.,#°!¡?¿()/+:"-]""")),
        LengthLimitingTextInputFormatter(maximo),
      ];

  /// Debe tener al menos 2 letras (no solo números o signos).
  static String? Function(String?) nombreNegocio(String campo, {int maximo = 60}) => (v) {
        final t = (v ?? '').trim();
        if (t.length < 2) return tr('Escribe {campo}', {'campo': campo});
        if (t.length > maximo) return tr('Máximo {maximo} caracteres', {'maximo': maximo});
        if (RegExp('[$_letras]').allMatches(t).length < 2) return tr('{campo} debe llevar letras', {'campo': campo});
        return null;
      };

  /// DIRECCIÓN: letras, números y signos de direcciones (#, °, /, -, comas).
  static final direccionFormato = <TextInputFormatter>[
    FilteringTextInputFormatter.allow(RegExp('[$_letras' r'0-9 .,#°/()-]')),
    LengthLimitingTextInputFormatter(150),
  ];

  /// Al menos 5 caracteres y con letras. Es flexible porque la dirección
  /// también se llena sola desde el mapa (Nominatim).
  static String? Function(String?) direccion({bool opcional = false}) => (v) {
        final t = (v ?? '').trim();
        if (t.isEmpty && opcional) return null;
        if (t.length < 5) return tr('Escribe la dirección');
        if (!_tieneLetra.hasMatch(t)) return tr('La dirección debe llevar el nombre de la calle');
        return null;
      };

  /// TEXTO LIBRE (descripción, promoción): cualquier carácter, pero con un
  /// mínimo de letras para que no sea solo números o signos.
  static String? Function(String?) textoConLetras(String campo, {int minimo = 10, bool opcional = false}) => (v) {
        final t = (v ?? '').trim();
        if (t.isEmpty && opcional) return null;
        if (t.length < minimo) return tr('Escribe {campo} (al menos {minimo} caracteres)', {'campo': campo, 'minimo': minimo});
        if (RegExp('[$_letras]').allMatches(t).length < 3) return tr('{campo} debe llevar palabras', {'campo': campo});
        return null;
      };

  /// SOLO NÚMEROS (precios, costos, días): no deja escribir letras.
  static List<TextInputFormatter> soloNumeros(int maxDigitos) => [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(maxDigitos),
      ];

  /// Precio en pesos de 0 a `maximo` (igual que la base de datos: 100 000).
  static String? Function(String?) precio({bool opcional = true, int maximo = 100000}) => (v) {
        final t = (v ?? '').trim();
        if (t.isEmpty) return opcional ? null : tr('Escribe el precio');
        final n = int.tryParse(t);
        if (n == null) return tr('Escribe solo números (pesos)');
        if (n > maximo) return tr('Máximo \${maximo}', {'maximo': maximo});
        return null;
      };

  /// CORREO: sin espacios y máximo 254 caracteres (límite de los correos).
  static final correoFormato = <TextInputFormatter>[
    FilteringTextInputFormatter.deny(RegExp(r'\s')),
    LengthLimitingTextInputFormatter(254),
  ];

  /// CONTRASEÑA: máximo 72 caracteres (límite del sistema que la cifra).
  static final contrasenaFormato = <TextInputFormatter>[LengthLimitingTextInputFormatter(72)];

  /// CÓDIGO DEL QR escrito a mano: "VG-" + 32 letras/números (a-f, 0-9).
  static final codigoQrFormato = <TextInputFormatter>[
    FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9\-]')),
    LengthLimitingTextInputFormatter(35),
  ];

  static String? codigoQr(String? v) {
    final t = normalizarCodigo(v ?? '');
    return RegExp(r'^VG-[0-9a-f]{32}$').hasMatch(t) ? null : tr('El código empieza con VG- y tiene 32 letras y números');
  }

  /// "vg-ABC…" → "VG-abc…" (así lo guarda la base de datos).
  static String normalizarCodigo(String codigo) {
    final t = codigo.trim();
    if (t.length > 3 && t.substring(0, 3).toUpperCase() == 'VG-') return 'VG-${t.substring(3).toLowerCase()}';
    return t;
  }
}
