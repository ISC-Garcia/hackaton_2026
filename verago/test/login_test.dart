// Prueba: al crear cuenta, si las contraseñas no coinciden, el formulario
// muestra el error y no intenta registrar.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verago/screens/login_screen.dart';

void main() {
  testWidgets('Crear cuenta pide confirmar la contraseña', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));

    // En modo "Entrar" no aparece el campo de confirmar.
    expect(find.text('Confirmar contraseña'), findsNothing);

    await tester.tap(find.text('No tengo cuenta: crear una'));
    await tester.pumpAndSettle();
    expect(find.text('Confirmar contraseña'), findsOneWidget);

    final campos = find.byType(TextFormField);
    await tester.enterText(campos.at(0), 'Ana');
    await tester.enterText(campos.at(1), 'ana@correo.com');
    await tester.enterText(campos.at(2), 'secreto1');
    await tester.enterText(campos.at(3), 'secreto2');
    await tester.tap(find.widgetWithText(FilledButton, 'Crear cuenta'));
    await tester.pumpAndSettle();

    expect(find.text('Las contraseñas no coinciden'), findsOneWidget);
  });
}
