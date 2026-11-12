// Pruebas de las fotos de los lugares (sin internet ni Supabase).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verago/models/lugar.dart';
import 'package:verago/services/fotos_service.dart';
import 'package:verago/widgets/foto_lugar.dart';

Lugar lugar({String? foto}) => Lugar.fromJson({
      'id': 'abc-123',
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
      'participa_pasaporte': true,
      'foto_url': foto,
    });

void main() {
  test('lee la foto del lugar', () {
    expect(lugar().fotoUrl, isNull);
    expect(lugar(foto: 'https://x/foto.jpg').fotoUrl, 'https://x/foto.jpg');
  });

  test('saca la ruta dentro del bucket a partir de la URL pública', () {
    expect(
      FotosService.rutaEnBucket(
          'https://p.supabase.co/storage/v1/object/public/fotos-lugares/abc-123/foto_1.jpg'),
      'abc-123/foto_1.jpg',
    );
    expect(FotosService.rutaEnBucket('https://otra.com/foto.jpg'), isNull);
    expect(FotosService.rutaEnBucket(null), isNull);
  });

  test('solo acepta JPG, PNG o WEBP', () {
    expect(FotosService.tipoDeImagen('foto.JPG', null)?.mime, 'image/jpeg');
    expect(FotosService.tipoDeImagen('x', 'image/png')?.extension, 'png');
    expect(FotosService.tipoDeImagen('foto.webp', null)?.mime, 'image/webp');
    expect(FotosService.tipoDeImagen('documento.pdf', 'application/pdf'), isNull);
  });

  testWidgets('sin foto muestra el ícono de la categoría', (tester) async {
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: FotoLugar(lugar: lugar(), ancho: 56, alto: 56))));
    expect(find.byIcon(Icons.local_cafe), findsOneWidget);
    expect(find.byType(Image), findsNothing);
  });

  testWidgets('con foto usa la imagen de internet', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: FotoLugar(lugar: lugar(foto: 'https://x/foto.jpg'), ancho: 56, alto: 56)),
    ));
    expect(find.byType(Image), findsOneWidget);
  });

  testWidgets('el editor ofrece elegir y tomar foto (y quitar si ya hay)', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: EditorFoto(lugar: lugar(foto: 'https://x/foto.jpg'), alGuardar: (_) async {})),
    ));
    expect(find.text('Cambiar foto'), findsOneWidget);
    expect(find.text('Tomar foto'), findsOneWidget);
    expect(find.text('Quitar'), findsOneWidget);
  });
}
