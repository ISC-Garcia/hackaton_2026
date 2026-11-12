// Pruebas de "Legal y confianza", reportes, cambio de ubicación y sellos
// (sin internet).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:verago/legal/documentos.dart';
import 'package:verago/models/lugar.dart';
import 'package:verago/screens/ajustes_screen.dart';
import 'package:verago/screens/documento_screen.dart';
import 'package:verago/screens/login_screen.dart';
import 'package:verago/services/pasaporte_service.dart';
import 'package:verago/widgets/reportar_problema.dart';

Map<String, dynamic> fila({Map<String, dynamic> extra = const {}}) => {
      'id': 'n1',
      'nombre': 'Negocio Demo',
      'descripcion': null,
      'categorias': {'clave': 'cafeteria', 'nombre': 'Cafeterías'},
      'latitud': 19.19,
      'longitud': -96.13,
      'direccion': 'Calle 1',
      'telefono': null,
      'interes': 3,
      'duracion_visita_min': 30,
      'es_comercio': true,
      'es_demo': true,
      'participa_pasaporte': true,
      ...extra,
    };

void main() {
  test('todos los documentos tienen título, resumen y secciones con texto', () {
    expect(Documentos.todos, hasLength(5));
    for (final d in Documentos.todos) {
      expect(d.titulo, isNotEmpty);
      expect(d.resumen, isNotEmpty);
      expect(d.secciones, isNotEmpty);
      for (final s in d.secciones) {
        expect(s.parrafos, isNotEmpty, reason: '${d.titulo} · ${s.titulo}');
      }
    }
  });

  testWidgets('un documento muestra contacto y versión', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: DocumentoScreen(documento: Documentos.avisoPrivacidad)));
    expect(find.text('Aviso de privacidad'), findsOneWidget);
    await tester.scrollUntilVisible(find.text(DocumentoLegal.version), 300,
        scrollable: find.byType(Scrollable).first);
    expect(find.text('Contacto'), findsOneWidget);
  });

  testWidgets('Ajustes tiene la sección "Legal y confianza"', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const MaterialApp(home: AjustesScreen()));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Términos para negocios'), 300,
        scrollable: find.byType(Scrollable).first);
    expect(find.text('Legal y confianza'), findsOneWidget);
    await tester.tap(find.text('Términos para negocios'));
    await tester.pumpAndSettle();
    expect(find.text('Registro y revisión'), findsOneWidget);
  });

  testWidgets('Crear cuenta muestra los enlaces a Términos y Aviso de privacidad', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));
    expect(find.text('Términos de uso'), findsNothing); // en "Entrar" no aparece
    await tester.tap(find.text('No tengo cuenta: crear una'));
    await tester.pumpAndSettle();
    expect(find.text('Términos de uso'), findsOneWidget);
    expect(find.text('Aviso de privacidad'), findsOneWidget);
  });

  testWidgets('Crear cuenta exige contraseña segura (8+, letras y números)', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));
    await tester.tap(find.text('No tengo cuenta: crear una'));
    await tester.pumpAndSettle();
    final campos = find.byType(TextFormField);
    await tester.enterText(campos.at(0), 'Ana');
    await tester.enterText(campos.at(1), 'ana@correo.com');
    await tester.enterText(campos.at(2), 'corta1');
    await tester.enterText(campos.at(3), 'corta1');
    await tester.tap(find.widgetWithText(FilledButton, 'Crear cuenta'));
    await tester.pumpAndSettle();
    expect(find.text('Usa al menos 8 caracteres'), findsOneWidget);
  });

  test('el reporte incluye el lugar y el problema', () {
    final l = Lugar.fromJson(fila());
    final m = ReportarProblema.mensaje(l, 'La ubicación está mal');
    expect(m, contains('Negocio Demo'));
    expect(m, contains('La ubicación está mal'));
  });

  group('Cambio de ubicación pendiente (SQL 013)', () {
    test('sin columnas de cambio: no hay pendiente', () {
      final l = Lugar.fromJson(fila());
      expect(l.tieneCambioPendiente, isFalse);
      expect(l.puntoSolicitado, isNull);
    });
    test('con cambio: el negocio sigue en su punto y guarda el solicitado', () {
      final l = Lugar.fromJson(fila(extra: {
        'cambio_latitud': 19.2,
        'cambio_longitud': -96.14,
        'cambio_direccion': 'Calle Nueva 2',
        'cambio_solicitado_en': '2026-11-11T10:00:00Z',
      }));
      expect(l.tieneCambioPendiente, isTrue);
      expect(l.punto.latitude, 19.19); // ubicación actual intacta
      expect(l.puntoSolicitado!.latitude, 19.2);
      expect(l.cambioDireccion, 'Calle Nueva 2');
    });
  });

  test('escanear tu propio QR da un mensaje claro', () {
    const r = ResultadoEscaneo(estado: 'ES_TU_NEGOCIO');
    expect(r.exito, isFalse);
    expect(r.mensaje, contains('propio negocio'));
  });
}
