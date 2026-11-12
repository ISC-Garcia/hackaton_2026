// Pruebas de la edición de la Agenda por el admin (sin internet):
// - Validación de fechas y costo.
// - Cómo se convierten los datos del formulario en una fila de `eventos`.

import 'package:flutter_test/flutter_test.dart';
import 'package:verago/services/eventos_service.dart';
import 'package:verago/services/validaciones.dart';

void main() {
  final inicio = DateTime(2026, 11, 20, 18, 0);

  group('Fechas del evento', () {
    test('debe terminar después de iniciar', () {
      expect(Validaciones.fechasEvento(inicio, inicio.add(const Duration(hours: 2))), isNull);
      expect(Validaciones.fechasEvento(inicio, inicio), isNotNull);
      expect(Validaciones.fechasEvento(inicio, inicio.subtract(const Duration(hours: 1))), isNotNull);
    });
    test('no puede durar más de 30 días', () {
      expect(Validaciones.fechasEvento(inicio, inicio.add(const Duration(days: 31))), isNotNull);
    });
  });

  test('costo: solo números o vacío', () {
    expect(Validaciones.costo(''), isNull);
    expect(Validaciones.costo('150'), isNull);
    expect(Validaciones.costo('15o'), isNotNull);
  });

  group('Datos del evento → fila de la tabla', () {
    DatosEvento datos({required bool gratuito, String estado = 'publicado'}) => DatosEvento(
          titulo: '  Noche de danzón  ',
          descripcion: '',
          lugarId: 'zocalo',
          inicia: inicio,
          termina: inicio.add(const Duration(hours: 2)),
          estado: estado,
          esGratuito: gratuito,
          costoAproxMxn: 150,
        );

    test('limpia el título y deja vacía la descripción en null', () {
      final fila = datos(gratuito: true).aFila();
      expect(fila['titulo'], 'Noche de danzón');
      expect(fila['descripcion'], isNull);
    });
    test('si es gratuito no guarda costo', () {
      expect(datos(gratuito: true).aFila()['costo_aprox_mxn'], isNull);
      expect(datos(gratuito: false).aFila()['costo_aprox_mxn'], 150);
    });
    test('las fechas viajan en UTC y el estado se respeta', () {
      final fila = datos(gratuito: true, estado: 'pendiente').aFila();
      expect((fila['inicia'] as String).endsWith('Z'), isTrue);
      expect(fila['estado'], 'pendiente');
    });
  });
}
