import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../i18n/idioma.dart';
import '../models/lugar.dart';
import '../services/error_verago.dart';
import '../services/geocodificacion_service.dart';
import '../services/negocios_service.dart';
import '../widgets/direccion_del_mapa.dart';
import '../widgets/estado_vacio.dart';
import '../widgets/selector_ubicacion.dart';

/// PEDIR CAMBIO DE UBICACIÓN (comerciante).
///
/// - Formal: toca el mapa en la nueva ubicación; la dirección se llena sola.
/// - No formal: elige otro Punto VeraGo donde su giro esté libre.
///
/// No mueve el negocio: solo envía la SOLICITUD. El admin la acepta o la
/// rechaza; mientras tanto, el negocio sigue en su ubicación actual.
class CambiarUbicacionScreen extends StatefulWidget {
  const CambiarUbicacionScreen({super.key, required this.negocio});

  final Lugar negocio;

  @override
  State<CambiarUbicacionScreen> createState() => _CambiarUbicacionScreenState();
}

class _CambiarUbicacionScreenState extends State<CambiarUbicacionScreen> {
  final _servicio = NegociosService();
  final _formulario = GlobalKey<FormState>();
  final _direccion = TextEditingController();
  late final Future<List<Lugar>> _puntos;

  LatLng? _ubicacion;
  String? _puntoId;
  bool? _giroLibre; // null = aún no se revisa
  bool _buscandoDireccion = false;
  bool _enviando = false;

  Lugar get n => widget.negocio;

  @override
  void initState() {
    super.initState();
    _puntos = n.esInformal ? _servicio.obtenerPuntos() : Future.value(const <Lugar>[]);
  }

  @override
  void dispose() {
    _direccion.dispose();
    super.dispose();
  }

  Future<void> _alTocarMapa(LatLng punto) async {
    setState(() {
      _ubicacion = punto;
      _buscandoDireccion = true;
      _direccion.clear(); // la anterior ya no corresponde al punto nuevo
    });
    final direccion = await GeocodificacionService().direccionDe(punto);
    if (!mounted || _ubicacion != punto) return;
    setState(() {
      _buscandoDireccion = false;
      if (direccion != null) _direccion.text = direccion;
    });
  }

  Future<void> _elegirPunto(String? id) async {
    setState(() {
      _puntoId = id;
      _giroLibre = null;
    });
    if (id == null) return;
    try {
      final ocupados = await _servicio.girosOcupados(id);
      if (mounted && _puntoId == id) setState(() => _giroLibre = !ocupados.contains(n.giroId));
    } on ErrorVeraGo catch (e) {
      _mensaje(e.mensaje);
    }
  }

  Future<void> _enviar() async {
    if (!_formulario.currentState!.validate()) {
      _mensaje(tr('Faltan datos importantes: revisa lo marcado en rojo.'));
      return;
    }
    if (n.esFormal && _ubicacion == null) {
      _mensaje(tr('Toca el mapa en la nueva ubicación de tu local.'));
      return;
    }
    setState(() => _enviando = true);
    try {
      if (n.esFormal) {
        await _servicio.solicitarCambioUbicacion(punto: _ubicacion, direccion: _direccion.text);
      } else {
        await _servicio.solicitarCambioUbicacion(puntoId: _puntoId);
      }
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          icon: const Icon(Icons.schedule, size: 40),
          title: Text(tr('Solicitud enviada')),
          content: Text(
            tr('El equipo de VeraGo revisará tu nueva ubicación. Mientras tanto, los turistas te siguen viendo en tu ubicación actual.'),
          ),
          actions: [FilledButton(onPressed: () => Navigator.of(ctx).pop(), child: Text(tr('Entendido')))],
        ),
      );
      if (mounted) Navigator.of(context).pop(true);
    } on ErrorVeraGo catch (e) {
      _mensaje(e.mensaje);
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  void _mensaje(String t) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(n.esFormal ? tr('Cambiar ubicación') : tr('Cambiar de Punto VeraGo'))),
      body: FutureBuilder<List<Lugar>>(
        future: _puntos,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return EstadoVacio(icono: Icons.wifi_off, titulo: tr('Algo salió mal'), mensaje: '${snapshot.error}');
          }
          final otrosPuntos = snapshot.data!.where((p) => p.id != n.puntoId).toList();
          return Form(
            key: _formulario,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
              children: [
                Text(tr('Ubicación actual'), style: Theme.of(context).textTheme.titleMedium),
                Text(n.direccion ?? '—'),
                const SizedBox(height: 16),
                if (n.esFormal) ..._formal() else ..._noFormal(otrosPuntos),
                const SizedBox(height: 8),
                Text(
                  tr('El cambio no es inmediato: VeraGo debe aceptarlo. Mientras tanto, tu negocio sigue en su ubicación actual.'),
                  style: TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: _enviando || (!n.esFormal && _giroLibre != true) ? null : _enviar,
                  child: Text(_enviando ? tr('Enviando…') : tr('Enviar solicitud')),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  List<Widget> _formal() => [
        Text(tr('1. Toca el mapa en la nueva ubicación de tu local:'),
            style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        SelectorUbicacion(valor: _ubicacion, alCambiar: _alTocarMapa),
        const SizedBox(height: 12),
        Text(tr('2. Revisa la nueva dirección:'), style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        // Solo texto: la ubicación se elige únicamente en el mapa.
        DireccionDelMapa(
          titulo: tr('Nueva dirección (según el mapa)'),
          direccion: _direccion.text,
          hayPunto: _ubicacion != null,
          buscando: _buscandoDireccion,
          alReintentar: _ubicacion == null ? null : () => _alTocarMapa(_ubicacion!),
        ),
      ];

  List<Widget> _noFormal(List<Lugar> puntos) {
    if (puntos.isEmpty) {
      return [Text(tr('Por ahora no hay otro Punto VeraGo disponible.'))];
    }
    return [
      DropdownButtonFormField<String>(
        initialValue: _puntoId,
        decoration: InputDecoration(labelText: tr('Nuevo Punto VeraGo'), border: OutlineInputBorder()),
        items: [for (final p in puntos) DropdownMenuItem(value: p.id, child: Text(p.nombre))],
        onChanged: _elegirPunto,
        validator: (v) => v == null ? tr('Elige un punto') : null,
      ),
      const SizedBox(height: 8),
      if (_giroLibre == false)
        Text(tr('Tu giro ({giro}) ya está ocupado en ese punto. Elige otro.', {'giro': tr(n.giroNombre ?? '')}),
            style: const TextStyle(color: Color(0xFF9B2C2C)))
      else if (_giroLibre == true)
        Text(tr('Tu giro ({giro}) está libre en ese punto.', {'giro': tr(n.giroNombre ?? '')})),
    ];
  }
}
