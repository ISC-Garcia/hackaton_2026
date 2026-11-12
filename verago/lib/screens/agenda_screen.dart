import 'dart:async';

import 'package:flutter/material.dart';

import '../i18n/idioma.dart';
import '../models/evento.dart';
import '../models/grupo_eventos.dart';
import '../services/auth_service.dart';
import '../services/error_verago.dart';
import '../services/eventos_service.dart';
import '../services/pasaporte_service.dart';
import '../services/traductor_service.dart';
import '../theme/app_theme.dart';
import '../widgets/estado_vacio.dart';
import '../widgets/etiqueta.dart';
import 'evento_form_screen.dart';

/// AGENDA: eventos culturales del centro.
///
/// - "Próximos" se puede ordenar de más pronto a más lejano (o al revés) y
///   lleva un encabezado por día.
/// - El MISMO evento varias veces el mismo día se junta en una tarjeta, con
///   las horas a la derecha (o "Cada 2 h" si van parejas). Ver GrupoEventos.
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

  /// Orden de "Próximos": false = más pronto primero (por defecto).
  bool _masLejanoPrimero = false;

  /// "sábado 14 de noviembre" (en el idioma de la app).
  String _nombreDia(DateTime d) => Idioma.fechaLarga(d);

  /// IDIOMA: títulos y descripciones traducidos con Gemini (vacío en español).
  Map<String, String> _traducido = const {};
  String _t(String original) => _traducido[original] ?? original;

  Future<List<Evento>> _cargar() async {
    final eventos = await _servicio.obtenerProximos();
    if (!Idioma.esEspanol && eventos.isNotEmpty) {
      // Una sola llamada para todos los textos; mientras llega se ve el español.
      TraductorService().traducir([
        for (final e in eventos) ...[e.titulo, ?e.descripcion],
      ]).then((r) {
        if (mounted) setState(() => _traducido = r);
      });
    }
    return eventos;
  }

  /// Tarjetas de la lista, con un encabezado cada vez que cambia el día
  /// (solo en "Próximos": en "Hoy" todo es del mismo día).
  List<Widget> _filas(List<Evento> visibles, DateTime ahora) {
    final grupos = GrupoEventos.agrupar(visibles, masLejanoPrimero: !_verHoy && _masLejanoPrimero);
    final filas = <Widget>[];
    DateTime? diaAnterior;
    for (final g in grupos) {
      if (!_verHoy && g.dia != diaAnterior) {
        filas.add(Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 2),
          child: Text(
            _nombreDia(g.dia),
            style: const TextStyle(fontWeight: FontWeight.w700, color: VgColores.azulGolfo),
          ),
        ));
        diaAnterior = g.dia;
      }
      filas.add(_TarjetaEvento(
        evento: g.primero,
        grupo: g,
        ahora: ahora,
        esAdmin: _esAdmin,
        alEditar: _abrirFormulario,
        alCambiar: _recargar,
        traducir: _t,
      ));
    }
    return filas;
  }
  bool _esAdmin = false;
  StreamSubscription<dynamic>? _suscripcion;

  @override
  void initState() {
    super.initState();
    _futuro = _cargar();
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
        _futuro = _cargar()..ignore();
      });

  bool _esHoy(Evento e, DateTime ahora) =>
      e.enCurso(ahora) ||
      (e.inicia.year == ahora.year && e.inicia.month == ahora.month && e.inicia.day == ahora.day);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tr('Agenda')),
        actions: [
          // Sin eventos no hay lista que jalar para recargar: por eso el botón.
          IconButton(tooltip: tr('Actualizar'), icon: const Icon(Icons.refresh), onPressed: _recargar),
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
              titulo: tr('Algo salió mal'),
              mensaje: tr(snapshot.error.toString()),
              textoBoton: tr('Reintentar'),
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
                    ButtonSegment(value: true, label: Text(tr('Hoy ({n})', {'n': hoy.length}))),
                    ButtonSegment(value: false, label: Text(tr('Próximos ({n})', {'n': proximos.length}))),
                  ],
                  selected: {_verHoy},
                  onSelectionChanged: (s) => setState(() => _verHoy = s.first),
                ),
              ),
              // Ordenar "Próximos".
              if (!_verHoy && proximos.isNotEmpty)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: TextButton.icon(
                      onPressed: () => setState(() => _masLejanoPrimero = !_masLejanoPrimero),
                      icon: const Icon(Icons.swap_vert),
                      label: Text(_masLejanoPrimero ? tr('Más lejano primero') : tr('Más pronto primero')),
                    ),
                  ),
                ),
              Expanded(
                child: visibles.isEmpty
                    ? EstadoVacio(
                        icono: Icons.event_busy,
                        titulo: _verHoy ? tr('No hay eventos hoy') : tr('No hay eventos próximos'),
                        mensaje: _verHoy
                            ? tr('Revisa los próximos días.')
                            : tr('Vuelve pronto: aquí aparecerán nuevos eventos.'),
                        textoBoton: _verHoy ? tr('Ver próximos') : null,
                        alPresionar: _verHoy ? () => setState(() => _verHoy = false) : null,
                      )
                    : RefreshIndicator(
                        onRefresh: () async {
                          _recargar();
                          await _futuro;
                        },
                        child: ListView(
                          padding: const EdgeInsets.only(bottom: 88), // espacio para "Nuevo evento"
                          children: _filas(visibles, ahora),
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
    this.grupo,
    required this.ahora,
    required this.esAdmin,
    required this.alEditar,
    required this.alCambiar,
    required this.traducir,
  });

  /// Texto traducido (título/descripción) o el original.
  final String Function(String) traducir;

  final Evento evento;

  /// Si el mismo evento se repite ese día: todas sus horas (null = uno solo).
  final GrupoEventos? grupo;
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

  /// Mes corto en el idioma de la app ("nov", "Nov", ...).
  static String _mesCorto(int mes) => Idioma.mes(mes).substring(0, 3);

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
            Text(traducir(evento.titulo), style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text('${evento.inicia.day} ${_mesCorto(evento.inicia.month)} · '
                '${_hora(evento.inicia)} – ${_hora(evento.termina)}'),
            if (evento.lugarNombre != null) Text(evento.lugarNombre!),
            const SizedBox(height: 4),
            Text(
              tr('Costo: {costo}', {'costo': tr(evento.textoCosto)}) +
                  (evento.esDemo && !evento.esGratuito ? tr(' (ficticio)') : ''),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            if (evento.descripcion != null) ...[
              const SizedBox(height: 12),
              Text(traducir(evento.descripcion!), style: const TextStyle(height: 1.4)),
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

  /// Evento repetido: primero se elige la hora y luego se abre su detalle
  /// (cada hora se puede editar o cancelar por separado).
  void _elegirHora(BuildContext context, GrupoEventos g) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (hoja) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: Text(traducir(evento.titulo), style: Theme.of(hoja).textTheme.titleLarge),
            ),
            for (final e in g.eventos)
              ListTile(
                leading: const Icon(Icons.schedule),
                title: Text('${_hora(e.inicia)} – ${_hora(e.termina)}',
                    style: TextStyle(decoration: e.cancelado ? TextDecoration.lineThrough : null)),
                subtitle: e.cancelado ? Text(tr('Cancelado')) : (e.borrador ? const Text('Borrador') : null),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.of(hoja).pop();
                  _TarjetaEvento(
                    evento: e,
                    ahora: ahora,
                    esAdmin: esAdmin,
                    alEditar: alEditar,
                    alCambiar: alCambiar,
                    traducir: traducir,
                  )._verDetalle(context);
                },
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final g = grupo;
    final varios = g != null && g.esVarios;
    // Tachado solo si TODAS las horas están canceladas.
    final todosCancelados = varios ? g.eventos.every((e) => e.cancelado) : evento.cancelado;
    final tachado = todosCancelados ? TextDecoration.lineThrough : null;
    final horario = (g ?? GrupoEventos([evento])).textoHorario;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => varios ? _elegirHora(context, g) : _verDetalle(context),
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
                      _mesCorto(evento.inicia.month),
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
                      traducir(evento.titulo),
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, decoration: tachado),
                    ),
                    if (evento.lugarNombre != null) ...[
                      const SizedBox(height: 2),
                      Text(evento.lugarNombre!, style: TextStyle(color: Colors.black.withValues(alpha: 0.65))),
                    ],
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        if (evento.borrador)
                          const Etiqueta('Borrador (solo admin)', color: Color(0xFF6B6B6B), icono: Icons.visibility_off_outlined),
                        if (todosCancelados)
                          const Etiqueta('Cancelado', color: Color(0xFF9B2C2C), icono: Icons.cancel_outlined)
                        else if (varios && g.eventos.any((e) => e.cancelado))
                          const Etiqueta('Alguna hora cancelada', color: Color(0xFF9B2C2C), icono: Icons.cancel_outlined)
                        else if ((varios ? g.eventos : [evento]).any((e) => e.enCurso(ahora)))
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
              // Horario a la derecha: una hora, varias horas o "Cada 2 h".
              const SizedBox(width: 10),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 104),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (varios) const Icon(Icons.repeat, size: 16, color: VgColores.terracota),
                    Text(
                      horario.principal,
                      textAlign: TextAlign.right,
                      style: TextStyle(fontWeight: FontWeight.w700, decoration: tachado, height: 1.3),
                    ),
                    if (horario.detalle != null)
                      Text(horario.detalle!,
                          textAlign: TextAlign.right,
                          style: TextStyle(fontSize: 12, color: Colors.black.withValues(alpha: 0.6))),
                    if (varios)
                      Text(tr('{n} horarios', {'n': g.eventos.length}),
                          style: TextStyle(fontSize: 12, color: Colors.black.withValues(alpha: 0.6))),
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
