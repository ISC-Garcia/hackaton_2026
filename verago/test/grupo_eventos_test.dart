// Pruebas de la Agenda: ordenar y juntar el mismo evento del mismo día.

import 'package:flutter_test/flutter_test.dart';
import 'package:verago/models/evento.dart';
import 'package:verago/models/grupo_eventos.dart';

Evento ev(String id, String titulo, DateTime inicia, {String? lugar = 'z', int horas = 1}) => Evento(
      id: id,
      titulo: titulo,
      descripcion: null,
      inicia: inicia,
      termina: inicia.add(Duration(hours: horas)),
      estado: 'publicado',
      esGratuito: true,
      esDemo: true,
      lugarId: lugar,
      lugarNombre: null,
      costoAproxMxn: null,
    );

void main() {
  final barco10 = ev('a', 'Paseo en barco', DateTime(2026, 11, 14, 10));
  final barco12 = ev('b', 'paseo  en BARCO', DateTime(2026, 11, 14, 12)); // mismo nombre, otra escritura
  final barco14 = ev('c', 'Paseo en barco', DateTime(2026, 11, 14, 14));
  final danzon = ev('d', 'Danzón', DateTime(2026, 11, 14, 11));
  final barcoOtroDia = ev('e', 'Paseo en barco', DateTime(2026, 11, 15, 10));

  test('ordena de más pronto a más lejano y al revés', () {
    final grupos = GrupoEventos.agrupar([barcoOtroDia, danzon, barco10]);
    expect(grupos.map((g) => g.primero.id), ['a', 'd', 'e']);
    final alReves = GrupoEventos.agrupar([barcoOtroDia, danzon, barco10], masLejanoPrimero: true);
    expect(alReves.map((g) => g.primero.id), ['e', 'd', 'a']);
  });

  test('junta el mismo evento del mismo día (no el de otro día ni otro lugar)', () {
    final otroLugar = ev('f', 'Paseo en barco', DateTime(2026, 11, 14, 16), lugar: 'malecon');
    final grupos = GrupoEventos.agrupar([barco14, danzon, barco10, barco12, barcoOtroDia, otroLugar]);
    final barco = grupos.firstWhere((g) => g.primero.id == 'a');
    expect(barco.eventos.map((e) => e.id), ['a', 'b', 'c']);
    expect(grupos, hasLength(4)); // barco (3 horas), danzón, barco en otro lugar, barco otro día
  });

  test('horario a la derecha: "Cada 2 h" si van parejas', () {
    final g = GrupoEventos.agrupar([barco10, barco12, barco14]).single;
    expect(g.textoHorario.principal, 'Cada 2 h');
    expect(g.textoHorario.detalle, '10:00 a 14:00');
  });

  test('horario a la derecha: lista de horas si no van parejas', () {
    final g = GrupoEventos.agrupar([barco10, ev('x', 'Paseo en barco', DateTime(2026, 11, 14, 17, 30))]).single;
    expect(g.textoHorario.principal, '10:00 · 17:30');
  });

  test('un solo evento muestra inicio y fin', () {
    final g = GrupoEventos.agrupar([danzon]).single;
    expect(g.esVarios, isFalse);
    expect(g.textoHorario.principal, '11:00 – 12:00');
  });
}
