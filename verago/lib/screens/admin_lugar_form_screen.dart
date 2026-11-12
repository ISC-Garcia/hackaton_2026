import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../models/lugar.dart';
import '../services/admin_service.dart';
import '../services/error_verago.dart';
import '../services/geocodificacion_service.dart';
import '../services/validaciones.dart';
import '../widgets/editor_costo_entrada.dart';
import '../widgets/editor_horario.dart';
import '../widgets/estado_vacio.dart';
import '../widgets/selector_ubicacion.dart';

/// FORMULARIO DE LUGAR o PUNTO VERAGO (admin): crear o editar.
///
/// Igual que en el registro de negocios, la dirección se llena sola al
/// tocar el mapa, para que coincidan.
class AdminLugarFormScreen extends StatefulWidget {
  const AdminLugarFormScreen({super.key, this.lugar});

  /// null = lugar nuevo.
  final Lugar? lugar;

  @override
  State<AdminLugarFormScreen> createState() => _AdminLugarFormScreenState();
}

class _AdminLugarFormScreenState extends State<AdminLugarFormScreen> {
  final _servicio = AdminService();
  final _formulario = GlobalKey<FormState>();
  late final _nombre = TextEditingController(text: widget.lugar?.nombre ?? '');
  late final _descripcion = TextEditingController(text: widget.lugar?.descripcion ?? '');
  late final _direccion = TextEditingController(text: widget.lugar?.direccion ?? '');
  late final List<Horario?> _horario = EditorHorario.desde(widget.lugar);
  late final Future<Map<int, String>> _categorias;

  late bool _esPunto = widget.lugar?.esPunto ?? false;
  late int? _categoriaId = widget.lugar?.categoriaId;
  late LatLng? _ubicacion = widget.lugar?.punto;
  late int _interes = widget.lugar?.interes ?? 3;
  late int _duracion = widget.lugar?.duracionVisitaMin ?? 30;
  late bool _aPie = widget.lugar?.enRecorridoAPie ?? true;
  late bool _publicado = widget.lugar?.publicado ?? true;
  late int? _costo = widget.lugar?.costoEntradaMxn;
  bool _faltaUbicacion = false;
  bool _guardando = false;

  static const _duraciones = [15, 20, 30, 45, 60, 90, 120];

  @override
  void initState() {
    super.initState();
    _categorias = _servicio.categorias();
    if (!_duraciones.contains(_duracion)) _duracion = 30;
  }

  @override
  void dispose() {
    _nombre.dispose();
    _descripcion.dispose();
    _direccion.dispose();
    super.dispose();
  }

  Future<void> _alTocarMapa(LatLng punto) async {
    setState(() {
      _ubicacion = punto;
      _faltaUbicacion = false;
    });
    final direccion = await GeocodificacionService().direccionDe(punto);
    if (mounted && direccion != null && _ubicacion == punto) {
      setState(() => _direccion.text = direccion);
    }
  }

  Future<void> _guardar() async {
    final ok = _formulario.currentState!.validate();
    setState(() => _faltaUbicacion = _ubicacion == null);
    if (!ok || _faltaUbicacion) return;
    final errorHorario = EditorHorario.validar(_horario);
    if (errorHorario != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorHorario)));
      return;
    }
    setState(() => _guardando = true);
    try {
      await _servicio.guardarLugar(
        id: widget.lugar?.id,
        datos: DatosLugar(
          nombre: _nombre.text,
          descripcion: _descripcion.text,
          categoriaId: _categoriaId ?? 8,
          latitud: _ubicacion!.latitude,
          longitud: _ubicacion!.longitude,
          direccion: _direccion.text,
          interes: _interes,
          duracionVisitaMin: _duracion,
          esPunto: _esPunto,
          enRecorridoAPie: _aPie,
          publicado: _publicado,
          costoEntradaMxn: _costo,
        ),
        horario: _horario.whereType<Horario>().toList(),
      );
      if (mounted) Navigator.of(context).pop(true);
    } on ErrorVeraGo catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.mensaje)));
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.lugar == null ? 'Nuevo lugar' : 'Editar lugar')),
      body: FutureBuilder<Map<int, String>>(
        future: _categorias,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return EstadoVacio(icono: Icons.wifi_off, titulo: 'Algo salió mal', mensaje: '${snapshot.error}');
          }
          // Los comercios se registran con "Soy un negocio"; aquí solo
          // categorías de lugares públicos (sin Puntos, que van con el interruptor).
          final categorias = {
            for (final c in snapshot.data!.entries)
              if (c.key != 8) c.key: c.value,
          };
          if (_categoriaId != null && !categorias.containsKey(_categoriaId)) _categoriaId = null;
          return _formularioLugar(categorias);
        },
      ),
    );
  }

  Widget _formularioLugar(Map<int, String> categorias) {
    return Form(
      key: _formulario,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Es un Punto VeraGo'),
            subtitle: const Text('Espacio donde VeraGo renta mesas a emprendedores (un negocio por giro).'),
            value: _esPunto,
            onChanged: (v) => setState(() => _esPunto = v),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _nombre,
            decoration: const InputDecoration(labelText: 'Nombre', border: OutlineInputBorder()),
            validator: Validaciones.obligatorio('el nombre'),
          ),
          const SizedBox(height: 12),
          if (!_esPunto) ...[
            DropdownButtonFormField<int>(
              initialValue: _categoriaId,
              decoration: const InputDecoration(labelText: 'Categoría', border: OutlineInputBorder()),
              items: [
                for (final c in categorias.entries) DropdownMenuItem(value: c.key, child: Text(c.value)),
              ],
              onChanged: (v) => setState(() => _categoriaId = v),
              validator: (v) => v == null ? 'Elige una categoría' : null,
            ),
            const SizedBox(height: 12),
          ],
          TextFormField(
            controller: _descripcion,
            maxLines: 3,
            maxLength: 300,
            decoration: const InputDecoration(labelText: 'Descripción', border: OutlineInputBorder()),
          ),
          const Text('Ubicación (toca el mapa):', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          SelectorUbicacion(valor: _ubicacion, alCambiar: _alTocarMapa),
          if (_faltaUbicacion)
            const Padding(
              padding: EdgeInsets.only(top: 6),
              child: Text('Marca la ubicación en el mapa', style: TextStyle(color: Color(0xFF9B2C2C))),
            ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _direccion,
            decoration: const InputDecoration(
              labelText: 'Dirección',
              helperText: 'Se llena sola al tocar el mapa; puedes ajustarla.',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          Text('Interés para las rutas: $_interes de 5', style: const TextStyle(fontWeight: FontWeight.w600)),
          Slider(
            value: _interes.toDouble(),
            min: 1,
            max: 5,
            divisions: 4,
            label: '$_interes',
            onChanged: (v) => setState(() => _interes = v.round()),
          ),
          DropdownButtonFormField<int>(
            initialValue: _duracion,
            decoration: const InputDecoration(labelText: 'Visita sugerida', border: OutlineInputBorder()),
            items: [for (final m in _duraciones) DropdownMenuItem(value: m, child: Text('$m min'))],
            onChanged: (v) => setState(() => _duracion = v ?? 30),
          ),
          if (!_esPunto) ...[
            const SizedBox(height: 12),
            EditorCostoEntrada(inicial: _costo, paraNegocio: false, alCambiar: (v) => _costo = v),
          ],
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Se llega caminando desde el centro'),
            subtitle: const Text('Si no (ej. San Juan de Ulúa), las rutas a pie lo omiten.'),
            value: _aPie,
            onChanged: (v) => setState(() => _aPie = v),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Publicado'),
            subtitle: const Text('Si lo apagas, el lugar se oculta de la app (no se borra).'),
            value: _publicado,
            onChanged: (v) => setState(() => _publicado = v),
          ),
          const SizedBox(height: 8),
          Text('Horario', style: Theme.of(context).textTheme.titleLarge),
          const Text('Déjalo todo en "Cerrado" si no hay horario confirmado (no inventamos horarios).',
              style: TextStyle(fontSize: 12)),
          EditorHorario(horario: _horario, alCambiar: () => setState(() {})),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _guardando ? null : _guardar,
            child: Text(_guardando ? 'Guardando…' : 'Guardar'),
          ),
        ],
      ),
    );
  }
}
