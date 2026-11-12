// Prueba: la barra inferior muestra las 4 pestañas y al tocar una cambia
// la pantalla. Sin conexión a Supabase, Explorar debe mostrar un mensaje
// claro con botón "Reintentar" (no una pantalla rota).
// Se ejecuta con: flutter test

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verago/screens/principal_screen.dart';
import 'package:verago/services/error_verago.dart';
import 'package:verago/theme/app_theme.dart';

void main() {
  testWidgets('La barra inferior cambia entre las 4 pestañas', (tester) async {
    await tester.pumpWidget(
      MaterialApp(theme: VgTema.claro, home: const PrincipalScreen()),
    );
    await tester.pumpAndSettle();

    for (final nombre in ['Explorar', 'Rutas', 'Agenda', 'Pasaporte']) {
      expect(find.widgetWithText(NavigationDestination, nombre), findsOneWidget);
    }

    // Sin Supabase, Explorar muestra el error amable con "Reintentar".
    expect(find.text('Reintentar'), findsWidgets);

    // Tocar "Reintentar" no debe provocar errores. (Antes, setState devolvía
    // un Future por usar `=>`, Flutter lo rechazaba y la pantalla no cambiaba.)
    // En las pruebas no hay Supabase, así que el reintento vuelve a fallar
    // con el error amable (ErrorVeraGo); eso está bien. Lo que NO debe pasar
    // es el error de Flutter por setState.
    await tester.tap(find.text('Reintentar').first);
    await tester.pumpAndSettle();
    final error = tester.takeException();
    expect(error == null || error is ErrorVeraGo, isTrue, reason: 'Error inesperado: $error');
    expect(find.text('Reintentar'), findsWidgets);

    await tester.tap(find.widgetWithText(NavigationDestination, 'Pasaporte'));
    await tester.pumpAndSettle();
    expect(find.text('Tu pasaporte VeraGo'), findsOneWidget);
  });
}
