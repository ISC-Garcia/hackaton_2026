// Pruebas del texto de costo de un evento en la Agenda.

import 'package:flutter_test/flutter_test.dart';
import 'package:verago/models/evento.dart';

Evento evento({required bool gratuito, int? costo}) => Evento(
      id: '1',
      titulo: 'Taller',
      descripcion: null,
      inicia: DateTime(2026, 11, 12, 10),
      termina: DateTime(2026, 11, 12, 12),
      estado: 'publicado',
      esGratuito: gratuito,
      esDemo: true,
      lugarId: null,
      lugarNombre: null,
      costoAproxMxn: costo,
    );

void main() {
  test('gratuito muestra "Gratuito" aunque tenga costo cargado', () {
    expect(evento(gratuito: true, costo: 100).textoCosto, 'Gratuito');
  });
  test('con costo muestra el aproximado en pesos', () {
    expect(evento(gratuito: false, costo: 150).textoCosto, '≈ \$150 MXN');
  });
  test('con costo pero sin precio cargado muestra "Con costo"', () {
    expect(evento(gratuito: false).textoCosto, 'Con costo');
  });
}
