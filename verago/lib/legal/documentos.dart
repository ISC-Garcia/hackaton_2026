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
  static const version = 'Versión 7 · 12 de noviembre de 2026';
}

class Documentos {
  // ==================================================================
  // TÉRMINOS DE USO (TURISTAS)
  // ==================================================================
  static const terminosUso = DocumentoLegal(
    titulo: 'Términos de uso',
    resumen: 'Las reglas para usar VeraGo como turista, tu seguridad y nuestra responsabilidad.',
    secciones: [
      SeccionDocumento('1. Aceptación', [
        'Al crear una cuenta o usar VeraGo aceptas estos Términos y el Aviso de privacidad. '
            'Si no estás de acuerdo, no uses la app.',
      ]),
      SeccionDocumento('2. Qué es VeraGo', [
        'VeraGo es una app gratuita de turismo para el Centro Histórico de Veracruz, hecha como '
            'proyecto estudiantil. Te ayuda a descubrir lugares, armar rutas a pie, ver eventos y '
            'juntar sellos de negocios locales.',
        'VeraGo es una guía informativa: no es agencia de viajes, ni guía de turistas, ni '
            'servicio de transporte, seguridad o emergencias.',
      ]),
      SeccionDocumento('3. Tu cuenta', [
        '• Usa datos verdaderos y una sola cuenta por persona.',
        '• Cuida tu contraseña: eres responsable de lo que se haga con tu cuenta.',
        '• Si pierdes tu celular o te lo roban, avísanos para proteger tu cuenta '
            '(ver el Aviso de privacidad).',
      ]),
      SeccionDocumento('4. Información de la app', [
        '• Los lugares públicos (plazas, museos, monumentos) usan su nombre real. Sus horarios y '
            'precios no siempre están disponibles: confírmalos en el lugar.',
        '• Los datos de los negocios (horario, descripción, costo de entrada) los da cada negocio.',
        '• Los comercios y eventos marcados como "Ficticio · demostración" no son reales.',
        '• Las ubicaciones, distancias, caminos y tiempos de caminata son aproximados.',
        '• "Pregúntale a VeraGo" usa inteligencia artificial (Google Gemini): sus respuestas pueden '
            'equivocarse. Confirma horarios, precios y datos importantes en el lugar.',
      ]),
      SeccionDocumento('5. Rutas y recorridos', [
        'Las rutas son SUGERENCIAS. Tú decides si las sigues, por dónde caminas y a qué hora. '
            'El camino dibujado puede no reflejar obras, calles cerradas, eventos ni zonas que '
            'convenga evitar a ciertas horas.',
      ]),
      SeccionDocumento('6. Tu seguridad', [
        '• Camina por calles concurridas e iluminadas y, de preferencia, de día.',
        '• Cuida tus pertenencias y evita mostrar objetos de valor o usar el celular al cruzar.',
        '• Respeta las señales y semáforos; cruza por las esquinas y pasos peatonales.',
        '• Lleva agua y protégete del sol y del calor.',
        '• En una emergencia, llama al 911. VeraGo tiene un botón rojo "911" en Explorar y en la '
            'ruta que solo abre la app de llamadas de tu celular con el número escrito: VeraGo no '
            'hace la llamada por ti, no avisa a nadie y no comparte tu ubicación con autoridades.',
      ]),
      SeccionDocumento('7. Limitación de responsabilidad', [
        'VeraGo y su equipo NO se hacen responsables de:',
        '• Accidentes, caídas, lesiones o problemas de salud durante un recorrido o una visita.',
        '• Asaltos, robos, extravíos o daños a tus pertenencias, dentro o fuera de los lugares '
            'que muestra la app.',
        '• Actos de otras personas, condiciones del clima, del tránsito o de las calles '
            '(obras, banquetas, iluminación).',
        '• Los productos, servicios, precios, trato o instalaciones de los negocios, ni los '
            'pagos que hagas con ellos.',
        '• Cierres, cambios de horario o de precio, ni cancelación de eventos.',
        '• Fallas de internet, del GPS, del celular o de la app.',
        'Todo lo que pase fuera de la app (en la calle, en un negocio o en un evento) es '
            'responsabilidad de cada persona y, en su caso, de quien preste el servicio. Si sufres '
            'un delito, denúncialo ante las autoridades.',
      ]),
      SeccionDocumento('8. Pasaporte y sellos', [
        '• Los sellos son un recuerdo de tu visita: no tienen valor en dinero, no se canjean por '
            'premios y no se pueden pasar a otra persona.',
        '• Solo los negocios formales dan sellos, y máximo uno por negocio al día.',
      ]),
      SeccionDocumento('9. Uso prohibido', [
        '• Hacer trampa con los sellos: compartir códigos, usar capturas del QR o programas.',
        '• Entrar a cuentas ajenas, alterar la app o dañar el servicio.',
        '• Hacer reportes falsos o usar la app para molestar a negocios o personas.',
        'Si pasa, podemos borrar esos sellos, suspender o borrar la cuenta.',
      ]),
      SeccionDocumento('10. Menores de edad', [
        'Si tienes menos de 18 años, usa VeraGo con permiso y supervisión de tu madre, padre o tutor, '
            'sobre todo al seguir una ruta.',
      ]),
      SeccionDocumento('11. Cambios y ley aplicable', [
        'Podemos actualizar estos Términos; la versión y la fecha se ven al final. Se rigen por las '
            'leyes de México.',
      ]),
    ],
  );

  // ==================================================================
  // AVISO DE PRIVACIDAD
  // ==================================================================
  static const avisoPrivacidad = DocumentoLegal(
    titulo: 'Aviso de privacidad',
    resumen: 'Qué datos pedimos, para qué, con quién se comparten y cómo corregirlos o borrarlos.',
    secciones: [
      SeccionDocumento('1. Responsable', [
        'El equipo de VeraGo (proyecto estudiantil de turismo del Centro Histórico de Veracruz) es '
            'responsable de cuidar los datos que se registran en la app.',
      ]),
      SeccionDocumento('2. Datos que pedimos', [
        'Turistas:',
        '• Nombre y correo electrónico, para tu cuenta.',
        '• Contraseña: la guarda nuestro proveedor (Supabase) cifrada; nadie del equipo puede verla.',
        '• Tus sellos: qué negocio visitaste y la fecha y hora en que escaneaste su QR.',
        'Negocios:',
        '• Del negocio: nombre comercial, descripción, teléfono, dirección, ubicación en el mapa, '
            'categoría o giro, horario, costo de entrada y foto. Estos datos SÍ se muestran a los turistas.',
        '• Del encargado: nombre completo y correo. El nombre solo lo ve el equipo de VeraGo.',
      ]),
      SeccionDocumento('3. Datos que NO pedimos ni guardamos', [
        '• Datos sensibles (salud, religión, origen, etc.), ni datos bancarios o de tarjetas: '
            'la app no cobra nada.',
        '• Tu ubicación no se guarda (ver punto 5).',
        '• No usamos publicidad, no vendemos ni rentamos datos y no hacemos perfiles de tus gustos.',
      ]),
      SeccionDocumento('4. Para qué usamos tus datos', [
        '• Darte acceso a tu cuenta y a tu pasaporte de sellos.',
        '• Mostrar los negocios aprobados a los turistas.',
        '• Revisar solicitudes de negocios, atender reportes y prevenir trampas con los sellos.',
        '• Contactar a un negocio sobre su solicitud.',
        'No usamos tus datos para ningún otro fin.',
      ]),
      SeccionDocumento('5. Tu ubicación', [
        'Se toma una vez cuando la app la necesita y no te seguimos en segundo plano:',
        '• Al abrir Explorar (o al tocar "Mostrar dónde estoy"), la app te pide permiso. Si aceptas, '
            'se usa dentro de tu celular para el punto azul y las distancias; no sale de tu celular. '
            'Si no aceptas, todo se mide desde el Zócalo.',
        '• "Mi ubicación" en Rutas: el punto de inicio se envía una vez al servicio de rutas a pie '
            'de OpenStreetMap para dibujar el camino por las calles. VeraGo no lo guarda.',
        'Puedes quitar el permiso de ubicación cuando quieras en los ajustes de tu celular.',
      ]),
      SeccionDocumento('6. Con quién se comparten', [
        '• Supabase: el servicio donde se guarda la base de datos de VeraGo.',
        '• OpenStreetMap: de ahí se descargan los mapas (como al abrir una página web). Para llenar '
            'la dirección de un negocio enviamos solo las coordenadas del negocio. Si usas "Buscar en el '
            'mapa" en Explorar, enviamos solo el texto que buscas.',
        '• Servicio de rutas a pie de OpenStreetMap (routing.openstreetmap.de): recibe las '
            'paradas de tu ruta y su punto de inicio para dibujar el camino.',
        '• Google Gemini (IA): si usas "Pregúntale a VeraGo", recibe lo que escribes en el chat y la '
            'lista pública de lugares. No recibe tu ubicación, tu correo ni tus sellos. La conversación '
            'no se guarda en VeraGo y se borra al cerrar el chat. No escribas datos personales.',
        'No compartimos tus datos con nadie más, salvo que una autoridad lo pida conforme a la ley.',
      ]),
      SeccionDocumento('7. Lo que se guarda en tu celular', [
        'Tu sesión (para no pedir tu contraseña cada vez), si ya viste la bienvenida, tus intereses '
            'y el tiempo de tu última ruta. Se borran al desinstalar la app.',
      ]),
      SeccionDocumento('8. Cómo protegemos tus datos', [
        '• Las reglas de la base de datos hacen que cada persona vea solo lo suyo: nadie más ve tus '
            'sellos ni tu correo.',
        '• Los sellos los valida la base de datos, no el celular, para evitar trampas.',
        '• Solo los desarrolladores del equipo entran al panel de la base de datos.',
      ]),
      SeccionDocumento('9. Si pierdes tu celular o te lo roban', [
        '• Escríbenos desde el correo de tu cuenta (ver "Contacto") y te ayudamos a proteger tu '
            'cuenta: cerrar tus sesiones o borrarla.',
        '• Cambia también la contraseña de tu correo.',
        '• Tus sellos no se pierden: están guardados en la base de datos, no en el celular.',
      ]),
      SeccionDocumento('10. Tus derechos (ARCO) y tu consentimiento', [
        'Puedes pedir Acceso a tus datos, su Rectificación (corregirlos), su Cancelación (borrarlos) '
            'u Oponerte a su uso, y también retirar tu consentimiento.',
        'Cómo: escríbenos desde el correo de tu cuenta con tu nombre y lo que pides. Te '
            'responderemos en un máximo de 20 días hábiles.',
        'Tú mismo puedes cambiar tu nombre y BORRAR tu cuenta en Ajustes (Borrar mi cuenta): se '
            'borran tu perfil y tus sellos; un negocio sin aprobar se borra y uno publicado se oculta.',
      ]),
      SeccionDocumento('11. Menores de edad', [
        'Si tienes menos de 18 años, tu madre, padre o tutor debe estar de acuerdo con que uses VeraGo.',
      ]),
      SeccionDocumento('12. Cuánto tiempo guardamos los datos', [
        'Mientras tu cuenta exista. Al borrarla, se eliminan tus datos de la base de datos. Las '
            'estadísticas solo guardan totales (cuántos sellos por día), nunca quién los ganó.',
      ]),
      SeccionDocumento('13. Cambios a este aviso', [
        'Si cambia este aviso, lo actualizaremos en la app con su nueva versión y fecha.',
      ]),
    ],
  );

  // ==================================================================
  // TÉRMINOS PARA NEGOCIOS
  // ==================================================================
  static const terminosNegocios = DocumentoLegal(
    titulo: 'Términos para negocios',
    resumen: 'Lo que acepta un negocio al registrarse en VeraGo.',
    secciones: [
      SeccionDocumento('1. Registro y revisión', [
        '• Los datos del negocio y del encargado deben ser verdaderos.',
        '• Cada cuenta puede registrar un solo negocio y cada nombre comercial se registra una sola vez.',
        '• Toda solicitud queda pendiente hasta que el equipo de VeraGo la revise. VeraGo puede '
            'aprobarla o rechazarla, y te avisará por teléfono o correo.',
      ]),
      SeccionDocumento('2. Lo que se publica', [
        'Al aprobarse, los turistas ven: nombre comercial, descripción, teléfono, dirección, '
            'ubicación en el mapa, horario, costo de entrada y tu vitrina (productos, servicios y '
            'promoción). El nombre del encargado no se publica.',
      ]),
      SeccionDocumento('3. Negocios formales (local propio)', [
        '• La ubicación marcada en el mapa debe ser la de tu local.',
        '• Puedes editar descripción, teléfono, horario y costo de entrada (si cobras). El costo debe '
            'ser el real y aproximado por persona; VeraGo puede corregirlo.',
        '• Un cambio de ubicación o dirección necesita la aprobación de VeraGo; mientras tanto, tu '
            'negocio sigue en su ubicación actual.',
        '• Puedes mostrar tu QR para que los turistas ganen su sello.',
      ]),
      SeccionDocumento('4. Negocios en un Punto VeraGo (no formales)', [
        '• Solo hay un negocio de cada giro en cada Punto VeraGo.',
        '• El horario lo asigna VeraGo según el horario del punto.',
        '• El uso y el pago del espacio se acuerdan directamente con el equipo de VeraGo, fuera de '
            'la app. La app no cobra ni procesa pagos.',
        '• Estos negocios no dan sellos del pasaporte.',
        '• Puedes pedir cambiarte a otro Punto VeraGo si tu giro está libre ahí; VeraGo debe aprobarlo.',
      ]),
      SeccionDocumento('5. Uso del QR', [
        '• El QR cambia cada 60 segundos: muéstralo en tu celular, no lo compartas en capturas ni redes.',
        '• No te des sellos a ti mismo ni a cuentas de tu negocio.',
      ]),
      SeccionDocumento('6. Contenido', [
        'La foto debe ser propia y del negocio, sin personas reconocibles sin su permiso. '
            'La descripción, la foto y la vitrina no pueden ser ofensivas, engañosas ni anunciar productos ilegales. '
            'Los precios deben ser reales y las promociones, vigentes; VeraGo puede quitar lo que no cumpla.',
      ]),
      SeccionDocumento('7. Responsabilidad del negocio', [
        '• Tu negocio es el único responsable de sus productos, servicios, precios, cobros, trato '
            'al cliente y de la seguridad de su local o espacio.',
        '• Debes contar con los permisos y licencias que pidan las autoridades para operar.',
        '• VeraGo solo muestra tu negocio: no participa en tus ventas ni garantiza visitas o ventas, '
            'y no se hace responsable de accidentes, robos, daños o conflictos que ocurran en tu '
            'negocio o con tus clientes.',
      ]),
      SeccionDocumento('8. Suspensión', [
        'VeraGo puede suspender un negocio por datos falsos, trampas con los sellos, quejas '
            'comprobadas, cierre del negocio o falta de pago del espacio en un Punto VeraGo. '
            'Un negocio suspendido deja de verse en la app y puede reactivarse si se corrige el problema.',
      ]),
      SeccionDocumento('9. Datos del encargado', [
        'Los datos del encargado se tratan como dice el Aviso de privacidad.',
      ]),
    ],
  );

  // ==================================================================
  // REGLAS OPERATIVAS
  // ==================================================================
  static const reglasOperativas = DocumentoLegal(
    titulo: 'Reglas operativas',
    resumen: 'Cómo trabaja VeraGo: aprobaciones, sellos, cambios, reportes y emergencias.',
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
      SeccionDocumento('5. Lugares públicos, precios y eventos', [
        '• Los lugares públicos usan su nombre real; no inventamos horarios ni precios. Su costo de '
            'entrada solo lo pone VeraGo si está confirmado; si no, la app dice "no disponible".',
        '• Los negocios formales ponen su propio costo de entrada (se publica al instante) y '
            'VeraGo puede corregirlo si es incorrecto.',
        '• Los eventos los publica el equipo de VeraGo; el costo que se muestra es aproximado.',
      ]),
      SeccionDocumento('6. Reportes', [
        'Cualquier persona puede reportar un problema desde la ficha de un lugar '
            '("Reportar un problema"). El equipo lo revisa y, si procede, corrige la información '
            'o habla con el negocio. Un reporte NO sustituye una denuncia ante las autoridades.',
      ]),
      SeccionDocumento('7. Emergencias', [
        'El botón rojo "911" (Explorar y ruta) abre la app de llamadas con el 911 escrito. VeraGo '
            'no atiende emergencias ni avisa a nadie: en un accidente, asalto o robo, llama al 911 '
            'y denuncia ante las autoridades.',
      ]),
    ],
  );

  // ==================================================================
  // ¿CÓMO FUNCIONA VERAGO?
  // ==================================================================
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
        '• Mapas y caminos: OpenStreetMap. Las distancias y tiempos son aproximados.',
      ]),
      SeccionDocumento('Cómo se arma tu ruta', [
        'Tu celular elige los lugares de lo que te interesa que alcanzas a visitar en tu tiempo y '
            'que están abiertos, solo de las categorías que elegiste (los Puntos VeraGo también se '
            'pueden elegir). El camino se dibuja por las calles.',
      ]),
      SeccionDocumento('Tu seguridad', [
        'Las rutas son sugerencias: camina por calles concurridas y cuida tus cosas. En una '
            'emergencia usa el botón rojo "911", que abre la app de llamadas de tu celular.',
      ]),
      SeccionDocumento('Tu privacidad', [
        'Solo guardamos tu nombre, tu correo y tus sellos. Tu ubicación se usa en tu celular para '
            'ubicarte en el mapa (si das permiso) y no se guarda. Más detalles en el Aviso de privacidad.',
      ]),
    ],
  );

  /// Orden en que se muestran en Ajustes.
  static const todos = [comoFunciona, reglasOperativas, terminosUso, terminosNegocios, avisoPrivacidad];
}
