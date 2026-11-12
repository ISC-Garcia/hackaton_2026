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
/// FILTRO POR INTERESES: SOLO entran lugares de las categorías que eligió el
/// visitante. Si eligió "Museos", la ruta trae solo museos. (Antes se metía a
/// fuerza 1 negocio formal y 1 Punto VeraGo; el equipo pidió quitarlo. Los
/// Puntos VeraGo ahora se pueden elegir como interés.)
///
/// Puntuación de un lugar = interés del lugar ÷ (minutos caminando + minutos
/// de visita). Así gana lo más interesante que cueste menos tiempo.
///
/// Es Dart puro: no usa internet ni pantallas, por eso se prueba fácil.
class RutasService {
  Ruta generar(PeticionRuta p, List<Lugar> lugares) {
    final fin = p.horaInicio.add(Duration(minutes: p.minutosDisponibles));
    final paradas = <Parada>[];
    final usados = <String>{};
    var posicion = p.inicio;
    var reloj = p.horaInicio;

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
        // Solo lo que le interesa.
        if (!_teInteresa(p, l)) continue;

        final caminata = Distancia.minutosCaminando(posicion, l.punto,
            velocidad: p.ritmo.metrosPorMinuto);
        final llegada = reloj.add(Duration(minutes: caminata));
        final salida = llegada.add(Duration(minutes: l.duracionVisitaMin));

        // ¿Alcanza el tiempo total?
        if (salida.isAfter(fin)) continue;
        // ¿Estará abierto al llegar y hasta terminar la visita?
        if (!_abiertoDurante(l, llegada, salida)) continue;

        final puntaje = l.interes / (caminata + l.duracionVisitaMin);

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
      posicion = mejor.punto;
      reloj = llegada.add(Duration(minutes: mejor.duracionVisitaMin));
    }

    return Ruta(peticion: p, paradas: paradas);
  }

  /// ¿El lugar es de una categoría que eligió el visitante?
  /// (Sin intereses, todo cuenta: así nunca falla aunque llegue vacío).
  bool _teInteresa(PeticionRuta p, Lugar l) =>
      p.intereses.isEmpty || p.intereses.contains(l.categoriaClave);

  /// Sugerencia para seguir explorando: el comercio FORMAL más cercano a
  /// `punto` que no esté en `yaIncluidos`, a menos de 10 min caminando.
  /// (Los informales no: ya se visitan dentro de su Punto VeraGo).
  /// Con `intereses` (al final de una ruta), solo de esas categorías: si
  /// eligió museos, no le sugerimos una taquería.
  Lugar? sugerenciaCercana(LatLng punto, List<Lugar> lugares, Set<String> yaIncluidos,
      {Set<String> intereses = const {}}) {
    Lugar? mejor;
    var mejorMin = 11;
    for (final l in lugares) {
      if (!l.esFormal || !l.enRecorridoAPie || yaIncluidos.contains(l.id)) continue;
      if (intereses.isNotEmpty && !intereses.contains(l.categoriaClave)) continue;
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
    if (p.intereses.contains(l.categoriaClave) && !l.esPunto) {
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
