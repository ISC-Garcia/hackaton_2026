// Prueba: con sesión y datos, el pasaporte dibuja saludo, contador,
// botón de escanear, colección e historial SIN errores de diseño.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verago/models/lugar.dart';
import 'package:verago/models/sello.dart';
import 'package:verago/screens/pasaporte_screen.dart';
import 'package:verago/theme/app_theme.dart';

Lugar comercio(String id, String nombre, {String? foto}) => Lugar(
      id: id,
      nombre: nombre,
      descripcion: null,
      categoriaClave: 'cafeteria',
      categoriaNombre: 'Cafeterías',
      latitud: 19.1985,
      longitud: -96.1338,
      direccion: null,
      telefono: null,
      interes: 4,
      duracionVisitaMin: 30,
      esComercio: true,
      esDemo: true,
      participaPasaporte: true,
      horarios: const [],
      fotoUrl: foto,
    );

void main() {
  Future<void> dibujar(WidgetTester tester, DatosPasaporte datos) async {
    await tester.pumpWidget(MaterialApp(
      theme: VgTema.claro,
      home: PasaporteScreen(cargadorDePrueba: () async => datos),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('Pasaporte con un sello', (tester) async {
    await dibujar(
      tester,
      DatosPasaporte(
        const Perfil(nombre: 'Ana', rol: 'usuario'),
        [Sello(lugarId: 'a', lugarNombre: 'Café Brisa del Golfo', categoriaClave: 'cafeteria', fecha: DateTime(2026, 11, 11, 10))],
        [comercio('a', 'Café Brisa del Golfo'), comercio('b', 'Cocina La Marea')],
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.text('Hola, Ana'), findsOneWidget);
    expect(find.text('1 de 2'), findsOneWidget);
    expect(find.text('Escanear QR'), findsOneWidget);
    expect(find.text('Tu colección'), findsOneWidget);
    // Un usuario normal ve "Soy un negocio"; un comerciante ve su panel.
    expect(find.text('Soy un negocio'), findsOneWidget);
  });

  testWidgets('Pasaporte vacío (sin sellos ni comercios)', (tester) async {
    await dibujar(tester, const DatosPasaporte(Perfil(nombre: 'Ana', rol: 'comerciante'), [], []));
    expect(tester.takeException(), isNull);
    expect(find.text('0 de 0'), findsOneWidget);
    expect(find.text('Panel de mi negocio'), findsOneWidget);
  });

  testWidgets('el sello ganado muestra la foto del negocio; el que falta, candado', (tester) async {
    await dibujar(
      tester,
      DatosPasaporte(
        const Perfil(nombre: 'Ana', rol: 'usuario'),
        [Sello(lugarId: 'a', lugarNombre: 'Café Brisa del Golfo', categoriaClave: 'cafeteria', fecha: DateTime(2026, 11, 11, 10))],
        [
          comercio('a', 'Café Brisa del Golfo', foto: 'https://x/cafe.jpg'),
          comercio('b', 'Cocina La Marea', foto: 'https://x/cocina.jpg'),
        ],
      ),
    );
    await tester.scrollUntilVisible(find.text('Cocina La Marea'), 200, scrollable: find.byType(Scrollable).first);
    // Solo el sello ganado usa la foto (con su distintivo); el otro sigue gris.
    expect(find.byType(Image), findsOneWidget);
    expect(find.byIcon(Icons.approval), findsOneWidget);
  });
}
