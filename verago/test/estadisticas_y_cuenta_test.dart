// Pruebas de estadísticas (ficticias por defecto y reales) y de
// "Borrar mi cuenta" (sin internet).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:verago/config.dart';
import 'package:verago/models/sello.dart';
import 'package:verago/screens/ajustes_screen.dart';
import 'package:verago/screens/estadisticas_screen.dart';
import 'package:verago/services/estadisticas_service.dart';

final _reales = Estadisticas.desdeJson({
  'estado': 'OK',
  'usuarios': 7,
  'turistas_con_sellos': 3,
  'sellos_total': 11,
  'sellos_7_dias': 4,
  'negocios_aprobados': 8,
  'negocios_pendientes': 1,
  'por_dia': [
    {'fecha': '2026-11-11', 'total': 3},
    {'fecha': '2026-11-12', 'total': 1},
  ],
  'top_negocios': [
    {'nombre': 'Café Brisa del Golfo', 'total': 5},
  ],
});

void main() {
  test('lee la respuesta de la función de estadísticas', () {
    expect(_reales.dato('sellos_total'), 11);
    expect(_reales.porDia, hasLength(2));
    expect(_reales.topNegocios['Café Brisa del Golfo'], 5);
  });

  testWidgets('por defecto muestra los datos FICTICIOS de demostración', (tester) async {
    await tester.pumpWidget(MaterialApp(home: EstadisticasScreen(cargadorDePrueba: () async => _reales)));
    expect(find.textContaining('DATOS FICTICIOS'), findsOneWidget);
    expect(find.text('214'), findsOneWidget);
    expect(find.text('132'), findsOneWidget);
  });

  testWidgets('en "Reales" muestra lo que hay en la base', (tester) async {
    await tester.pumpWidget(MaterialApp(home: EstadisticasScreen(cargadorDePrueba: () async => _reales)));
    await tester.tap(find.text('Reales'));
    await tester.pumpAndSettle();
    expect(find.text('11'), findsOneWidget); // sellos en total
    expect(find.text('Café Brisa del Golfo'), findsOneWidget);
  });

  testWidgets('el comerciante también ve sus números ficticios', (tester) async {
    await tester.pumpWidget(
        MaterialApp(home: EstadisticasScreen(deMiNegocio: true, cargadorDePrueba: () async => _reales)));
    expect(find.text('Mis estadísticas'), findsOneWidget);
    expect(find.text('turistas distintos'), findsOneWidget);
  });

  testWidgets('Ajustes: un usuario puede borrar su cuenta; un admin no', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const MaterialApp(
      home: AjustesScreen(perfil: Perfil(nombre: 'Ana', rol: 'usuario')),
    ));
    await tester.scrollUntilVisible(find.text('Borrar mi cuenta'), 300, scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text('Borrar mi cuenta'));
    await tester.pumpAndSettle();
    expect(find.text('¿Borrar tu cuenta para siempre?'), findsOneWidget);
    await tester.tap(find.text('Cancelar')); // no borra nada
    await tester.pumpAndSettle();

    await tester.pumpWidget(const MaterialApp(
      home: AjustesScreen(perfil: Perfil(nombre: 'Admin', rol: 'admin')),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Borrar mi cuenta'), findsNothing);
  });

  test('el correo de soporte viene por defecto', () {
    expect(Config.correoSoporte, 'ververagoo@gmail.com');
  });
}
