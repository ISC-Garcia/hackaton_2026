import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config.dart';
import '../models/lugar.dart';
import '../models/sello.dart';
import 'distancia.dart';
import 'error_verago.dart';

/// Un mensaje de la conversación: de la persona o de la guía.
class MensajeChat {
  const MensajeChat({required this.deUsuario, required this.texto, this.lugaresIds = const []});

  final bool deUsuario;
  final String texto;

  /// Lugares que recomendó la guía (para dibujar sus tarjetas).
  final List<String> lugaresIds;
}

/// Lo que devuelve la guía: el texto y los lugares recomendados.
class RespuestaGuia {
  const RespuestaGuia(this.respuesta, this.lugaresIds);
  final String respuesta;
  final List<String> lugaresIds;
}

/// GUÍA CON IA "Pregúntale a VeraGo" (Google Gemini).
///
/// Qué es Gemini: un modelo de lenguaje de Google. Le mandamos texto y
/// responde texto. Lo llamamos por su API REST con el paquete `http`.
///
/// Cómo funciona:
/// 1. INSTRUCCIONES DEL SISTEMA (system prompt): le decimos que es la guía de
///    VeraGo y le damos la LISTA DE LUGARES en un JSON compacto (para gastar
///    pocos "tokens", es decir, poco texto).
/// 2. Le pedimos que responda SIEMPRE un JSON con dos campos:
///    `respuesta` (texto para el chat) y `lugares_ids` (ids recomendados).
///    `responseMimeType: application/json` + `responseSchema` obligan a Gemini
///    a devolver JSON válido que se lee con `jsonDecode`.
/// 3. Solo usamos ids que existen en la lista: si la IA inventa uno, se ignora.
///
/// PERSONALIZACIÓN (decisión del equipo): si la persona tiene sesión, también
/// se envía un PERFIL ANÓNIMO: sus intereses y qué lugares ya selló (solo id
/// y categoría, sin fechas). Así la guía no repite lo ya visitado y afina.
///
/// Privacidad: nunca se envían tu nombre, tu correo ni tu ubicación.
class GuiaIaService {
  GuiaIaService({http.Client? cliente, String? apiKey, String? modelo})
      : _cliente = cliente ?? http.Client(),
        _apiKey = apiKey ?? Config.geminiApiKey,
        _modelo = modelo ?? Config.geminiModelo;

  final http.Client _cliente;
  final String _apiKey;
  final String _modelo;

  /// Cuántos mensajes anteriores se mandan (para entender "¿y algo más barato?").
  static const maxHistorial = 10;

  // ------------------------------------------------------------------
  // 1. Contexto: la lista de lugares en JSON compacto
  // ------------------------------------------------------------------
  static String contextoLugares(List<Lugar> lugares, DateTime ahora) {
    String tipo(Lugar l) => l.esPunto
        ? 'punto_verago'
        : l.esInformal
            ? 'negocio_no_formal'
            : l.esFormal
                ? 'negocio_formal'
                : 'lugar_publico';
    String estado(Lugar l) => switch (l.estadoEn(ahora)) {
          EstadoApertura.abierto => 'abierto',
          EstadoApertura.cerrado => 'cerrado',
          EstadoApertura.sinDatos => 'sin_horario',
        };
    String? costo(Lugar l) {
      final c = l.costoEntradaMxn;
      if (c == null) return null;
      return c == 0 ? 'gratis' : '$c MXN';
    }

    final lista = [
      for (final l in lugares)
        {
          'id': l.id,
          'nombre': l.nombre,
          if (l.descripcion != null)
            'descripcion': l.descripcion!.length > 140 ? '${l.descripcion!.substring(0, 140)}…' : l.descripcion,
          'categoria': l.categoriaNombre,
          'tipo': tipo(l),
          if (costo(l) != null) 'costo_entrada': costo(l),
          'estado_actual': estado(l),
          'min_caminando_desde_zocalo': Distancia.minutosCaminando(Distancia.zocalo, l.punto),
          if (l.promocion != null) 'promocion': l.promocion,
          if (l.productos.isNotEmpty) 'productos': [for (final p in l.productos.take(6)) p.nombre],
          if (l.esDemo) 'ficticio': true,
        },
    ];
    return jsonEncode(lista);
  }

  /// PERFIL ANÓNIMO del visitante: intereses + lugares ya sellados (solo id y
  /// categoría) + cuántos sellos por categoría. Sin nombre, correo, fechas ni
  /// ubicación. Devuelve null si no hay nada que contar.
  static String? perfilVisitante({
    required List<Sello> sellos,
    required Set<String> intereses,
    required List<Lugar> lugares,
  }) {
    if (sellos.isEmpty && intereses.isEmpty) return null;
    final nombres = {for (final l in lugares) l.categoriaClave: l.categoriaNombre};
    final porCategoria = <String, int>{};
    final yaSellados = <String>{};
    for (final s in sellos) {
      if (!yaSellados.add(s.lugarId)) continue; // un lugar cuenta una vez
      final cat = nombres[s.categoriaClave] ?? s.categoriaClave;
      porCategoria[cat] = (porCategoria[cat] ?? 0) + 1;
    }
    return jsonEncode({
      if (intereses.isNotEmpty) 'intereses': [for (final i in intereses) nombres[i] ?? i],
      if (yaSellados.isNotEmpty) 'ya_sellados_ids': yaSellados.toList(),
      if (porCategoria.isNotEmpty) 'sellos_por_categoria': porCategoria,
    });
  }

  static String instrucciones(String contexto, {String? perfil}) => '''
Eres el guía turístico oficial de VeraGo en el Centro Histórico de Veracruz, México.
Responde en español, de forma natural, amigable y breve (máximo 3 oraciones).

Reglas:
- Recomienda SOLO lugares de la LISTA de abajo y usa sus "id" exactos. Máximo 4 lugares.
- Si nada de la lista encaja, dilo con amabilidad y deja "lugares_ids" vacío.
- No inventes horarios, precios, productos ni lugares. Si un dato no está en la lista, di que conviene confirmarlo en el lugar.
- "estado_actual" dice si está abierto ahora. "min_caminando_desde_zocalo" es el tiempo aproximado a pie.
- Los lugares con "ficticio": true son de demostración; puedes recomendarlos sin decir que son reales.
- Si la persona habla de una emergencia, accidente o delito, dile que llame al 911 (hay un botón rojo en la app) y no recomiendes lugares.
- No pidas ni guardes datos personales.

Devuelve SIEMPRE un JSON con:
- "respuesta": el texto para la persona.
- "lugares_ids": arreglo con los id de los lugares recomendados (puede ir vacío).

LISTA DE LUGARES (JSON):
$contexto
${perfil == null ? '' : '''
PERFIL ANÓNIMO DEL VISITANTE (JSON):
$perfil
- Usa sus intereses para elegir mejor.
- Los lugares de "ya_sellados_ids" ya los visitó: NO los recomiendes otra vez, salvo que los pida.
- Puedes mencionar su gusto con naturalidad (ej. "veo que te gustan las cafeterías"), sin inventar nada.
'''}''';

  // ------------------------------------------------------------------
  // 2. Llamada a Gemini
  // ------------------------------------------------------------------
  Uri get _url =>
      Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/$_modelo:generateContent');

  /// Pregunta a la guía. `historial` = la conversación hasta ahora (la
  /// última es la pregunta nueva). `idsValidos` = ids de la lista enviada.
  Future<RespuestaGuia> preguntar({
    required String contexto,
    required List<MensajeChat> historial,
    required Set<String> idsValidos,
    String? perfil,
  }) async {
    if (_apiKey.isEmpty) {
      throw const ErrorVeraGo('Falta configurar la guía: agrega GEMINI_API_KEY en env.json.');
    }
    final recientes = historial.length > maxHistorial
        ? historial.sublist(historial.length - maxHistorial)
        : historial;
    final cuerpo = {
      'systemInstruction': {
        'parts': [
          {'text': instrucciones(contexto, perfil: perfil)},
        ],
      },
      'contents': [
        for (final m in recientes)
          {
            'role': m.deUsuario ? 'user' : 'model',
            'parts': [
              {'text': m.texto},
            ],
          },
      ],
      'generationConfig': {
        'temperature': 0.4,
        'maxOutputTokens': 800,
        'responseMimeType': 'application/json',
        'responseSchema': {
          'type': 'OBJECT',
          'properties': {
            'respuesta': {'type': 'STRING'},
            'lugares_ids': {
              'type': 'ARRAY',
              'items': {'type': 'STRING'},
            },
          },
          'required': ['respuesta', 'lugares_ids'],
        },
      },
    };

    http.Response r;
    try {
      r = await _cliente
          .post(
            _url,
            // La clave va en un encabezado, no en la dirección (así no queda
            // escrita en registros de servidores).
            headers: {'Content-Type': 'application/json', 'x-goog-api-key': _apiKey},
            body: jsonEncode(cuerpo),
          )
          .timeout(const Duration(seconds: 45));
    } catch (_) {
      throw const ErrorVeraGo('Revisa tu conexión a internet e intenta de nuevo.');
    }

    // 429 = demasiadas preguntas (límite gratuito); 503 = Google saturado.
    if (r.statusCode == 429 || r.statusCode == 503) {
      throw const ErrorVeraGo('La guía está recibiendo muchas preguntas. Espera un minuto e intenta de nuevo.');
    }
    if (r.statusCode == 400 || r.statusCode == 403) {
      final clave = r.body.contains('API_KEY') || r.body.contains('API key');
      throw ErrorVeraGo(clave
          ? 'La clave de Gemini no es válida o está restringida. Revisa GEMINI_API_KEY.'
          : 'La guía no pudo responder esa pregunta. Intenta escribirla de otra forma.');
    }
    if (r.statusCode == 404) {
      throw ErrorVeraGo('El modelo "$_modelo" no está disponible. Cambia GEMINI_MODELO en env.json.');
    }
    if (r.statusCode != 200) {
      throw const ErrorVeraGo('La guía no está disponible en este momento. Intenta más tarde.');
    }
    return leerRespuesta(jsonDecode(utf8.decode(r.bodyBytes)) as Map<String, dynamic>, idsValidos);
  }

  // ------------------------------------------------------------------
  // 3. Leer la respuesta (pública para probarla sin internet)
  // ------------------------------------------------------------------
  /// Gemini responde: candidates[0].content.parts[0].text = nuestro JSON.
  static RespuestaGuia leerRespuesta(Map<String, dynamic> json, Set<String> idsValidos) {
    try {
      final candidatos = json['candidates'] as List;
      final partes = (candidatos.first['content'] as Map)['parts'] as List;
      final texto = partes.map((p) => (p as Map)['text'] ?? '').join();
      final datos = jsonDecode(texto) as Map<String, dynamic>;
      final respuesta = (datos['respuesta'] as String? ?? '').trim();
      final ids = <String>[
        for (final id in (datos['lugares_ids'] as List? ?? const []))
          if (id is String && idsValidos.contains(id)) id, // ignora ids inventados
      ];
      if (respuesta.isEmpty) throw const FormatException();
      return RespuestaGuia(respuesta, ids.toSet().take(4).toList());
    } catch (_) {
      throw const ErrorVeraGo('La guía respondió algo que no entendimos. Intenta de nuevo.');
    }
  }
}
