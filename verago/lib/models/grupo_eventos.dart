import '../i18n/idioma.dart';
import 'evento.dart';

/// Un GRUPO de la Agenda: el mismo evento (mismo nombre y lugar) el MISMO DÍA
/// a distintas horas. Se muestra como una sola tarjeta con las horas a la
/// derecha (ej. "Paseo en barco": 10:00 · 12:00 · 16:00).
class GrupoEventos {
  GrupoEventos(this.eventos);

  /// Ordenados por hora de inicio. Siempre hay al menos uno.
  final List<Evento> eventos;

  Evento get primero => eventos.first;
  bool get esVarios => eventos.length > 1;
  DateTime get dia => DateTime(primero.inicia.year, primero.inicia.month, primero.inicia.day);

  static String hora(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  /// Texto de horario para la derecha de la tarjeta:
  /// - 1 evento: "18:00 – 20:00".
  /// - 3 o más con la misma separación: "Cada 2 h" + "10:00 a 16:00".
  /// - Si no: las horas, "10:00 · 12:00 · 17:30".
  ({String principal, String? detalle}) get textoHorario {
    if (!esVarios) {
      return (principal: '${hora(primero.inicia)} – ${hora(primero.termina)}', detalle: null);
    }
    final inicios = [for (final e in eventos) e.inicia];
    final pasos = <int>{
      for (var i = 1; i < inicios.length; i++) inicios[i].difference(inicios[i - 1]).inMinutes,
    };
    if (eventos.length >= 3 && pasos.length == 1 && pasos.first > 0) {
      return (
        principal: tr('Cada {tiempo}', {'tiempo': _duracion(pasos.first)}),
        detalle: tr('{desde} a {hasta}', {'desde': hora(inicios.first), 'hasta': hora(inicios.last)}),
      );
    }
    return (principal: inicios.map(hora).join(' · '), detalle: null);
  }

  static String _duracion(int minutos) {
    if (minutos % 60 == 0) return '${minutos ~/ 60} h';
    if (minutos < 60) return '$minutos min';
    return tr('{v} h {v2} min', {'v': minutos ~/ 60, 'v2': minutos % 60});
  }

  /// Clave para juntar: mismo día, mismo nombre (sin mayúsculas ni espacios
  /// de más) y mismo lugar.
  static String _clave(Evento e) =>
      '${e.inicia.year}-${e.inicia.month}-${e.inicia.day}|'
      '${e.titulo.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ')}|${e.lugarId ?? ''}';

  /// Ordena los eventos por hora (de más pronto a más lejano, o al revés) y
  /// junta los repetidos del mismo día. El grupo queda donde está su primera
  /// hora en ese orden.
  static List<GrupoEventos> agrupar(List<Evento> eventos, {bool masLejanoPrimero = false}) {
    final ordenados = [...eventos]..sort((a, b) => a.inicia.compareTo(b.inicia));
    final porClave = <String, List<Evento>>{};
    for (final e in ordenados) {
      porClave.putIfAbsent(_clave(e), () => []).add(e);
    }
    final grupos = [for (final lista in porClave.values) GrupoEventos(lista)];
    grupos.sort((a, b) => a.primero.inicia.compareTo(b.primero.inicia));
    return masLejanoPrimero ? grupos.reversed.toList() : grupos;
  }
}
