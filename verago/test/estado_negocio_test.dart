// Pruebas de la pantalla "Solicitud en revisión" del comerciante.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verago/models/lugar.dart';
import 'package:verago/screens/estado_negocio_screen.dart';

Lugar negocio(String estado) => Lugar.fromJson({
      'id': 'n1',
      'nombre': 'Café Demo',
      'descripcion': null,
      'categorias': {'clave': 'cafeteria', 'nombre': 'Cafeterías'},
      'latitud': 19.19,
      'longitud': -96.13,
      'direccion': null,
      'telefono': null,
      'interes': 3,
      'duracion_visita_min': 30,
      'es_comercio': true,
      'es_demo': true,
      'participa_pasaporte': false,
      'estado_aprobacion': estado,
    });

void main() {
  testWidgets('pendiente: pide esperar al administrador y explica qué sigue', (tester) async {
    await tester.pumpWidget(MaterialApp(home: EstadoNegocioScreen(negocio: negocio('pendiente'))));
    expect(find.text('Solicitud en revisión'), findsOneWidget);
    expect(find.textContaining('espera mientras un administrador'), findsOneWidget);
    expect(find.text('¿Qué pasa ahora?'), findsOneWidget);
    expect(find.textContaining('Te contactaremos por teléfono o correo'), findsOneWidget);
    expect(find.text('Revisar de nuevo'), findsOneWidget);
  });

  testWidgets('dentro del panel no dibuja una segunda barra de título', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Mi negocio')),
        body: EstadoNegocioScreen(negocio: negocio('pendiente'), dentroDelPanel: true),
      ),
    ));
    expect(find.byType(AppBar), findsOneWidget);
  });

  testWidgets('rechazado: no muestra "¿Qué pasa ahora?"', (tester) async {
    await tester.pumpWidget(MaterialApp(home: EstadoNegocioScreen(negocio: negocio('rechazado'))));
    expect(find.text('Tu solicitud no fue aprobada'), findsOneWidget);
    expect(find.text('¿Qué pasa ahora?'), findsNothing);
  });
}
