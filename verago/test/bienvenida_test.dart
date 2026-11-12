// Prueba de la bienvenida y guía: recorre las 7 páginas, permite elegir
// intereses y al terminar guarda en el celular que ya se vio y los intereses.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:verago/screens/bienvenida_screen.dart';
import 'package:verago/services/preferencias_service.dart';

void main() {
  testWidgets('La bienvenida guía por cada pestaña, guarda intereses y no vuelve a mostrarse', (tester) async {
    // Simula el almacén del celular vacío (primera vez).
    SharedPreferences.setMockInitialValues({});
    final prefs = PreferenciasService();
    expect(await prefs.bienvenidaVista(), isFalse);

    await tester.pumpWidget(const MaterialApp(home: BienvenidaScreen()));
    expect(find.text('Descubre el Centro Histórico'), findsOneWidget);
    // El logo de VeraGo aparece en la primera página.
    expect(find.image(const AssetImage('assets/logo.png')), findsOneWidget);

    await tester.tap(find.text('Siguiente'));
    await tester.pumpAndSettle();
    expect(find.text('¿Qué te interesa?'), findsOneWidget);
    await tester.tap(find.text('Cafeterías'));
    await tester.pump();

    // Una página por pestaña, con la barra de abajo dibujada, y la de seguridad.
    for (final titulo in ['Explorar', 'Rutas', 'Agenda', 'Colecciona sellos', 'Tu seguridad y más']) {
      await tester.tap(find.text('Siguiente'));
      await tester.pumpAndSettle();
      expect(find.text(titulo), findsWidgets, reason: titulo);
    }
    expect(find.text('Botón 911'), findsOneWidget);

    await tester.tap(find.text('Empezar'));
    await tester.pumpAndSettle();

    expect(await prefs.bienvenidaVista(), isTrue);
    expect(await prefs.leerIntereses(), {'cafeteria'});
  });
}
