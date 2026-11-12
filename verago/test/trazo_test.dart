// Pruebas del trazo por las calles (sin internet: se simula el servidor).

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:latlong2/latlong.dart';
import 'package:verago/services/trazo_service.dart';

void main() {
  const a = LatLng(19.1993, -96.1345);
  const b = LatLng(19.1985, -96.1338);

  test('la dirección usa "longitud,latitud" y el perfil a pie', () {
    final u = TrazoService.direccion([a, b]).toString();
    expect(u, contains('routed-foot'));
    expect(u, contains('-96.134500,19.199300;-96.133800,19.198500'));
  });

  test('lee el camino de la respuesta del servidor', () {
    final camino = TrazoService.leer({
      'code': 'Ok',
      'routes': [
        {
          'geometry': {
            'coordinates': [
              [-96.1345, 19.1993],
              [-96.1340, 19.1990],
              [-96.1338, 19.1985],
            ],
          },
        },
      ],
    });
    expect(camino, hasLength(3));
    expect(camino!.first.latitude, 19.1993);
    expect(camino.first.longitude, -96.1345);
  });

  test('respuesta sin ruta = null (se dibuja la línea recta)', () {
    expect(TrazoService.leer({'code': 'NoRoute'}), isNull);
  });

  test('si el servidor falla, devuelve null sin tronar', () async {
    final servicio = TrazoService(cliente: MockClient((_) async => http.Response('error', 500)));
    expect(await servicio.caminoPorCalles([a, const LatLng(19.19, -96.13)]), isNull);
  });

  test('con una sola parada no pide nada', () async {
    var llamadas = 0;
    final servicio = TrazoService(cliente: MockClient((_) async {
      llamadas++;
      return http.Response('{}', 200);
    }));
    expect(await servicio.caminoPorCalles([a]), isNull);
    expect(llamadas, 0);
  });
}
