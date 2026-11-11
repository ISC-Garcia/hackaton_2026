// Prueba de la bienvenida: muestra 3 páginas, permite elegir intereses
// y al terminar guarda en el celular que ya se vio y los intereses.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:verago/screens/bienvenida_screen.dart';
import 'package:verago/services/preferencias_service.dart';

void main() {
  testWidgets('La bienvenida guarda intereses y no vuelve a mostrarse', (tester) async {
    // Simula el almacén del celular vacío (primera vez).
    SharedPreferences.setMockInitialValues({});
    final prefs = PreferenciasService();
    expect(await prefs.bienvenidaVista(), isFalse);

    await tester.pumpWidget(const MaterialApp(home: BienvenidaScreen()));
    expect(find.text('Descubre el Centro Histórico'), findsOneWidget);

    await tester.tap(find.text('Siguiente'));
    await tester.pumpAndSettle();
    expect(find.text('¿Qué te interesa?'), findsOneWidget);

    await tester.tap(find.text('Cafeterías'));
    await tester.pump();
    await tester.tap(find.text('Siguiente'));
    await tester.pumpAndSettle();
    expect(find.text('Colecciona sellos'), findsOneWidget);

    await tester.tap(find.text('Empezar'));
    await tester.pumpAndSettle();

    expect(await prefs.bienvenidaVista(), isTrue);
    expect(await prefs.leerIntereses(), {'cafeteria'});
  });
}
