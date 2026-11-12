import 'package:flutter/material.dart';

import '../i18n/idioma.dart';
import '../models/lugar.dart';
import '../services/admin_service.dart';
import '../services/error_verago.dart';
import '../services/geocodificacion_service.dart';
import '../theme/app_theme.dart';
import '../widgets/editor_costo_entrada.dart';
import '../widgets/editor_horario.dart';
import '../widgets/eliminar_lugar.dart';
import '../widgets/estado_vacio.dart';
import '../widgets/foto_lugar.dart';
import '../widgets/mapa_lugares.dart';
import '../widgets/selector_ubicacion.dart';

/// SOLICITUDES DE NEGOCIOS (admin): pendientes, cambios de ubicación,
/// aprobados y otros.
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
      'cambio' => l.tieneCambioPendiente,
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
      appBar: AppBar(title: Text(tr('Negocios'))),
      body: FutureBuilder<List<Lugar>>(
        future: _futuro,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return EstadoVacio(
              icono: Icons.wifi_off,
              titulo: tr('Algo salió mal'),
              mensaje: snapshot.error.toString(),
              textoBoton: tr('Reintentar'),
              alPresionar: _recargar,
            );
          }
          final todos = snapshot.data!;
          final pendientes = todos.where((l) => l.estadoAprobacion == 'pendiente').length;
          final cambios = todos.where((l) => l.tieneCambioPendiente).length;
          final visibles = todos.where(_coincide).toList();
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                // Chips en vez de botones segmentados: con 4 opciones caben
                // mejor en pantallas angostas (bajan de renglón si no caben).
                child: Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    for (final f in {
                      'pendiente': tr('Pendientes ({pendientes})', {'pendientes': pendientes}),
                      'cambio': tr('Cambios de ubicación ({cambios})', {'cambios': cambios}),
                      'aprobado': tr('Aprobados'),
                      'otros': tr('Rechazados y suspendidos'),
                    }.entries)
                      ChoiceChip(
                        label: Text(f.value),
                        selected: _filtro == f.key,
                        onSelected: (_) => setState(() => _filtro = f.key),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Wrap(
                  spacing: 8,
                  children: [
                    for (final t in {
                      'todos': tr('Todos'),
                      'formal': tr('Formales'),
                      'informal': tr('No formales'),
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
                    ? EstadoVacio(
                        icono: Icons.inbox_outlined,
                        titulo: tr('Nada por aquí'),
                        mensaje: tr('No hay negocios en esta lista.'),
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
                                  '${n.esInformal ? tr('No formal · Punto VeraGo · {giro}', {'giro': tr(n.giroNombre ?? '')}) : tr('Formal · Local propio · {categoria}', {'categoria': tr(n.categoriaNombre)})}'
                                  '\n${tr('Estado: {estado}', {'estado': tr(n.estadoAprobacion)})}'
                                  '${n.tieneCambioPendiente ? tr(' · cambio de ubicación pendiente') : ''}',
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
  late final Future<String?> _direccionNueva;
  late final List<Horario?> _horario = EditorHorario.desde(widget.negocio);
  bool _trabajando = false;
  late int? _costo = widget.negocio.costoEntradaMxn;
  final _formCosto = GlobalKey<FormState>();

  Lugar get n => widget.negocio;

  @override
  void initState() {
    super.initState();
    // Solo los formales eligieron su ubicación; los informales están en su punto.
    _direccionMapa = n.esFormal ? GeocodificacionService().direccionDe(n.punto) : Future.value(null);
    final nuevo = n.puntoSolicitado;
    _direccionNueva =
        n.esFormal && nuevo != null ? GeocodificacionService().direccionDe(nuevo) : Future.value(null);
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

  Future<void> _guardarCosto() async {
    if (!_formCosto.currentState!.validate()) return;
    await _ejecutar(() => _servicio.guardarCostoEntrada(n.id, _costo), tr('Costo de entrada guardado.'));
  }

  Future<void> _resolverCambio({required bool aceptar}) => _ejecutar(
        () => _servicio.resolverCambioUbicacion(n.id, aceptar: aceptar),
        aceptar ? tr('Cambio de ubicación aceptado.') : tr('Cambio de ubicación rechazado.'),
      );

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
      tr('Horario guardado.'),
    );
  }

  @override
  Widget build(BuildContext context) {
    final estado = n.estadoAprobacion;
    return Scaffold(
      appBar: AppBar(title: Text(tr('Solicitud'))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        children: [
          Text(n.nombre, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 4),
          Text(n.esInformal
              ? tr('No formal · Punto VeraGo · Giro: {giro} (no da sellos)', {'giro': tr(n.giroNombre ?? '—')})
              : tr('Formal · Local propio · {categoriaNombre} (da sellos)', {'categoriaNombre': tr(n.categoriaNombre)})),
          Text(tr('Estado: {estado}', {'estado': tr(estado)}), style: const TextStyle(fontWeight: FontWeight.w600)),
          const Divider(height: 28),
          // El admin puede poner, cambiar o quitar la foto (ej. si no corresponde).
          EditorFoto(lugar: n, alGuardar: (url) => _servicio.guardarFoto(n.id, url)),
          const SizedBox(height: 16),
          _Dato(tr('Encargado'), n.duenoNombre ?? '—'),
          _Dato(tr('Teléfono'), n.telefono ?? '—'),
          _Dato(tr('Descripción'), n.descripcion ?? '—'),
          const SizedBox(height: 12),
          Text(tr('Ubicación'), style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              height: 200,
              child: MapaLugares(lugares: [n], centro: n.punto, zoom: 17, interactivo: false),
            ),
          ),
          const SizedBox(height: 8),
          _Dato(tr('Dirección escrita'), n.direccion ?? '—'),
          if (n.esFormal)
            FutureBuilder<String?>(
              future: _direccionMapa,
              builder: (_, s) => _Dato(
                tr('Según el mapa'),
                s.connectionState != ConnectionState.done
                    ? tr('Buscando…')
                    : (s.data ?? tr('No disponible (sin conexión con OpenStreetMap)')),
              ),
            ),
          if (n.esFormal)
            Text(tr('Revisa que ambas direcciones coincidan antes de aprobar.'),
                style: TextStyle(fontSize: 12, color: VgColores.terracota)),
          if (n.puntoSolicitado case final nuevo?) ...[
            const Divider(height: 28),
            Text(tr('Cambio de ubicación solicitado'), style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(tr('Mientras no lo aceptes, el negocio sigue en su ubicación actual (mapa de arriba).'),
                style: TextStyle(fontSize: 12)),
            const SizedBox(height: 8),
            SelectorUbicacion(valor: nuevo, alCambiar: (_) {}),
            const SizedBox(height: 8),
            _Dato(n.esInformal ? tr('Nuevo Punto VeraGo') : tr('Nueva dirección escrita'), n.cambioDireccion ?? '—'),
            if (n.esFormal)
              FutureBuilder<String?>(
                future: _direccionNueva,
                builder: (_, s) => _Dato(
                  tr('Según el mapa'),
                  s.connectionState != ConnectionState.done
                      ? tr('Buscando…')
                      : (s.data ?? tr('No disponible (sin conexión con OpenStreetMap)')),
                ),
              ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _trabajando ? null : () => _resolverCambio(aceptar: false),
                    child: Text(tr('Rechazar cambio')),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton(
                    onPressed: _trabajando ? null : () => _resolverCambio(aceptar: true),
                    child: Text(tr('Aceptar cambio')),
                  ),
                ),
              ],
            ),
            if (n.esInformal)
              Padding(
                padding: EdgeInsets.only(top: 6),
                child: Text(tr('Al aceptar, el negocio toma el horario del punto nuevo.'), style: TextStyle(fontSize: 12)),
              ),
          ],
          if (n.esFormal) ...[
            const Divider(height: 28),
            Form(
              key: _formCosto,
              child: EditorCostoEntrada(inicial: _costo, paraNegocio: true, alCambiar: (v) => _costo = v),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(onPressed: _trabajando ? null : _guardarCosto, child: Text(tr('Guardar costo'))),
            ),
          ],
          const Divider(height: 28),
          Text(tr('Horario'), style: Theme.of(context).textTheme.titleLarge),
          EditorHorario(horario: _horario, alCambiar: () => setState(() {})),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(onPressed: _trabajando ? null : _guardarHorario, child: Text(tr('Guardar horario'))),
          ),
          const Divider(height: 28),
          if (estado != 'aprobado')
            FilledButton.icon(
              onPressed: _trabajando ? null : () => _cambiarEstado('aprobado', tr('Negocio aprobado.')),
              icon: const Icon(Icons.check),
              label: Text(estado == 'pendiente' ? tr('Aprobar') : tr('Reactivar (aprobar)')),
            ),
          if (estado == 'pendiente') ...[
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _trabajando ? null : () => _cambiarEstado('rechazado', tr('Solicitud rechazada.')),
              icon: const Icon(Icons.close),
              label: Text(tr('Rechazar')),
            ),
          ],
          if (estado == 'aprobado')
            OutlinedButton.icon(
              onPressed: _trabajando ? null : () => _cambiarEstado('suspendido', tr('Negocio suspendido.')),
              icon: const Icon(Icons.pause),
              label: Text(tr('Suspender')),
            ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: _trabajando
                ? null
                : () async {
                    final listo = await EliminarLugar.ejecutar(
                      context,
                      n,
                      // Si tiene sellos no se borra: se suspende (deja de verse).
                      ocultar: () => _servicio.cambiarEstadoNegocio(n.id, 'suspendido', formal: n.esFormal),
                    );
                    if (listo && context.mounted) Navigator.of(context).pop(true);
                  },
            style: TextButton.styleFrom(foregroundColor: const Color(0xFF9B2C2C)),
            icon: const Icon(Icons.delete_outline),
            label: Text(tr('Eliminar negocio')),
          ),
          const SizedBox(height: 8),
          Text(
            tr('Aprobar = aparece en la app (y da sellos solo si es formal). Recuerda avisar al comerciante (por teléfono o correo): la app no envía notificaciones.'),
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
