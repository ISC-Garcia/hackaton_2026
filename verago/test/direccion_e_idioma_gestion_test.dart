// Pruebas de: la dirección que da el mapa (solo texto) y las pantallas de
// administración traducidas (sin internet).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verago/i18n/idioma.dart';
import 'package:verago/i18n/traducciones.dart';
import 'package:verago/screens/admin_screen.dart';
import 'package:verago/widgets/direccion_del_mapa.dart';

Widget _enFormulario(GlobalKey<FormState> llave, Widget hijo) => MaterialApp(
      home: Scaffold(body: Form(key: llave, child: hijo)),
    );

void main() {
  tearDown(() => Idioma.actual.value = 'es');

  group('Dirección del mapa (solo texto, no se escribe)', () {
    testWidgets('sin punto: lo pide y no hay campo para escribir', (tester) async {
      final llave = GlobalKey<FormState>();
      await tester.pumpWidget(_enFormulario(
        llave,
        const DireccionDelMapa(direccion: '', hayPunto: false, buscando: false),
      ));
      expect(find.text('Toca el mapa para ver aquí la dirección.'), findsOneWidget);
      expect(find.byType(TextField), findsNothing); // no es un campo de texto
      expect(llave.currentState!.validate(), isFalse);
      await tester.pump();
      expect(find.text('Primero toca el mapa'), findsOneWidget);
    });

    testWidgets('con dirección: se muestra como texto y el formulario pasa', (tester) async {
      final llave = GlobalKey<FormState>();
      await tester.pumpWidget(_enFormulario(
        llave,
        const DireccionDelMapa(direccion: 'Calle Zaragoza 12, Centro', hayPunto: true, buscando: false),
      ));
      expect(find.text('Calle Zaragoza 12, Centro'), findsOneWidget);
      expect(llave.currentState!.validate(), isTrue);
    });

    testWidgets('si falló: ofrece Reintentar y no deja terminar', (tester) async {
      final llave = GlobalKey<FormState>();
      var reintentos = 0;
      await tester.pumpWidget(_enFormulario(
        llave,
        DireccionDelMapa(direccion: '', hayPunto: true, buscando: false, alReintentar: () => reintentos++),
      ));
      expect(llave.currentState!.validate(), isFalse);
      await tester.tap(find.byTooltip('Reintentar'));
      expect(reintentos, 1);
    });

    testWidgets('mientras busca no deja terminar', (tester) async {
      final llave = GlobalKey<FormState>();
      await tester.pumpWidget(_enFormulario(
        llave,
        const DireccionDelMapa(direccion: '', hayPunto: true, buscando: true),
      ));
      expect(find.text('Buscando la dirección del punto…'), findsOneWidget);
      expect(llave.currentState!.validate(), isFalse);
    });
  });

  testWidgets('Panel de administración en inglés', (tester) async {
    Idioma.actual.value = 'en';
    await tester.pumpWidget(const MaterialApp(home: AdminScreen()));
    expect(find.text('Administration'), findsOneWidget);
    expect(find.text('Business requests'), findsOneWidget);
    expect(find.text('Places & VeraGo Spots'), findsOneWidget);
    expect(find.text('Statistics'), findsOneWidget);
  });

  test('giros, estados y días (vienen de la base) tienen traducción', () {
    for (final t in [
      'Guayaberas', 'Picadas y antojitos', 'Artesanías', 'Café', 'Dulces típicos', 'Cócteles y mariscos',
      'Recuerdos de Veracruz', 'Nieves y paletas', 'pendiente', 'aprobado', 'rechazado', 'suspendido',
      'Domingo', 'Lunes', 'Sábado', 'Cafetería', 'Restaurante', 'Tienda o artesanías',
    ]) {
      expect(traducciones.containsKey(t), isTrue, reason: t);
    }
  });
}
