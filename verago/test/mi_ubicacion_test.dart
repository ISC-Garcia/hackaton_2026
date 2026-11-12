// Prueba del botón "Mostrar dónde estoy" y del punto "Estás aquí" (sin GPS).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verago/models/lugar.dart';
import 'package:verago/screens/ruta_screen.dart';
import 'package:verago/services/distancia.dart';
import 'package:verago/services/rutas_service.dart';
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

  testWidgets('la pantalla de la ruta tiene el botón de emergencia 911', (tester) async {
    final plaza = Lugar.fromJson({
      'id': 'p1',
      'nombre': 'Plaza Demo',
      'descripcion': null,
      'categorias': {'clave': 'plaza', 'nombre': 'Plazas'},
      'latitud': Distancia.zocalo.latitude + 0.001,
      'longitud': Distancia.zocalo.longitude,
      'direccion': null,
      'telefono': null,
      'interes': 4,
      'duracion_visita_min': 20,
      'es_comercio': false,
      'es_demo': true,
      'participa_pasaporte': false,
    });
    await tester.pumpWidget(MaterialApp(
      home: RutaScreen(
        peticion: PeticionRuta(
          inicio: Distancia.zocalo,
          nombreInicio: 'el Zócalo',
          horaInicio: DateTime(2025, 11, 10, 10),
          minutosDisponibles: 60,
          intereses: const {'plaza'},
        ),
        lugares: [plaza],
      ),
    ));
    expect(find.byTooltip('Emergencia: llamar al 911'), findsOneWidget);
    expect(find.text('911'), findsOneWidget);
  });
}
