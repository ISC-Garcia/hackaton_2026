// Pruebas del botón de idioma y de las traducciones (sin internet).

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:verago/i18n/idioma.dart';
import 'package:verago/i18n/traducciones.dart';
import 'package:verago/legal/documentos.dart';
import 'package:verago/models/insignia.dart';
import 'package:verago/screens/bienvenida_screen.dart';
import 'package:verago/services/pasaporte_service.dart';
import 'package:verago/services/rutas_service.dart';
import 'package:verago/services/traductor_service.dart';
import 'package:verago/widgets/categoria_estilo.dart';
import 'package:verago/widgets/reportar_problema.dart';

/// Lee los textos que pasan por tr('...') o Etiqueta('...') en lib/.
Set<String> _textosDelCodigo() {
  final patron = RegExp(r"(?:\btr|\bEtiqueta)\(\s*'((?:[^'\\]|\\.)*)'");
  final textos = <String>{};
  for (final archivo in Directory('lib').listSync(recursive: true).whereType<File>()) {
    if (!archivo.path.endsWith('.dart') || archivo.path.endsWith('traducciones.dart')) continue;
    for (final linea in archivo.readAsLinesSync()) {
      if (linea.trimLeft().startsWith('//')) continue; // comentarios
      for (final m in patron.allMatches(linea)) {
        // Mismo texto que ve Dart: quitamos los escapes \' \$ \n.
        textos.add(m
            .group(1)!
            .replaceAll(r"\'", "'")
            .replaceAll(r'\$', r'$')
            .replaceAll(r'\n', '\n'));
      }
    }
  }
  return textos;
}

Set<String> _variables(String t) => RegExp(r'\{(\w+)\}').allMatches(t).map((m) => m.group(1)!).toSet();

void main() {
  tearDown(() => Idioma.actual.value = 'es');

  test('TODOS los textos marcados con tr() tienen traducción', () {
    final faltan = _textosDelCodigo().where((t) => !traducciones.containsKey(t)).toList();
    expect(faltan, isEmpty, reason: 'Faltan en traducciones.dart:\n${faltan.join('\n')}');
  });

  test('textos que vienen de datos fijos (categorías, insignias, documentos…) también', () {
    final fijos = [
      ...CategoriaEstilo.nombres.values,
      for (final n in Insignia.niveles) ...[n.nombre, n.descripcion],
      for (final d in Documentos.todos) ...[d.titulo, d.resumen],
      for (final r in Ritmo.values) r.nombre,
      ...ReportarProblema.motivos,
      PasaporteService.sinConexionAlEscanear,
      'Ficticio · demostración',
      'Gratuito',
      'Con costo',
      'Escribe un correo válido (ej. nombre@correo.com)',
      'Usa al menos 8 caracteres',
      'El nombre no lleva números',
    ];
    final faltan = fijos.where((t) => !traducciones.containsKey(t)).toList();
    expect(faltan, isEmpty, reason: faltan.join('\n'));
  });

  test('cada texto tiene 4 traducciones con las mismas variables {…}', () {
    traducciones.forEach((es, lista) {
      expect(lista.length, Idioma.orden.length, reason: es);
      for (final t in lista) {
        expect(t.trim(), isNotEmpty, reason: es);
        expect(_variables(t), _variables(es), reason: '"$es" → "$t"');
      }
    });
  });

  test('tr: español por defecto, traduce y reemplaza variables', () {
    expect(tr('Explorar'), 'Explorar');
    Idioma.actual.value = 'en';
    expect(tr('Explorar'), 'Explore');
    expect(tr('Visita sugerida: {min} min', {'min': 30}), 'Suggested visit: 30 min');
    Idioma.actual.value = 'de';
    expect(tr('Te quedan {min} min libres', {'min': 20}), 'Du hast noch 20 Min. frei');
    // Un texto sin traducción se queda en español (la app no se rompe).
    expect(tr('Texto que no existe'), 'Texto que no existe');
  });

  test('fechas en cada idioma', () {
    final sabado = DateTime(2026, 11, 14);
    expect(Idioma.fechaLarga(sabado), 'sábado 14 de noviembre');
    Idioma.actual.value = 'en';
    expect(Idioma.fechaLarga(sabado), 'Saturday, November 14');
    Idioma.actual.value = 'fr';
    expect(Idioma.fechaLarga(sabado), 'samedi 14 novembre');
  });

  test('el idioma se guarda en el celular', () async {
    SharedPreferences.setMockInitialValues({});
    await Idioma.cambiar('pt');
    Idioma.actual.value = 'es';
    await Idioma.cargar();
    expect(Idioma.codigo, 'pt');
    await Idioma.cambiar('xx'); // idioma que no existe: se ignora
    expect(Idioma.codigo, 'pt');
  });

  group('Traductor con IA (contenido de la base)', () {
    Map<String, dynamic> respuesta(String json) => {
          'candidates': [
            {
              'content': {
                'parts': [
                  {'text': json},
                ],
              },
            },
          ],
        };

    test('lee la lista traducida', () {
      expect(TraductorService.leerTraducciones(respuesta('{"traducciones":["Hello","Museum"]}'), 2),
          ['Hello', 'Museum']);
    });
    test('si Gemini devuelve otra cantidad, falla (y se queda el español)', () {
      expect(() => TraductorService.leerTraducciones(respuesta('{"traducciones":["Hello"]}'), 2),
          throwsFormatException);
    });
    test('en español no llama a Gemini y devuelve lo mismo', () async {
      final r = await TraductorService(apiKey: 'x').traducir(['Hola', 'Museo']);
      expect(r, {'Hola': 'Hola', 'Museo': 'Museo'});
    });
  });

  testWidgets('Bienvenida: el botón de idioma cambia los textos', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const MaterialApp(home: BienvenidaScreen()));
    expect(find.text('Saltar'), findsOneWidget);
    await tester.tap(find.text('Español'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();
    expect(find.text('Skip'), findsOneWidget);
    expect(find.text('Discover the Historic Center'), findsOneWidget);
    expect(Idioma.codigo, 'en');
  });
}
