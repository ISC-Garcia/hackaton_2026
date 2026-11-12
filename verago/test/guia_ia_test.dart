// Pruebas del chat "Pregúntale a VeraGo" (Gemini simulado: sin internet ni
// gasto de cuota).

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:verago/models/lugar.dart';
import 'package:verago/screens/chat_guia_screen.dart';
import 'package:verago/services/error_verago.dart';
import 'package:verago/services/guia_ia_service.dart';

Lugar lugar(String id, String nombre, {int? costo}) => Lugar.fromJson({
      'id': id,
      'nombre': nombre,
      'descripcion': 'Lugar de prueba con sombra.',
      'categorias': {'clave': 'plaza', 'nombre': 'Plazas y paseos'},
      'latitud': 19.1996,
      'longitud': -96.1342,
      'direccion': null,
      'telefono': null,
      'interes': 4,
      'duracion_visita_min': 30,
      'es_comercio': false,
      'es_demo': false,
      'participa_pasaporte': false,
      'costo_entrada_mxn': costo,
    });

/// Respuesta de Gemini como la manda la API.
Map<String, dynamic> respuestaGemini(Map<String, dynamic> datos) => {
      'candidates': [
        {
          'content': {
            'parts': [
              {'text': jsonEncode(datos)},
            ],
          },
        },
      ],
    };

void main() {
  final lugares = [lugar('a1', 'Zócalo de Veracruz', costo: 0), lugar('b2', 'Portales de Lerdo')];

  test('el contexto es un JSON compacto con lo necesario', () {
    final lista = jsonDecode(GuiaIaService.contextoLugares(lugares, DateTime(2026, 11, 12, 12))) as List;
    expect(lista, hasLength(2));
    final z = lista.first as Map;
    expect(z['id'], 'a1');
    expect(z['categoria'], 'Plazas y paseos');
    expect(z['tipo'], 'lugar_publico');
    expect(z['costo_entrada'], 'gratis');
    expect(z['estado_actual'], 'sin_horario');
    expect(z.containsKey('min_caminando_desde_zocalo'), isTrue);
  });

  test('las instrucciones llevan la lista y piden el JSON', () {
    final texto = GuiaIaService.instrucciones('[{"id":"a1"}]');
    expect(texto, contains('guía turístico oficial de VeraGo'));
    expect(texto, contains('lugares_ids'));
    expect(texto, contains('[{"id":"a1"}]'));
  });

  test('lee la respuesta y descarta ids inventados', () {
    final r = GuiaIaService.leerRespuesta(
      respuestaGemini({'respuesta': 'Ve al Zócalo.', 'lugares_ids': ['a1', 'inventado']}),
      {'a1', 'b2'},
    );
    expect(r.respuesta, 'Ve al Zócalo.');
    expect(r.lugaresIds, ['a1']);
  });

  test('envía la clave en un encabezado y el JSON obligatorio', () async {
    late http.Request enviada;
    final servicio = GuiaIaService(
      apiKey: 'clave-de-prueba',
      modelo: 'modelo-x',
      cliente: MockClient((req) async {
        enviada = req;
        return http.Response(jsonEncode(respuestaGemini({'respuesta': 'Hola', 'lugares_ids': []})), 200);
      }),
    );
    await servicio.preguntar(
      contexto: '[]',
      historial: const [MensajeChat(deUsuario: true, texto: 'hola')],
      idsValidos: const {},
    );
    expect(enviada.headers['x-goog-api-key'], 'clave-de-prueba');
    expect(enviada.url.toString(), isNot(contains('clave-de-prueba'))); // la clave no va en la dirección
    expect(enviada.url.path, contains('modelo-x:generateContent'));
    final cuerpo = jsonDecode(enviada.body) as Map;
    expect(cuerpo['generationConfig']['responseMimeType'], 'application/json');
  });

  test('si Google está saturado, da un mensaje claro', () async {
    final servicio = GuiaIaService(
      apiKey: 'x',
      cliente: MockClient((_) async => http.Response('{"error":{}}', 503)),
    );
    expect(
      () => servicio.preguntar(contexto: '[]', historial: const [], idsValidos: const {}),
      throwsA(isA<ErrorVeraGo>().having((e) => e.mensaje, 'mensaje', contains('Espera un minuto'))),
    );
  });

  testWidgets('el chat muestra la respuesta y la tarjeta del lugar recomendado', (tester) async {
    final servicio = GuiaIaService(
      apiKey: 'x',
      cliente: MockClient((_) async => http.Response(
            jsonEncode(respuestaGemini({'respuesta': 'Te recomiendo los Portales.', 'lugares_ids': ['b2']})),
            200,
          )),
    );
    await tester.pumpWidget(MaterialApp(home: ChatGuiaScreen(lugares: lugares, servicio: servicio)));
    await tester.tap(find.text('Algo con sombra para ir con niños'));
    await tester.pumpAndSettle();
    expect(find.text('Algo con sombra para ir con niños'), findsOneWidget); // burbuja de la persona
    expect(find.text('Te recomiendo los Portales.'), findsOneWidget);
    expect(find.text('Portales de Lerdo'), findsOneWidget); // tarjeta del lugar
  });

  testWidgets('sin clave, avisa que falta configurar', (tester) async {
    await tester.pumpWidget(MaterialApp(home: ChatGuiaScreen(lugares: lugares)));
    expect(find.text('Falta configurar la guía'), findsOneWidget);
  });
}
