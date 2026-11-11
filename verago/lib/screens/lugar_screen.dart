import 'package:flutter/material.dart';

import '../models/lugar.dart';
import '../services/distancia.dart';
import '../theme/app_theme.dart';
import '../widgets/categoria_estilo.dart';
import '../widgets/etiqueta.dart';
import '../widgets/mapa_lugares.dart';
import '../widgets/tarjeta_lugar.dart';

/// FICHA DEL LUGAR: toda la información de un lugar o comercio.
///
/// Incluye "Cerca de aquí": comercios a pocos minutos caminando.
/// Es el descubrimiento comercial del documento: después de ver un lugar,
/// VeraGo sugiere otro cercano de forma natural, no como publicidad.
class LugarScreen extends StatelessWidget {
  const LugarScreen({super.key, required this.lugar, required this.todos});

  final Lugar lugar;

  /// Todos los lugares (para calcular cuáles están cerca de este).
  final List<Lugar> todos;

  /// Distancia máxima para "Cerca de aquí": 10 minutos caminando.
  static const _minutosCerca = 10;

  static const _dias = ['Domingo', 'Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado'];

  List<Lugar> _comerciosCercanos() {
    final cercanos = todos
        .where((l) =>
            l.id != lugar.id &&
            l.esComercio &&
            Distancia.minutosCaminando(lugar.punto, l.punto) <= _minutosCerca)
        .toList()
      ..sort((a, b) => Distancia.metros(lugar.punto, a.punto)
          .compareTo(Distancia.metros(lugar.punto, b.punto)));
    return cercanos.take(4).toList();
  }

  @override
  Widget build(BuildContext context) {
    final estilo = CategoriaEstilo.de(lugar.categoriaClave);
    final cercanos = _comerciosCercanos();
    final hoy = DateTime.now().weekday % 7;

    return Scaffold(
      appBar: AppBar(),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          // Encabezado: en lugar de foto, bloque de color de la categoría.
          Container(
            height: 140,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: estilo.color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(estilo.icono, size: 64, color: estilo.color),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(lugar.nombre, style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 4),
                Text(
                  '${lugar.categoriaNombre} · ${Distancia.texto(Distancia.zocalo, lugar.punto)} del Zócalo',
                  style: TextStyle(color: Colors.black.withValues(alpha: 0.65)),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    Etiqueta.apertura(lugar.estadoEn(DateTime.now())),
                    if (lugar.participaPasaporte)
                      const Etiqueta('Da sello en tu pasaporte', color: VgColores.azulGolfo, icono: Icons.approval),
                    if (lugar.esDemo) const Etiqueta.demo(),
                  ],
                ),
                if (lugar.descripcion != null) ...[
                  const SizedBox(height: 16),
                  Text(lugar.descripcion!, style: const TextStyle(fontSize: 16, height: 1.4)),
                ],
                const SizedBox(height: 8),
                Text(
                  'Visita sugerida: ${lugar.duracionVisitaMin} min',
                  style: TextStyle(color: Colors.black.withValues(alpha: 0.65)),
                ),
                if (lugar.participaPasaporte) ...[
                  const SizedBox(height: 16),
                  _Aviso(
                    icono: Icons.qr_code_2,
                    texto: 'Pide en el comercio su código QR y escanéalo desde la pestaña '
                        'Pasaporte para ganar su sello.',
                  ),
                ],
                _Seccion('Horario'),
                if (lugar.horarios.isEmpty)
                  const Text('Horario no disponible. Consulta directamente en el lugar.')
                else
                  for (var d = 0; d < 7; d++)
                    _FilaHorario(
                      dia: _dias[d],
                      horario: lugar.horarioDel(d),
                      esHoy: d == hoy,
                    ),
                if (lugar.esDemo && lugar.horarios.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      'Horario ficticio de demostración.',
                      style: TextStyle(fontSize: 12, color: Colors.black.withValues(alpha: 0.55)),
                    ),
                  ),
                if (lugar.direccion != null || lugar.telefono != null) ...[
                  _Seccion('Contacto'),
                  if (lugar.direccion != null)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.place_outlined),
                      title: Text(lugar.direccion!),
                    ),
                  if (lugar.telefono != null)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.phone_outlined),
                      title: Text(lugar.telefono!),
                    ),
                ],
                _Seccion('Ubicación'),
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: SizedBox(
                    height: 180,
                    child: MapaLugares(
                      lugares: [lugar],
                      centro: lugar.punto,
                      zoom: 17,
                      interactivo: false,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Ubicación aproximada.',
                  style: TextStyle(fontSize: 12, color: Colors.black.withValues(alpha: 0.55)),
                ),
              ],
            ),
          ),
          if (cercanos.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _Seccion('Cerca de aquí'),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
              child: Text(
                'Comercios locales a menos de $_minutosCerca minutos caminando.',
                style: TextStyle(color: Colors.black.withValues(alpha: 0.65)),
              ),
            ),
            for (final c in cercanos)
              TarjetaLugar(
                lugar: c,
                desde: lugar.punto,
                alTocar: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => LugarScreen(lugar: c, todos: todos)),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _Seccion extends StatelessWidget {
  const _Seccion(this.titulo);
  final String titulo;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 24, bottom: 8),
        child: Text(titulo, style: Theme.of(context).textTheme.titleLarge),
      );
}

class _FilaHorario extends StatelessWidget {
  const _FilaHorario({required this.dia, required this.horario, required this.esHoy});

  final String dia;
  final Horario? horario;
  final bool esHoy;

  @override
  Widget build(BuildContext context) {
    final estilo = TextStyle(fontWeight: esHoy ? FontWeight.w700 : FontWeight.w400);
    final h = horario;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(child: Text(esHoy ? '$dia (hoy)' : dia, style: estilo)),
          Text(
            h == null ? 'Cerrado' : '${Horario.formato(h.abre)} – ${Horario.formato(h.cierra)}',
            style: estilo,
          ),
        ],
      ),
    );
  }
}

class _Aviso extends StatelessWidget {
  const _Aviso({required this.icono, required this.texto});
  final IconData icono;
  final String texto;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: VgColores.azulGolfo.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icono, color: VgColores.azulGolfo),
            const SizedBox(width: 10),
            Expanded(child: Text(texto)),
          ],
        ),
      );
}
