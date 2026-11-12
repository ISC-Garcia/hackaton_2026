import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config.dart';
import '../i18n/idioma.dart';

/// TRADUCTOR CON IA (Google Gemini) para el CONTENIDO de la base de datos:
/// descripciones de lugares, promociones, productos, eventos y documentos.
///
/// Por qué con IA: esos textos los escriben el admin y los comerciantes en
/// español y cambian seguido; traducirlos a mano en 4 idiomas no es realista.
/// Los botones y menús de la app NO usan esto: van en `traducciones.dart`.
///
/// Cómo funciona:
/// 1. Si la app está en español (o no hay clave), devuelve los textos igual.
/// 2. Manda a Gemini la lista de textos y pide un JSON con la lista traducida,
///    en el mismo orden (`responseSchema`).
/// 3. Guarda cada traducción en memoria (`_memoria`): si vuelves a abrir la
///    ficha, ya no se le pregunta a Gemini.
/// 4. Si algo falla (sin internet, límite de Gemini), devuelve el español:
///    la app nunca se queda sin texto.
///
/// Privacidad: solo se envían textos públicos de la app, nada de la persona.
class TraductorService {
  TraductorService({http.Client? cliente, String? apiKey, String? modelo})
      : _cliente = cliente ?? http.Client(),
        _apiKey = apiKey ?? Config.geminiApiKey,
        _modelo = modelo ?? Config.geminiModelo;

  final http.Client _cliente;
  final String _apiKey;
  final String _modelo;

  /// idioma|texto → traducción (vive mientras la app esté abierta).
  static final Map<String, String> _memoria = {};

  /// Traduce `textos` al idioma actual. Devuelve original → traducción.
  Future<Map<String, String>> traducir(Iterable<String> textos) async {
    final idioma = Idioma.codigo;
    final unicos = {for (final t in textos) if (t.trim().isNotEmpty) t};
    final resultado = {for (final t in unicos) t: t};
    if (idioma == 'es' || _apiKey.isEmpty || unicos.isEmpty) return resultado;

    final faltan = <String>[];
    for (final t in unicos) {
      final guardada = _memoria['$idioma|$t'];
      if (guardada != null) {
        resultado[t] = guardada;
      } else {
        faltan.add(t);
      }
    }
    if (faltan.isEmpty) return resultado;

    try {
      final traducidos = await _pedirAGemini(faltan, Idioma.nombreParaIa[idioma]!);
      for (var i = 0; i < faltan.length; i++) {
        _memoria['$idioma|${faltan[i]}'] = traducidos[i];
        resultado[faltan[i]] = traducidos[i];
      }
    } catch (_) {
      // Se queda en español.
    }
    return resultado;
  }

  Future<List<String>> _pedirAGemini(List<String> textos, String idioma) async {
    final cuerpo = {
      'systemInstruction': {
        'parts': [
          {
            'text': 'You translate texts from a tourism app about the historic center of Veracruz, Mexico. '
                'Translate each text of the JSON array from Spanish to $idioma. '
                'Keep proper names of places, streets and businesses as they are. Keep numbers, prices and '
                'line breaks. Return a JSON object with "traducciones": an array with exactly the same number '
                'of items, in the same order.',
          },
        ],
      },
      'contents': [
        {
          'role': 'user',
          'parts': [
            {'text': jsonEncode(textos)},
          ],
        },
      ],
      'generationConfig': {
        'temperature': 0.1,
        'responseMimeType': 'application/json',
        'responseSchema': {
          'type': 'OBJECT',
          'properties': {
            'traducciones': {
              'type': 'ARRAY',
              'items': {'type': 'STRING'},
            },
          },
          'required': ['traducciones'],
        },
      },
    };
    final r = await _cliente
        .post(
          Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/$_modelo:generateContent'),
          headers: {'Content-Type': 'application/json', 'x-goog-api-key': _apiKey},
          body: jsonEncode(cuerpo),
        )
        .timeout(const Duration(seconds: 45));
    if (r.statusCode != 200) throw Exception('Gemini ${r.statusCode}');
    return leerTraducciones(jsonDecode(utf8.decode(r.bodyBytes)) as Map<String, dynamic>, textos.length);
  }

  /// Lee la respuesta de Gemini (pública para probarla sin internet).
  /// Si no trae exactamente `cuantos` textos, falla (y se queda el español).
  static List<String> leerTraducciones(Map<String, dynamic> json, int cuantos) {
    final partes = ((json['candidates'] as List).first['content'] as Map)['parts'] as List;
    final texto = partes.map((p) => (p as Map)['text'] ?? '').join();
    final lista = (jsonDecode(texto) as Map<String, dynamic>)['traducciones'] as List;
    if (lista.length != cuantos) throw const FormatException('Cantidad distinta');
    return [for (final t in lista) '$t'];
  }
}
