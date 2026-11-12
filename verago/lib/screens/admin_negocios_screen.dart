import 'package:flutter/material.dart';

import '../models/lugar.dart';
import '../services/admin_service.dart';
import '../services/error_verago.dart';
import '../services/geocodificacion_service.dart';
import '../theme/app_theme.dart';
import '../widgets/editor_horario.dart';
import '../widgets/estado_vacio.dart';
import '../widgets/mapa_lugares.dart';

/// SOLICITUDES DE NEGOCIOS (admin): pendientes, aprobados y otros.
class AdminNegociosScreen extends StatefulWidget {
  const AdminNegociosScreen({super.key});

  @override
  State<AdminNegociosScreen> createState() => _AdminNegociosScreenState();
}

class _AdminNegociosScreenState extends State<AdminNegociosScreen> {
  final _servicio = AdminService();
  late Future<List<Lugar>> _futuro;
  String _filtro = 'pendiente';

  /// Tipo de negocio: 'todos', 'formal' (local propio) o 'informal' (Punto VeraGo).
  String _tipo = 'todos';

  @override
  void initState() {
    super.initState();
    _futuro = _servicio.negocios();
  }

  void _recargar() => setState(() {
        _futuro = _servicio.negocios()..ignore();
      });

  bool _coincide(Lugar l) {
    final estado = switch (_filtro) {
      'pendiente' => l.estadoAprobacion == 'pendiente',
      'aprobado' => l.estadoAprobacion == 'aprobado',
      _ => l.estadoAprobacion == 'rechazado' || l.estadoAprobacion == 'suspendido',
    };
    final tipo = switch (_tipo) {
      'formal' => l.esFormal,
      'informal' => l.esInformal,
      _ => true,
    };
    return estado && tipo;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Negocios')),
      body: FutureBuilder<List<Lugar>>(
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
          final todos = snapshot.data!;
          final pendientes = todos.where((l) => l.estadoAprobacion == 'pendiente').length;
          final visibles = todos.where(_coincide).toList();
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: SegmentedButton<String>(
                  segments: [
                    ButtonSegment(value: 'pendiente', label: Text('Pendientes ($pendientes)')),
                    const ButtonSegment(value: 'aprobado', label: Text('Aprobados')),
                    const ButtonSegment(value: 'otros', label: Text('Otros')),
                  ],
                  selected: {_filtro},
                  onSelectionChanged: (s) => setState(() => _filtro = s.first),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Wrap(
                  spacing: 8,
                  children: [
                    for (final t in const {
                      'todos': 'Todos',
                      'formal': 'Formales',
                      'informal': 'No formales',
                    }.entries)
                      ChoiceChip(
                        label: Text(t.value),
                        selected: _tipo == t.key,
                        onSelected: (_) => setState(() => _tipo = t.key),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: visibles.isEmpty
                    ? const EstadoVacio(
                        icono: Icons.inbox_outlined,
                        titulo: 'Nada por aquí',
                        mensaje: 'No hay negocios en esta lista.',
                      )
                    : ListView(
                        padding: const EdgeInsets.only(bottom: 16),
                        children: [
                          for (final n in visibles)
                            Card(
                              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                              child: ListTile(
                                title: Text(n.nombre, style: const TextStyle(fontWeight: FontWeight.w700)),
                                subtitle: Text(
                                  '${n.esInformal ? 'No formal · Punto VeraGo · ${n.giroNombre ?? ''}' : 'Formal · Local propio · ${n.categoriaNombre}'}'
                                  '\nEstado: ${n.estadoAprobacion}',
                                ),
                                isThreeLine: true,
                                trailing: const Icon(Icons.chevron_right),
                                onTap: () async {
                                  final cambio = await Navigator.of(context).push<bool>(MaterialPageRoute(
                                    builder: (_) => AdminNegocioDetalleScreen(negocio: n),
                                  ));
                                  if (cambio == true) _recargar();
                                },
                              ),
                            ),
                        ],
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// DETALLE DE UNA SOLICITUD: datos, ubicación y acciones del admin.
///
/// Revisión de dirección (opción C): se muestra la dirección que escribió
/// el comerciante junto a la que da el mapa en ese punto, para comparar.
class AdminNegocioDetalleScreen extends StatefulWidget {
  const AdminNegocioDetalleScreen({super.key, required this.negocio});

  final Lugar negocio;

  @override
  State<AdminNegocioDetalleScreen> createState() => _AdminNegocioDetalleScreenState();
}

class _AdminNegocioDetalleScreenState extends State<AdminNegocioDetalleScreen> {
  final _servicio = AdminService();
  late final Future<String?> _direccionMapa;
  late final List<Horario?> _horario = EditorHorario.desde(widget.negocio);
  bool _trabajando = false;

  Lugar get n => widget.negocio;

  @override
  void initState() {
    super.initState();
    // Solo los formales eligieron su ubicación; los informales están en su punto.
    _direccionMapa = n.esFormal ? GeocodificacionService().direccionDe(n.punto) : Future.value(null);
  }

  Future<void> _ejecutar(Future<void> Function() accion, String hecho) async {
    setState(() => _trabajando = true);
    try {
      await accion();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(hecho)));
      Navigator.of(context).pop(true);
    } on ErrorVeraGo catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.mensaje)));
    } finally {
      if (mounted) setState(() => _trabajando = false);
    }
  }

  Future<void> _cambiarEstado(String estado, String hecho) =>
      _ejecutar(() => _servicio.cambiarEstadoNegocio(n.id, estado, formal: n.esFormal), hecho);

  Future<void> _guardarHorario() async {
    final error = EditorHorario.validar(_horario);
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    await _ejecutar(
      () => _servicio.guardarHorario(n.id, _horario.whereType<Horario>().toList()),
      'Horario guardado.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final estado = n.estadoAprobacion;
    return Scaffold(
      appBar: AppBar(title: const Text('Solicitud')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        children: [
          Text(n.nombre, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 4),
          Text(n.esInformal
              ? 'No formal · Punto VeraGo · Giro: ${n.giroNombre ?? '—'} (no da sellos)'
              : 'Formal · Local propio · ${n.categoriaNombre} (da sellos)'),
          Text('Estado: $estado', style: const TextStyle(fontWeight: FontWeight.w600)),
          const Divider(height: 28),
          _Dato('Encargado', n.duenoNombre ?? '—'),
          _Dato('Teléfono', n.telefono ?? '—'),
          _Dato('Descripción', n.descripcion ?? '—'),
          const SizedBox(height: 12),
          Text('Ubicación', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              height: 200,
              child: MapaLugares(lugares: [n], centro: n.punto, zoom: 17, interactivo: false),
            ),
          ),
          const SizedBox(height: 8),
          _Dato('Dirección escrita', n.direccion ?? '—'),
          if (n.esFormal)
            FutureBuilder<String?>(
              future: _direccionMapa,
              builder: (_, s) => _Dato(
                'Según el mapa',
                s.connectionState != ConnectionState.done
                    ? 'Buscando…'
                    : (s.data ?? 'No disponible (sin conexión con OpenStreetMap)'),
              ),
            ),
          if (n.esFormal)
            const Text('Revisa que ambas direcciones coincidan antes de aprobar.',
                style: TextStyle(fontSize: 12, color: VgColores.terracota)),
          const Divider(height: 28),
          Text('Horario', style: Theme.of(context).textTheme.titleLarge),
          EditorHorario(horario: _horario, alCambiar: () => setState(() {})),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(onPressed: _trabajando ? null : _guardarHorario, child: const Text('Guardar horario')),
          ),
          const Divider(height: 28),
          if (estado != 'aprobado')
            FilledButton.icon(
              onPressed: _trabajando ? null : () => _cambiarEstado('aprobado', 'Negocio aprobado.'),
              icon: const Icon(Icons.check),
              label: Text(estado == 'pendiente' ? 'Aprobar' : 'Reactivar (aprobar)'),
            ),
          if (estado == 'pendiente') ...[
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _trabajando ? null : () => _cambiarEstado('rechazado', 'Solicitud rechazada.'),
              icon: const Icon(Icons.close),
              label: const Text('Rechazar'),
            ),
          ],
          if (estado == 'aprobado')
            OutlinedButton.icon(
              onPressed: _trabajando ? null : () => _cambiarEstado('suspendido', 'Negocio suspendido.'),
              icon: const Icon(Icons.pause),
              label: const Text('Suspender'),
            ),
          const SizedBox(height: 8),
          const Text(
            'Aprobar = aparece en la app (y da sellos solo si es formal). Recuerda avisar al comerciante '
            '(por teléfono o correo): la app no envía notificaciones.',
            style: TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _Dato extends StatelessWidget {
  const _Dato(this.etiqueta, this.valor);
  final String etiqueta;
  final String valor;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 130,
              child: Text(etiqueta, style: TextStyle(color: Colors.black.withValues(alpha: 0.6))),
            ),
            Expanded(child: Text(valor)),
          ],
        ),
      );
}
