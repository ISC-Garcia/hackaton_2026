import 'dart:async';

import 'package:flutter/material.dart';

import '../models/evento.dart';
import '../services/auth_service.dart';
import '../services/error_verago.dart';
import '../services/eventos_service.dart';
import '../services/pasaporte_service.dart';
import '../theme/app_theme.dart';
import '../widgets/estado_vacio.dart';
import '../widgets/etiqueta.dart';
import 'evento_form_screen.dart';

/// AGENDA: eventos culturales del centro.
///
/// Cómo funciona: pide a `EventosService` los eventos que aún no terminan
/// y los separa en "Hoy" (en curso o que empiezan hoy) y "Próximos".
/// Los cancelados se muestran tachados para avisar al visitante.
///
/// ADMIN: si la cuenta tiene rol admin, aparece "Nuevo evento" y, al tocar
/// un evento, las opciones Editar / Publicar / Borrador / Cancelar / Eliminar.
/// Así el admin administra la agenda sin entrar a Supabase.
class AgendaScreen extends StatefulWidget {
  const AgendaScreen({super.key});

  @override
  State<AgendaScreen> createState() => _AgendaScreenState();
}

class _AgendaScreenState extends State<AgendaScreen> {
  final _servicio = EventosService();
  late Future<List<Evento>> _futuro;
  bool _verHoy = true;
  bool _esAdmin = false;
  StreamSubscription<dynamic>? _suscripcion;

  @override
  void initState() {
    super.initState();
    _futuro = _servicio.obtenerProximos();
    _revisarAdmin();
    // Si alguien entra o sale, volvemos a revisar si es admin.
    _suscripcion = AuthService().cambios.listen((_) => _revisarAdmin());
  }

  @override
  void dispose() {
    _suscripcion?.cancel();
    super.dispose();
  }

  /// ¿La cuenta con sesión es admin? (Solo decide qué botones se ven;
  /// la base de datos es la que permite o rechaza los cambios.)
  Future<void> _revisarAdmin() async {
    var admin = false;
    if (AuthService().usuario != null) {
      try {
        admin = (await PasaporteService().miPerfil()).esAdmin;
      } on ErrorVeraGo {
        admin = false;
      }
    }
    if (!mounted || admin == _esAdmin) return;
    setState(() => _esAdmin = admin);
    _recargar(); // el admin también ve los borradores
  }

  Future<void> _abrirFormulario([Evento? evento]) async {
    final guardo = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => EventoFormScreen(evento: evento)),
    );
    if (guardo == true) _recargar();
  }

  void _recargar() => setState(() {
        _futuro = _servicio.obtenerProximos()..ignore();
      });

  bool _esHoy(Evento e, DateTime ahora) =>
      e.enCurso(ahora) ||
      (e.inicia.year == ahora.year && e.inicia.month == ahora.month && e.inicia.day == ahora.day);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agenda'),
        actions: [
          // Sin eventos no hay lista que jalar para recargar: por eso el botón.
          IconButton(tooltip: 'Actualizar', icon: const Icon(Icons.refresh), onPressed: _recargar),
        ],
      ),
      floatingActionButton: _esAdmin
          ? FloatingActionButton.extended(
              onPressed: () => _abrirFormulario(),
              icon: const Icon(Icons.add),
              label: const Text('Nuevo evento'),
            )
          : null,
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
                          itemBuilder: (_, i) => _TarjetaEvento(
                            evento: visibles[i],
                            ahora: ahora,
                            esAdmin: _esAdmin,
                            alEditar: _abrirFormulario,
                            alCambiar: _recargar,
                          ),
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
  const _TarjetaEvento({
    required this.evento,
    required this.ahora,
    required this.esAdmin,
    required this.alEditar,
    required this.alCambiar,
  });

  final Evento evento;
  final DateTime ahora;
  final bool esAdmin;
  final void Function(Evento) alEditar;
  final VoidCallback alCambiar;

  /// Acción del admin: cierra el detalle, la ejecuta y recarga la agenda.
  Future<void> _accionAdmin(BuildContext context, Future<void> Function() accion, String hecho) async {
    final avisos = ScaffoldMessenger.of(context);
    Navigator.of(context).pop(); // cierra el detalle
    try {
      await accion();
      avisos.showSnackBar(SnackBar(content: Text(hecho)));
      alCambiar();
    } on ErrorVeraGo catch (e) {
      avisos.showSnackBar(SnackBar(content: Text(e.mensaje)));
    }
  }

  Future<void> _eliminar(BuildContext context) async {
    final seguro = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Eliminar evento?'),
        content: Text('"${evento.titulo}" se borrará para siempre. '
            'Si solo no se llevará a cabo, mejor márcalo como cancelado.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('No')),
          FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Eliminar')),
        ],
      ),
    );
    if (seguro == true && context.mounted) {
      await _accionAdmin(context, () => EventosService().eliminar(evento.id), 'Evento eliminado.');
    }
  }

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
            const SizedBox(height: 4),
            Text(
              'Costo: ${evento.textoCosto}${evento.esDemo && !evento.esGratuito ? ' (ficticio)' : ''}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            if (evento.descripcion != null) ...[
              const SizedBox(height: 12),
              Text(evento.descripcion!, style: const TextStyle(height: 1.4)),
            ],
            // Opciones solo para el admin.
            if (esAdmin) ...[
              const Divider(height: 28),
              const Text('Administrar', style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      alEditar(evento);
                    },
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Editar'),
                  ),
                  if (evento.estado != 'publicado')
                    OutlinedButton.icon(
                      onPressed: () => _accionAdmin(context,
                          () => EventosService().cambiarEstado(evento.id, 'publicado'), 'Evento publicado.'),
                      icon: const Icon(Icons.public),
                      label: const Text('Publicar'),
                    ),
                  if (!evento.borrador)
                    OutlinedButton.icon(
                      onPressed: () => _accionAdmin(context,
                          () => EventosService().cambiarEstado(evento.id, 'pendiente'), 'Evento pasado a borrador.'),
                      icon: const Icon(Icons.visibility_off_outlined),
                      label: const Text('Borrador'),
                    ),
                  if (!evento.cancelado)
                    OutlinedButton.icon(
                      onPressed: () => _accionAdmin(context,
                          () => EventosService().cambiarEstado(evento.id, 'cancelado'), 'Evento cancelado.'),
                      icon: const Icon(Icons.cancel_outlined),
                      label: const Text('Cancelar'),
                    ),
                  OutlinedButton.icon(
                    onPressed: () => _eliminar(context),
                    style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF9B2C2C)),
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Eliminar'),
                  ),
                ],
              ),
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
                        if (evento.borrador)
                          const Etiqueta('Borrador (solo admin)', color: Color(0xFF6B6B6B), icono: Icons.visibility_off_outlined),
                        if (evento.cancelado)
                          const Etiqueta('Cancelado', color: Color(0xFF9B2C2C), icono: Icons.cancel_outlined)
                        else if (evento.enCurso(ahora))
                          const Etiqueta('En curso', color: VgColores.verdePalma, icono: Icons.play_circle_outline),
                        // Siempre se indica el costo: "Gratuito", "≈ $150 MXN" o "Con costo".
                        Etiqueta(
                          evento.textoCosto,
                          color: evento.esGratuito ? VgColores.azulGolfo : VgColores.terracota,
                          icono: evento.esGratuito ? null : Icons.payments_outlined,
                        ),
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
