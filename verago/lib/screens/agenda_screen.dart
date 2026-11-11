import 'package:flutter/material.dart';

import '../models/evento.dart';
import '../services/eventos_service.dart';
import '../theme/app_theme.dart';
import '../widgets/estado_vacio.dart';
import '../widgets/etiqueta.dart';

/// AGENDA: eventos culturales del centro.
///
/// Cómo funciona: pide a `EventosService` los eventos que aún no terminan
/// y los separa en "Hoy" (en curso o que empiezan hoy) y "Próximos".
/// Los cancelados se muestran tachados para avisar al visitante.
class AgendaScreen extends StatefulWidget {
  const AgendaScreen({super.key});

  @override
  State<AgendaScreen> createState() => _AgendaScreenState();
}

class _AgendaScreenState extends State<AgendaScreen> {
  final _servicio = EventosService();
  late Future<List<Evento>> _futuro;
  bool _verHoy = true;

  @override
  void initState() {
    super.initState();
    _futuro = _servicio.obtenerProximos();
  }

  void _recargar() => setState(() => _futuro = _servicio.obtenerProximos());

  bool _esHoy(Evento e, DateTime ahora) =>
      e.enCurso(ahora) ||
      (e.inicia.year == ahora.year && e.inicia.month == ahora.month && e.inicia.day == ahora.day);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Agenda')),
      body: FutureBuilder<List<Evento>>(
        future: _futuro,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return EstadoVacio(
              icono: Icons.wifi_off,
              titulo: 'Algo salió mal',
              mensaje: snapshot.error.toString(),
              textoBoton: 'Reintentar',
              alPresionar: _recargar,
            );
          }
          final ahora = DateTime.now();
          final eventos = snapshot.data!;
          final hoy = eventos.where((e) => _esHoy(e, ahora)).toList();
          final proximos = eventos.where((e) => !_esHoy(e, ahora)).toList();
          final visibles = _verHoy ? hoy : proximos;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: SegmentedButton<bool>(
                  segments: [
                    ButtonSegment(value: true, label: Text('Hoy (${hoy.length})')),
                    ButtonSegment(value: false, label: Text('Próximos (${proximos.length})')),
                  ],
                  selected: {_verHoy},
                  onSelectionChanged: (s) => setState(() => _verHoy = s.first),
                ),
              ),
              Expanded(
                child: visibles.isEmpty
                    ? EstadoVacio(
                        icono: Icons.event_busy,
                        titulo: _verHoy ? 'No hay eventos hoy' : 'No hay eventos próximos',
                        mensaje: _verHoy
                            ? 'Revisa los próximos días.'
                            : 'Vuelve pronto: aquí aparecerán nuevos eventos.',
                        textoBoton: _verHoy ? 'Ver próximos' : null,
                        alPresionar: _verHoy ? () => setState(() => _verHoy = false) : null,
                      )
                    : RefreshIndicator(
                        onRefresh: () async {
                          _recargar();
                          await _futuro;
                        },
                        child: ListView.builder(
                          padding: const EdgeInsets.only(bottom: 16),
                          itemCount: visibles.length,
                          itemBuilder: (_, i) => _TarjetaEvento(evento: visibles[i], ahora: ahora),
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _TarjetaEvento extends StatelessWidget {
  const _TarjetaEvento({required this.evento, required this.ahora});

  final Evento evento;
  final DateTime ahora;

  static const _meses = ['ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sep', 'oct', 'nov', 'dic'];

  String _hora(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  void _verDetalle(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(evento.titulo, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text('${evento.inicia.day} ${_meses[evento.inicia.month - 1]} · '
                '${_hora(evento.inicia)} – ${_hora(evento.termina)}'),
            if (evento.lugarNombre != null) Text(evento.lugarNombre!),
            if (evento.descripcion != null) ...[
              const SizedBox(height: 12),
              Text(evento.descripcion!, style: const TextStyle(height: 1.4)),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tachado = evento.cancelado ? TextDecoration.lineThrough : null;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _verDetalle(context),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Fecha en bloque, como un calendario.
              Container(
                width: 56,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: VgColores.terracota.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      '${evento.inicia.day}',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: VgColores.terracota,
                      ),
                    ),
                    Text(
                      _meses[evento.inicia.month - 1],
                      style: const TextStyle(color: VgColores.terracota),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      evento.titulo,
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, decoration: tachado),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${_hora(evento.inicia)} – ${_hora(evento.termina)}'
                      '${evento.lugarNombre != null ? ' · ${evento.lugarNombre}' : ''}',
                      style: TextStyle(color: Colors.black.withValues(alpha: 0.65)),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        if (evento.cancelado)
                          const Etiqueta('Cancelado', color: Color(0xFF9B2C2C), icono: Icons.cancel_outlined)
                        else if (evento.enCurso(ahora))
                          const Etiqueta('En curso', color: VgColores.verdePalma, icono: Icons.play_circle_outline),
                        if (evento.esGratuito)
                          const Etiqueta('Gratuito', color: VgColores.azulGolfo),
                        if (evento.esDemo) const Etiqueta.demo(),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
