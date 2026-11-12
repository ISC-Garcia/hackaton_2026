import 'package:flutter/material.dart';

import '../i18n/idioma.dart';
import '../models/lugar.dart';
import '../services/distancia.dart';
import '../services/error_verago.dart';
import '../services/lugares_service.dart';
import '../services/preferencias_service.dart';
import '../services/rutas_service.dart';
import '../services/ubicacion_service.dart';
import '../widgets/categoria_estilo.dart';
import '../widgets/estado_vacio.dart';
import 'ruta_screen.dart';

/// RUTAS: formulario corto para pedir un recorrido.
///
/// El visitante elige: tiempo disponible, intereses (OBLIGATORIO al menos
/// uno), ritmo y punto de partida. Al tocar "Generar ruta", `RutasService`
/// arma el recorrido y se abre `RutaScreen` con el resultado.
class RutasScreen extends StatefulWidget {
  const RutasScreen({super.key});

  /// Categorías que pueden ser parada de una ruta (ordenadas por nombre).
  /// No incluye "Puntos VeraGo" (siempre entra uno) ni los negocios de un
  /// punto (no son paradas sueltas), ni lugares a los que no se llega a pie.
  static Map<String, String> categoriasDeRuta(List<Lugar> lugares) {
    final categorias = <String, String>{
      for (final l in lugares)
        // Los Puntos VeraGo sí se pueden elegir; los negocios de un punto no
        // (no son paradas sueltas: la parada es su punto).
        if (l.enRecorridoAPie && !l.esInformal) l.categoriaClave: l.categoriaNombre,
    };
    final claves = categorias.keys.toList()
      ..sort((a, b) => categorias[a]!.compareTo(categorias[b]!));
    return {for (final c in claves) c: categorias[c]!};
  }

  @override
  State<RutasScreen> createState() => _RutasScreenState();
}

class _RutasScreenState extends State<RutasScreen> {
  final _lugaresService = LugaresService();
  final _prefs = PreferenciasService();
  late Future<List<Lugar>> _futuro;

  /// Hasta 5 h: lo que un visitante de crucero pasa en tierra (reto del hackatón).
  static const _opcionesMinutos = [60, 120, 180, 240, 300];

  int _minutos = 120;
  Set<String> _intereses = {};
  Ritmo _ritmo = Ritmo.normal;
  bool _desdeMiUbicacion = false;
  bool _buscandoUbicacion = false;

  @override
  void initState() {
    super.initState();
    _futuro = _lugaresService.obtenerLugares();
    _cargarPreferencias();
    // Si cambian los intereses en Ajustes, los volvemos a leer.
    PreferenciasService.interesesCambiaron.addListener(_cargarPreferencias);
  }

  @override
  void dispose() {
    PreferenciasService.interesesCambiaron.removeListener(_cargarPreferencias);
    super.dispose();
  }

  void _recargar() => setState(() {
        _futuro = _lugaresService.obtenerLugares()..ignore();
      });

  Future<void> _cargarPreferencias() async {
    final intereses = await _prefs.leerIntereses();
    final minutos = await _prefs.leerMinutos();
    if (!mounted) return;
    setState(() {
      _intereses = intereses;
      if (minutos != null && _opcionesMinutos.contains(minutos)) _minutos = minutos;
    });
  }

  Future<void> _generar(List<Lugar> lugares) async {
    // Seguridad extra: el botón ya está apagado si no hay intereses.
    if (_intereses.isEmpty) return;
    var inicio = Distancia.zocalo;
    var nombreInicio = tr('el Zócalo');

    if (_desdeMiUbicacion) {
      setState(() => _buscandoUbicacion = true);
      try {
        final yo = await UbicacionService().obtenerUbicacion();
        // Lejos del Centro Histórico no cabría ningún lugar en la ruta:
        // empezamos desde el Zócalo y lo avisamos.
        if (Distancia.metros(Distancia.zocalo, yo) > 15000) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(tr('Estás lejos del Centro Histórico. Armamos tu ruta desde el Zócalo.')),
            ));
          }
        } else {
          inicio = yo;
          nombreInicio = tr('tu ubicación');
        }
      } on ErrorVeraGo catch (e) {
        if (!mounted) return;
        setState(() => _buscandoUbicacion = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr(e.mensaje))));
        return;
      }
      if (!mounted) return;
      setState(() => _buscandoUbicacion = false);
    }

    await _prefs.guardar(intereses: _intereses, minutos: _minutos);
    if (!mounted) return;

    final peticion = PeticionRuta(
      inicio: inicio,
      nombreInicio: nombreInicio,
      horaInicio: DateTime.now(),
      minutosDisponibles: _minutos,
      intereses: _intereses,
      ritmo: _ritmo,
    );
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => RutaScreen(peticion: peticion, lugares: lugares)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tr('Rutas')),
        actions: [
          // La pestaña queda abierta en memoria; con esto se ven los
          // negocios recién aprobados sin cerrar la app.
          IconButton(tooltip: tr('Actualizar'), icon: const Icon(Icons.refresh), onPressed: _recargar),
        ],
      ),
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
              mensaje: tr(snapshot.error.toString()),
              textoBoton: tr('Reintentar'),
              alPresionar: _recargar,
            );
          }
          return _formulario(snapshot.data!);
        },
      ),
    );
  }

  Widget _formulario(List<Lugar> lugares) {
    final categorias = RutasScreen.categoriasDeRuta(lugares);
    // Quitamos intereses guardados de categorías que ya no existen
    // (si no, el botón se activaría con un chip invisible).
    final intereses = _intereses.where(categorias.containsKey).toSet();
    if (intereses.length != _intereses.length) _intereses = intereses;
    final faltaInteres = _intereses.isEmpty;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      children: [
        Text(
          tr('Tu recorrido a la medida'),
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 4),
        Text(tr('Dinos cuánto tiempo tienes y qué te gusta.')),
        const _Titulo('¿Cuánto tiempo tienes?'),
        Wrap(
          spacing: 8,
          children: [
            for (final m in _opcionesMinutos)
              ChoiceChip(
                label: Text('${m ~/ 60} h'),
                selected: _minutos == m,
                onSelected: (_) => setState(() => _minutos = m),
              ),
          ],
        ),
        const _Titulo('¿Qué te interesa?'),
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Text(
            faltaInteres
                ? tr('Elige al menos uno para generar tu ruta.')
                : tr('Tu ruta solo tendrá lugares de lo que elijas.'),
            style: TextStyle(
              fontSize: 12,
              color: faltaInteres ? const Color(0xFF9B2C2C) : Colors.black.withValues(alpha: 0.6),
            ),
          ),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final c in categorias.entries)
              FilterChip(
                avatar: Icon(CategoriaEstilo.de(c.key).icono, size: 18),
                label: Text(tr(c.value)),
                selected: _intereses.contains(c.key),
                onSelected: (sel) => setState(() {
                  _intereses = {..._intereses};
                  sel ? _intereses.add(c.key) : _intereses.remove(c.key);
                }),
              ),
          ],
        ),
        const _Titulo('Tu ritmo al caminar'),
        SegmentedButton<Ritmo>(
          segments: [
            for (final r in Ritmo.values) ButtonSegment(value: r, label: Text(tr(r.nombre))),
          ],
          selected: {_ritmo},
          onSelectionChanged: (s) => setState(() => _ritmo = s.first),
        ),
        const _Titulo('¿Desde dónde empiezas?'),
        SegmentedButton<bool>(
          segments: [
            ButtonSegment(value: false, icon: const Icon(Icons.location_city), label: Text(tr('Zócalo'))),
            ButtonSegment(value: true, icon: const Icon(Icons.my_location), label: Text(tr('Mi ubicación'))),
          ],
          selected: {_desdeMiUbicacion},
          onSelectionChanged: (s) => setState(() => _desdeMiUbicacion = s.first),
        ),
        if (_desdeMiUbicacion)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              tr('Usamos tu ubicación solo para empezar la ruta. No la guardamos.'),
              style: const TextStyle(fontSize: 12),
            ),
          ),
        const SizedBox(height: 28),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _buscandoUbicacion || faltaInteres ? null : () => _generar(lugares),
            icon: _buscandoUbicacion
                ? const SizedBox(
                    width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.route),
            label: Text(tr('Generar ruta')),
          ),
        ),
      ],
    );
  }
}

class _Titulo extends StatelessWidget {
  const _Titulo(this.texto);
  final String texto;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 24, bottom: 10),
        child: Text(tr(texto), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
      );
}
