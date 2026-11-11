// Pruebas de Ajustes:
// - Invitado: ve intereses, bienvenida y privacidad, pero no "Mi cuenta".
// - Con sesión: ve su rol y el botón Cerrar sesión.
// - Elegir un interés lo guarda en el celular.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:verago/models/sello.dart';
import 'package:verago/screens/ajustes_screen.dart';
import 'package:verago/services/preferencias_service.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('Invitado: sin "Mi cuenta"; elegir interés lo guarda', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: AjustesScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Mi cuenta'), findsNothing);
    expect(find.text('Mis intereses'), findsOneWidget);
    expect(find.text('Ver la bienvenida otra vez'), findsOneWidget);

    await tester.tap(find.text('Museos'));
    await tester.pumpAndSettle();
    expect(await PreferenciasService().leerIntereses(), {'museo'});
  });

  testWidgets('Con sesión: muestra rol y Cerrar sesión', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: AjustesScreen(perfil: Perfil(nombre: 'Ana', rol: 'comerciante')),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Mi cuenta'), findsOneWidget);
    expect(find.text('Rol: Comerciante'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Cerrar sesión'),
      200,
      scrollable: find.byType(Scrollable).first, // la lista principal
    );
    expect(find.text('Cerrar sesión'), findsOneWidget);
  });
}
