import 'package:latlong2/latlong.dart';

import '../models/lugar.dart';
import 'distancia.dart';

/// Ritmo de caminata que elige el visitante (preferencia de movilidad).
enum Ritmo {
  tranquilo('Tranquilo', 50), // 3 km/h
  normal('Normal', 67), // 4 km/h
  rapido('Rápido', 83); // 5 km/h

  const Ritmo(this.nombre, this.metrosPorMinuto);
  final String nombre;
  final double metrosPorMinuto;
}

/// Lo que el visitante pide.
class PeticionRuta {
  const PeticionRuta({
    required this.inicio,
    required this.nombreInicio,
    required this.horaInicio,
    required this.minutosDisponibles,
    required this.intereses,
    this.ritmo = Ritmo.normal,
    this.excluir = const {},
  });

  final LatLng inicio;
  final String nombreInicio;
  final DateTime horaInicio;
  final int minutosDisponibles;

  /// Claves de categorías favoritas (ej. {'historia', 'restaurante'}).
  final Set<String> intereses;
  final Ritmo ritmo;

  /// Ids de lugares que el visitante quitó de la ruta.
  final Set<String> excluir;
}

/// Una parada de la ruta.
class Parada {
  const Parada({
    required this.lugar,
    required this.llegada,
    required this.minutosCaminando,
    required this.motivo,
  });

  final Lugar lugar;
  final DateTime llegada;
  final int minutosCaminando; // desde la parada anterior
  final String motivo; // por qué se recomienda

  DateTime get salida => llegada.add(Duration(minutes: lugar.duracionVisitaMin));
}

/// La ruta generada.
class Ruta {
  const Ruta({required this.peticion, required this.paradas});

  final PeticionRuta peticion;
  final List<Parada> paradas;

  DateTime get fin => paradas.isEmpty ? peticion.horaInicio : paradas.last.salida;
  int get minutosUsados => fin.difference(peticion.horaInicio).inMinutes;
  int get minutosLibres => peticion.minutosDisponibles - minutosUsados;
  int get minutosCaminando => paradas.fold(0, (s, p) => s + p.minutosCaminando);
}

/// GENERADOR DE RUTAS (sección 16 del documento).
///
/// Algoritmo VORAZ (greedy): en cada paso elige el mejor lugar disponible
/// en ese momento, lo agrega a la ruta y "se mueve" ahí. Repite hasta que
/// ningún lugar quepa en el tiempo que queda.
///
/// Puntuación de un lugar = (interés del lugar + 2 si es de una categoría
/// favorita) ÷ (minutos caminando + minutos de visita).
/// Así gana lo más interesante que cueste menos tiempo.
///
/// REGLA DEL EQUIPO: toda ruta incluye al menos 1 comercio FORMAL y al menos
/// 1 PUNTO VERAGO (si caben en el tiempo y están abiertos). Mientras falte
/// alguno, esos lugares reciben una PRIORIDAD enorme (+1000), así el
/// algoritmo los elige en cuanto son posibles.
///
/// Es Dart puro: no usa internet ni pantallas, por eso se prueba fácil.
class RutasService {
  static const _bonoFavorito = 2;
  static const _prioridad = 1000;

  Ruta generar(PeticionRuta p, List<Lugar> lugares) {
    final fin = p.horaInicio.add(Duration(minutes: p.minutosDisponibles));
    final paradas = <Parada>[];
    final usados = <String>{};
    var posicion = p.inicio;
    var reloj = p.horaInicio;
    var tieneFormal = false;
    var tienePunto = false;

    // Cuántos comerciantes hay en cada Punto VeraGo.
    final comerciantesPorPunto = <String, int>{};
    for (final l in lugares) {
      final punto = l.puntoId;
      if (punto != null) comerciantesPorPunto[punto] = (comerciantesPorPunto[punto] ?? 0) + 1;
    }

    // Candidatos:
    // - se pueden recorrer a pie y el visitante no los quitó;
    // - los comerciantes informales NO son paradas sueltas: la parada es su punto;
    // - un punto solo cuenta si tiene comerciantes.
    final candidatos = lugares
        .where((l) =>
            l.enRecorridoAPie &&
            !p.excluir.contains(l.id) &&
            !l.esInformal &&
            (!l.esPunto || comerciantesPorPunto.containsKey(l.id)))
        .toList();

    while (true) {
      Lugar? mejor;
      var mejorPuntaje = -1.0;
      var mejorCaminata = 0;

      for (final l in candidatos) {
        if (usados.contains(l.id)) continue;

        final caminata = Distancia.minutosCaminando(posicion, l.punto,
            velocidad: p.ritmo.metrosPorMinuto);
        final llegada = reloj.add(Duration(minutes: caminata));
        final salida = llegada.add(Duration(minutes: l.duracionVisitaMin));

        // ¿Alcanza el tiempo total?
        if (salida.isAfter(fin)) continue;
        // ¿Estará abierto al llegar y hasta terminar la visita?
        if (!_abiertoDurante(l, llegada, salida)) continue;

        final favorito = p.intereses.contains(l.categoriaClave);
        final prioridad = (!tieneFormal && l.esFormal) || (!tienePunto && l.esPunto) ? _prioridad : 0;
        final puntaje = (l.interes + (favorito ? _bonoFavorito : 0) + prioridad) /
            (caminata + l.duracionVisitaMin);

        if (puntaje > mejorPuntaje) {
          mejor = l;
          mejorPuntaje = puntaje;
          mejorCaminata = caminata;
        }
      }

      if (mejor == null) break; // ya no cabe nada más

      final llegada = reloj.add(Duration(minutes: mejorCaminata));
      paradas.add(Parada(
        lugar: mejor,
        llegada: llegada,
        minutosCaminando: mejorCaminata,
        motivo: _motivo(mejor, p, mejorCaminata, paradas.isEmpty, comerciantesPorPunto[mejor.id] ?? 0),
      ));
      usados.add(mejor.id);
      if (mejor.esFormal) tieneFormal = true;
      if (mejor.esPunto) tienePunto = true;
      posicion = mejor.punto;
      reloj = llegada.add(Duration(minutes: mejor.duracionVisitaMin));
    }

    return Ruta(peticion: p, paradas: paradas);
  }

  /// Sugerencia para seguir explorando: el comercio más cercano a `punto`
  /// que no esté en `yaIncluidos`, a menos de 10 min caminando.
  Lugar? sugerenciaCercana(LatLng punto, List<Lugar> lugares, Set<String> yaIncluidos) {
    Lugar? mejor;
    var mejorMin = 11;
    for (final l in lugares) {
      if (!l.esComercio || !l.enRecorridoAPie || yaIncluidos.contains(l.id)) continue;
      final min = Distancia.minutosCaminando(punto, l.punto);
      if (min < mejorMin) {
        mejor = l;
        mejorMin = min;
      }
    }
    return mejor;
  }

  /// Si el lugar no tiene horario cargado, se permite (los lugares públicos
  /// como plazas no tienen horario), y la pantalla avisa "confirma horario".
  bool _abiertoDurante(Lugar l, DateTime llegada, DateTime salida) {
    if (l.horarios.isEmpty) return true;
    final h = l.horarioDel(llegada.weekday % 7);
    if (h == null) return false;
    final minLlegada = llegada.hour * 60 + llegada.minute;
    final mismoDia = salida.day == llegada.day;
    final minSalida = mismoDia ? salida.hour * 60 + salida.minute : 24 * 60;
    return minLlegada >= h.abre && minSalida <= h.cierra;
  }

  /// Texto que explica por qué se eligió el lugar.
  String _motivo(Lugar l, PeticionRuta p, int caminata, bool esPrimera, int comerciantes) {
    final razones = <String>[];
    if (l.esPunto) {
      razones.add('Punto VeraGo: $comerciantes ${comerciantes == 1 ? 'emprendedor local' : 'emprendedores locales'}');
    }
    if (p.intereses.contains(l.categoriaClave)) {
      razones.add('Te interesa: ${l.categoriaNombre.toLowerCase()}');
    }
    if (l.interes >= 5) razones.add('Imperdible del centro');
    if (l.esFormal) razones.add('Comercio local');
    if (l.participaPasaporte) razones.add('Da sello en tu pasaporte');
    razones.add(esPrimera
        ? 'A $caminata min de ${p.nombreInicio}'
        : 'A $caminata min de la parada anterior');
    return razones.join(' · ');
  }
}
