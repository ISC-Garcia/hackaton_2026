// Prueba del botón "Mostrar dónde estoy" y del punto "Estás aquí" (sin GPS).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verago/services/distancia.dart';
import 'package:verago/widgets/mapa_lugares.dart';

void main() {
  testWidgets('el mapa muestra el botón de ubicación y el punto "Estás aquí"', (tester) async {
    var pidio = false;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: MapaLugares(
          lugares: const [],
          centro: Distancia.zocalo,
          miUbicacion: Distancia.zocalo,
          alPedirUbicacion: () => pidio = true,
        ),
      ),
    ));
    expect(find.byTooltip('Volver a centrar el mapa'), findsOneWidget);
    expect(find.bySemanticsLabel('Estás aquí'), findsOneWidget);
    await tester.tap(find.byTooltip('Mostrar dónde estoy'));
    expect(pidio, isTrue);
  });

  testWidgets('sin pedirlo, no aparece el botón de ubicación', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: MapaLugares(lugares: const [], centro: Distancia.zocalo)),
    ));
    expect(find.byTooltip('Mostrar dónde estoy'), findsNothing);
    expect(find.bySemanticsLabel('Estás aquí'), findsNothing);
  });
}
