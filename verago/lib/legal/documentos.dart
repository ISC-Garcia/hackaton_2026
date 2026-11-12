/// DOCUMENTOS LEGALES Y DE CONFIANZA de VeraGo.
///
/// Qué es: el texto del Aviso de privacidad, los Términos (turistas y
/// negocios), las Reglas operativas y "¿Cómo funciona VeraGo?".
/// Por qué está en un archivo de Dart y no en la base de datos: son textos
/// fijos; así se leen sin internet y se revisan en un solo lugar.
///
/// IMPORTANTE: son textos de un proyecto de hackatón. Antes de usar VeraGo
/// con personas y negocios reales, un abogado debe revisarlos.
library;

/// Una sección del documento: título y párrafos.
class SeccionDocumento {
  const SeccionDocumento(this.titulo, this.parrafos);
  final String titulo;
  final List<String> parrafos;
}

/// Un documento completo.
class DocumentoLegal {
  const DocumentoLegal({
    required this.titulo,
    required this.resumen,
    required this.secciones,
  });

  final String titulo;

  /// Una línea que explica de qué trata (se ve en la lista de Ajustes).
  final String resumen;
  final List<SeccionDocumento> secciones;

  /// Cambiar al modificar cualquier documento.
  static const version = 'Versión 1 · 11 de noviembre de 2026';
}

class Documentos {
  // ------------------------------------------------------------------
  // AVISO DE PRIVACIDAD
  // ------------------------------------------------------------------
  static const avisoPrivacidad = DocumentoLegal(
    titulo: 'Aviso de privacidad',
    resumen: 'Qué datos pedimos, para qué y cómo puedes corregirlos o borrarlos.',
    secciones: [
      SeccionDocumento('Quiénes somos', [
        'VeraGo es un proyecto estudiantil de turismo para el Centro Histórico de Veracruz. '
            'El equipo de VeraGo es responsable de cuidar los datos que se registran en la app.',
      ]),
      SeccionDocumento('Datos que pedimos a los turistas', [
        '• Nombre y correo electrónico, para crear tu cuenta.',
        '• Contraseña: la guarda nuestro proveedor (Supabase) de forma cifrada; nadie del equipo puede verla.',
        '• Tus sellos: qué lugar visitaste y la fecha y hora en que escaneaste su QR.',
      ]),
      SeccionDocumento('Datos que pedimos a los negocios', [
        '• Del negocio: nombre comercial, descripción, teléfono, dirección, ubicación en el mapa, '
            'categoría o giro y horario. Estos datos SÍ se muestran a los turistas en la app.',
        '• Del encargado: nombre completo y correo. El nombre solo lo ve el equipo de VeraGo.',
      ]),
      SeccionDocumento('Qué NO guardamos', [
        '• Tu ubicación. Solo se usa dentro de tu celular para iniciar una ruta, y solo si eliges '
            '"Mi ubicación". No te seguimos en segundo plano.',
        '• Tus intereses y el tiempo de tu última ruta se guardan solo en tu celular.',
        '• No usamos publicidad, no vendemos ni rentamos datos y no hacemos perfiles de tus gustos.',
      ]),
      SeccionDocumento('Para qué usamos tus datos', [
        '• Darte acceso a tu cuenta y a tu pasaporte de sellos.',
        '• Mostrar los negocios aprobados a los turistas.',
        '• Revisar solicitudes de negocios y prevenir trampas con los sellos.',
        '• Contactar a un negocio sobre su solicitud.',
      ]),
      SeccionDocumento('Con quién se comparten', [
        '• Supabase: el servicio donde se guarda la base de datos de VeraGo.',
        '• OpenStreetMap: de ahí se descargan los mapas, como al abrir cualquier página web. '
            'Para llenar la dirección de un negocio, solo enviamos las coordenadas del negocio, '
            'nunca la ubicación del turista.',
        'No compartimos tus datos con nadie más, salvo que una autoridad lo pida conforme a la ley.',
      ]),
      SeccionDocumento('Tus derechos (ARCO)', [
        'Puedes pedir Acceso a tus datos, su Rectificación (corregirlos), su Cancelación (borrarlos) '
            'u Oposición a su uso. Escríbenos desde el correo de tu cuenta (ver "Contacto").',
        'Tu nombre lo puedes cambiar tú mismo en Ajustes. Si pides borrar tu cuenta, se borran '
            'también tu perfil y tus sellos.',
      ]),
      SeccionDocumento('Cuánto tiempo guardamos los datos', [
        'Mientras tu cuenta exista. Al borrarla, se eliminan tus datos de la base de datos.',
      ]),
      SeccionDocumento('Cambios a este aviso', [
        'Si cambia este aviso, lo actualizaremos en la app con su nueva versión y fecha.',
      ]),
    ],
  );

  // ------------------------------------------------------------------
  // TÉRMINOS DE USO (TURISTAS)
  // ------------------------------------------------------------------
  static const terminosUso = DocumentoLegal(
    titulo: 'Términos de uso',
    resumen: 'Las reglas para usar VeraGo como turista.',
    secciones: [
      SeccionDocumento('Aceptación', [
        'Al crear una cuenta o usar VeraGo aceptas estos términos y el Aviso de privacidad.',
      ]),
      SeccionDocumento('Información de la app', [
        '• Los lugares públicos (plazas, museos, monumentos) usan su nombre real. Sus horarios y '
            'precios no siempre están disponibles: confírmalos en el lugar.',
        '• Los comercios y eventos marcados como "Ficticio · demostración" no son reales.',
        '• Las ubicaciones y tiempos de caminata son aproximados.',
      ]),
      SeccionDocumento('Rutas', [
        'Las rutas son sugerencias. Camina con precaución, respeta las señales de tránsito y '
            'cuida tus pertenencias. VeraGo no se hace responsable de lo que pase durante tu recorrido.',
      ]),
      SeccionDocumento('Tu cuenta', [
        '• Usa datos verdaderos y una sola cuenta por persona.',
        '• Cuida tu contraseña; eres responsable de lo que se haga con tu cuenta.',
      ]),
      SeccionDocumento('Pasaporte y sellos', [
        '• Los sellos son un recuerdo de tu visita: no tienen valor en dinero, no se canjean por '
            'premios y no se pueden pasar a otra persona.',
        '• Solo los negocios formales dan sellos, y máximo uno por negocio al día.',
        '• Está prohibido hacer trampa: compartir códigos, usar capturas de pantalla del QR o '
            'programas para generar sellos. Si pasa, podemos borrar esos sellos o la cuenta.',
      ]),
      SeccionDocumento('Uso correcto', [
        'No intentes entrar a cuentas ajenas, alterar la app ni dañar el servicio.',
      ]),
      SeccionDocumento('Cambios', [
        'Podemos actualizar estos términos; la versión y la fecha siempre se ven al final del documento.',
      ]),
    ],
  );

  // ------------------------------------------------------------------
  // TÉRMINOS PARA NEGOCIOS
  // ------------------------------------------------------------------
  static const terminosNegocios = DocumentoLegal(
    titulo: 'Términos para negocios',
    resumen: 'Lo que acepta un negocio al registrarse en VeraGo.',
    secciones: [
      SeccionDocumento('Registro y revisión', [
        '• Los datos del negocio y del encargado deben ser verdaderos.',
        '• Cada cuenta puede registrar un solo negocio y cada nombre comercial se registra una sola vez.',
        '• Toda solicitud queda pendiente hasta que el equipo de VeraGo la revise. VeraGo puede '
            'aprobarla o rechazarla, y te avisará por teléfono o correo.',
      ]),
      SeccionDocumento('Lo que se publica', [
        'Al aprobarse, los turistas ven: nombre comercial, descripción, teléfono, dirección, '
            'ubicación en el mapa y horario. El nombre del encargado no se publica.',
      ]),
      SeccionDocumento('Negocios formales (local propio)', [
        '• La ubicación marcada en el mapa debe ser la de tu local.',
        '• Puedes editar descripción, teléfono y horario. Un cambio de ubicación o dirección '
            'necesita la aprobación de VeraGo; mientras tanto, tu negocio sigue en su ubicación actual.',
        '• Puedes mostrar tu QR para que los turistas ganen su sello.',
      ]),
      SeccionDocumento('Negocios en un Punto VeraGo (no formales)', [
        '• Solo hay un negocio de cada giro en cada Punto VeraGo.',
        '• El horario lo asigna VeraGo según el horario del punto.',
        '• El uso y el pago del espacio se acuerdan directamente con el equipo de VeraGo, fuera de la app. '
            'La app no cobra ni procesa pagos.',
        '• Estos negocios no dan sellos del pasaporte.',
        '• Puedes pedir cambiarte a otro Punto VeraGo si tu giro está libre ahí; VeraGo debe aprobarlo.',
      ]),
      SeccionDocumento('Uso del QR', [
        '• El QR cambia cada 60 segundos: muéstralo en tu celular, no lo compartas en capturas ni redes.',
        '• No te des sellos a ti mismo ni a cuentas de tu negocio.',
      ]),
      SeccionDocumento('Contenido', [
        'La descripción no puede ser ofensiva, engañosa ni anunciar productos ilegales. '
            'Tu negocio es responsable de los productos y servicios que ofrece.',
      ]),
      SeccionDocumento('Suspensión', [
        'VeraGo puede suspender un negocio por datos falsos, trampas con los sellos, quejas '
            'comprobadas, cierre del negocio o falta de pago del espacio en un Punto VeraGo. '
            'Un negocio suspendido deja de verse en la app y puede reactivarse si se corrige el problema.',
      ]),
    ],
  );

  // ------------------------------------------------------------------
  // REGLAS OPERATIVAS
  // ------------------------------------------------------------------
  static const reglasOperativas = DocumentoLegal(
    titulo: 'Reglas operativas',
    resumen: 'Cómo trabaja VeraGo: aprobaciones, sellos, cambios y reportes.',
    secciones: [
      SeccionDocumento('1. Alta de un negocio', [
        '1) El negocio se registra en "Soy un negocio" y acepta los Términos para negocios.',
        '2) Queda PENDIENTE y no se ve en la app.',
        '3) El equipo de VeraGo revisa: que los datos sean completos, que la dirección escrita '
            'coincida con la del mapa y, en un Punto VeraGo, que el giro esté libre y el espacio acordado.',
        '4) Se APRUEBA (aparece en la app) o se RECHAZA, y se avisa al negocio por teléfono o correo.',
      ]),
      SeccionDocumento('2. Cambios de ubicación', [
        'El negocio pide el cambio desde su panel. Sigue visible en su ubicación actual hasta que '
            'VeraGo acepte o rechace el cambio.',
      ]),
      SeccionDocumento('3. Sellos', [
        '• Solo los negocios formales aprobados dan sellos.',
        '• Un turista puede ganar un sello por negocio al día.',
        '• El QR cambia cada 60 segundos y lo valida la base de datos, no el celular.',
        '• Un comerciante no puede darse sellos de su propio negocio.',
      ]),
      SeccionDocumento('4. Suspensiones', [
        'Por datos falsos, trampas con los sellos, quejas comprobadas, cierre o falta de pago del '
            'espacio. Se avisa al negocio y puede reactivarse al corregir el problema.',
      ]),
      SeccionDocumento('5. Lugares públicos y eventos', [
        '• Los lugares públicos usan su nombre real; no inventamos horarios ni precios.',
        '• Los eventos los publica el equipo de VeraGo; el costo que se muestra es aproximado.',
      ]),
      SeccionDocumento('6. Reportes', [
        'Cualquier persona puede reportar un problema desde la ficha de un lugar '
            '("Reportar un problema"). El equipo lo revisa y, si procede, corrige la información '
            'o habla con el negocio.',
      ]),
    ],
  );

  // ------------------------------------------------------------------
  // ¿CÓMO FUNCIONA VERAGO?
  // ------------------------------------------------------------------
  static const comoFunciona = DocumentoLegal(
    titulo: '¿Cómo funciona VeraGo?',
    resumen: 'Por qué puedes confiar en los sellos, los negocios y tus datos.',
    secciones: [
      SeccionDocumento('Los negocios se revisan', [
        'Ningún negocio aparece en la app sin que el equipo de VeraGo revise sus datos y su ubicación. '
            'Si algo no cuadra, puedes reportarlo desde su ficha.',
      ]),
      SeccionDocumento('El QR es seguro', [
        'El código del negocio cambia cada 60 segundos, así que una foto vieja no sirve. '
            'Quien valida el sello es la base de datos, no tu celular, y solo da un sello por negocio al día.',
      ]),
      SeccionDocumento('Qué vale un sello', [
        'Es un recuerdo de tu visita a un negocio local. No tiene valor en dinero ni se canjea por premios.',
      ]),
      SeccionDocumento('De dónde salen los datos', [
        '• Lugares públicos: nombres reales del Centro Histórico, sin horarios ni precios inventados.',
        '• Comercios y eventos de demostración: son ficticios y lo dicen en su etiqueta.',
        '• Mapas: OpenStreetMap. Las distancias y tiempos son aproximados.',
      ]),
      SeccionDocumento('Cómo se arma tu ruta', [
        'Tu celular elige los lugares de lo que te interesa que alcanzas a visitar en tu tiempo y '
            'que están abiertos, e incluye siempre un comercio local y un Punto VeraGo para apoyar '
            'a los negocios del centro.',
      ]),
      SeccionDocumento('Tu privacidad', [
        'No guardamos tu ubicación ni te seguimos. Solo guardamos tu nombre, tu correo y tus sellos. '
            'Más detalles en el Aviso de privacidad.',
      ]),
    ],
  );

  /// Orden en que se muestran en Ajustes.
  static const todos = [comoFunciona, reglasOperativas, terminosUso, terminosNegocios, avisoPrivacidad];
}
