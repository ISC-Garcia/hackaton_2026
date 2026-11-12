// Pruebas del panel de administración y de la dirección automática
// (sin internet).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verago/screens/admin_screen.dart';
import 'package:verago/services/admin_service.dart';
import 'package:verago/services/geocodificacion_service.dart';

void main() {
  group('Dirección desde el mapa (formato)', () {
    test('calle con número, colonia y ciudad', () {
      final d = GeocodificacionService.formatear({
        'road': 'Avenida Independencia',
        'house_number': '1080',
        'suburb': 'Centro',
        'city': 'Veracruz',
      });
      expect(d, 'Avenida Independencia 1080, Centro, Veracruz');
    });
    test('sin número usa solo la calle', () {
      expect(GeocodificacionService.formatear({'road': 'Calle Zaragoza', 'city': 'Veracruz'}),
          'Calle Zaragoza, Veracruz');
    });
    test('sin datos devuelve null', () {
      expect(GeocodificacionService.formatear(null), isNull);
      expect(GeocodificacionService.formatear({}), isNull);
    });
  });

  group('Datos de lugar (admin)', () {
    DatosLugar datos({required bool punto}) => DatosLugar(
          nombre: ' Parque Demo ',
          descripcion: '',
          categoriaId: 6,
          latitud: 19.19,
          longitud: -96.13,
          direccion: '',
          interes: 4,
          duracionVisitaMin: 30,
          esPunto: punto,
          enRecorridoAPie: true,
          publicado: true,
        );

    test('un Punto VeraGo siempre usa la categoría "Puntos VeraGo" (8)', () {
      expect(datos(punto: true).aFila()['categoria_id'], 8);
      expect(datos(punto: false).aFila()['categoria_id'], 6);
    });
    test('solo envía el costo de entrada si cambió (funciona aunque falte el SQL 014)', () {
      expect(datos(punto: false).aFila().containsKey('costo_entrada_mxn'), isFalse);
      const conCosto = DatosLugar(
        nombre: 'Museo',
        descripcion: '',
        categoriaId: 2,
        latitud: 19.19,
        longitud: -96.13,
        direccion: '',
        interes: 4,
        duracionVisitaMin: 30,
        esPunto: false,
        enRecorridoAPie: true,
        publicado: true,
        costoEntradaMxn: 50,
        incluirCosto: true,
      );
      expect(conCosto.aFila()['costo_entrada_mxn'], 50);
    });
    test('limpia textos y deja vacíos en null', () {
      final fila = datos(punto: false).aFila();
      expect(fila['nombre'], 'Parque Demo');
      expect(fila['descripcion'], isNull);
      expect(fila['direccion'], isNull);
    });
  });

  testWidgets('El panel de administración muestra sus opciones', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: AdminScreen()));
    expect(find.text('Solicitudes de negocios'), findsOneWidget);
    expect(find.text('Lugares y Puntos VeraGo'), findsOneWidget);
    expect(find.text('Estadísticas'), findsOneWidget);
  });

  testWidgets('"Agenda" en el panel abre la Agenda (antes regresaba al Pasaporte)', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: AdminScreen()));
    await tester.tap(find.text('Agenda'));
    await tester.pumpAndSettle();
    expect(find.text('Administración'), findsNothing); // ya no está el panel
    expect(find.widgetWithText(AppBar, 'Agenda'), findsOneWidget);
  });
}
