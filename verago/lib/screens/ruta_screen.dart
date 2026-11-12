import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../i18n/idioma.dart';
import '../models/lugar.dart';
import '../services/distancia.dart';
import '../services/rutas_service.dart';
import '../services/trazo_service.dart';
import '../theme/app_theme.dart';
import '../widgets/boton_emergencia.dart';
import '../widgets/categoria_estilo.dart';
import '../widgets/estado_vacio.dart';
import '../widgets/etiqueta.dart';
import '../widgets/mapa_lugares.dart';
import 'lugar_screen.dart';

/// RESULTADO DE LA RUTA: mapa con la línea del recorrido y la lista de
/// paradas con hora de llegada, caminata, tiempo de visita y motivo.
///
/// La ruta se puede modificar: "Quitar" saca una parada y vuelve a generar
/// el recorrido sin ella.
///
/// El camino se dibuja POR LAS CALLES (`TrazoService`), desde el inicio
/// (Zócalo o la ubicación del turista) hasta la última parada. Mientras
/// llega, o si no hay internet, se dibuja en línea recta punteada.
///
/// Botón rojo "911": abre la app de llamadas por si algo pasa en el camino. Al final, si sobra tiempo, sugiere un comercio
/// cercano para seguir explorando.
class RutaScreen extends StatefulWidget {
  const RutaScreen({super.key, required this.peticion, required this.lugares});

  final PeticionRuta peticion;
  final List<Lugar> lugares;

  @override
  State<RutaScreen> createState() => _RutaScreenState();
}

class _RutaScreenState extends State<RutaScreen> {
  final _servicio = RutasService();
  late PeticionRuta _peticion;
  late Ruta _ruta;

  /// Camino por las calles entre las paradas (null = aún no llega o falló).
  List<LatLng>? _calles;
  bool _buscandoCalles = false;

  @override
  void initState() {
    super.initState();
    _peticion = widget.peticion;
    _ruta = _servicio.generar(_peticion, widget.lugares);
    _pedirCalles();
  }

  /// Pide el trazo por las calles: del INICIO a la última parada.
  /// Si el inicio es "Mi ubicación", ese punto se envía al servicio de rutas
  /// (decisión del equipo; lo dice el Aviso de privacidad). No se guarda.
  Future<void> _pedirCalles() async {
    final ruta = _ruta;
    final puntos = [_peticion.inicio, ...ruta.paradas.map((p) => p.lugar.punto)];
    // Sin setState aquí: se llama desde initState (donde no se permite) y
    // justo después de un setState en _quitar, que ya redibuja.
    _calles = null;
    _buscandoCalles = puntos.length > 1;
    if (ruta.paradas.isEmpty) {
      _buscandoCalles = false;
      return;
    }
    final camino = await TrazoService().caminoPorCalles(puntos);
    // Si mientras tanto quitaron una parada, esta respuesta ya no sirve.
    if (!mounted || ruta != _ruta) return;
    setState(() {
      _calles = camino;
      _buscandoCalles = false;
    });
  }

  void _quitar(Lugar lugar) {
    setState(() {
      _peticion = PeticionRuta(
        inicio: _peticion.inicio,
        nombreInicio: _peticion.nombreInicio,
        horaInicio: _peticion.horaInicio,
        minutosDisponibles: _peticion.minutosDisponibles,
        intereses: _peticion.intereses,
        ritmo: _peticion.ritmo,
        excluir: {..._peticion.excluir, lugar.id},
      );
      _ruta = _servicio.generar(_peticion, widget.lugares);
    });
    _pedirCalles();
  }

  String _hora(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  /// Título de la ruta según los intereses (ej. "Historia y sabores").
  String _titulo() {
    final i = _peticion.intereses;
    final historia = i.contains('historia') || i.contains('museo');
    final sabores = i.contains('restaurante') || i.contains('cafeteria');
    if (historia && sabores) return tr('Entre historia y sabores');
    if (historia) return tr('Recorrido histórico');
    if (sabores) return tr('Ruta de sabores');
    return tr('Tu recorrido por el centro');
  }

  @override
  Widget build(BuildContext context) {
    final paradas = _ruta.paradas;
    if (paradas.isEmpty) {
      return Scaffold(
        appBar: AppBar(),
        body: EstadoVacio(
          icono: Icons.route_outlined,
          titulo: tr('No encontramos una ruta'),
          mensaje: tr('Con ese tiempo, horario o intereses no alcanzamos a incluir lugares abiertos. Prueba con más tiempo o elige más intereses.'),
          textoBoton: tr('Cambiar preferencias'),
          alPresionar: () => Navigator.of(context).pop(),
        ),
      );
    }

    // Con trazo: todo el camino por las calles (línea continua).
    // Sin trazo (cargando o sin internet): línea recta punteada.
    final calles = _calles;
    final lineaRecta = calles == null
        ? <LatLng>[_peticion.inicio, ...paradas.map((p) => p.lugar.punto)]
        : const <LatLng>[];
    final incluidos = paradas.map((p) => p.lugar.id).toSet();
    final sugerencia = _ruta.minutosLibres >= 15
        ? _servicio.sugerenciaCercana(paradas.last.lugar.punto, widget.lugares, incluidos,
            intereses: _peticion.intereses)
        : null;

    return Scaffold(
      appBar: AppBar(title: Text(_titulo())),
      floatingActionButton: BotonEmergencia.flotante(context),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 96), // espacio para el botón 911
        children: [
          SizedBox(
            height: 260,
            child: MapaLugares(
              lugares: paradas.map((p) => p.lugar).toList(),
              centro: paradas.first.lugar.punto,
              zoom: 15.5,
              linea: lineaRecta,
              lineaPorCalles: calles ?? const [],
              // Si la ruta empieza en "Mi ubicación", marcamos dónde estabas.
              miUbicacion: _peticion.inicio == Distancia.zocalo ? null : _peticion.inicio,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
            child: Text(
              _buscandoCalles
                  ? tr('Trazando el camino por las calles…')
                  : calles != null
                      ? tr('Camino a pie por las calles (OpenStreetMap). Es aproximado: sigue las señales y cruza con cuidado.')
                      : tr('Sin conexión para trazar las calles: la línea es recta y aproximada.'),
              style: TextStyle(fontSize: 12, color: Colors.black.withValues(alpha: 0.6)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              tr('{n} paradas · {min} min caminando · termina a las {hora}', {
                'n': paradas.length,
                'min': _ruta.minutosCaminando,
                'hora': _hora(_ruta.fin),
              }),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          for (var i = 0; i < paradas.length; i++) _paradaTile(i + 1, paradas[i]),
          if (paradas.any((p) => p.lugar.horarios.isEmpty))
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Text(
                tr('Algunos lugares no tienen horario cargado: confirma en el lugar antes de ir. Los tiempos de caminata son aproximados.'),
                style: TextStyle(fontSize: 12, color: Colors.black.withValues(alpha: 0.6)),
              ),
            ),
          if (sugerencia != null) _tarjetaSugerencia(sugerencia),
        ],
      ),
    );
  }

  Widget _paradaTile(int numero, Parada p) {
    final estilo = CategoriaEstilo.de(p.lugar.categoriaClave);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: estilo.color,
                  child: Text('$numero',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(p.lugar.nombre,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                ),
                Text(_hora(p.llegada), style: const TextStyle(fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              tr('{min} min caminando · visita sugerida {visita} min',
                  {'min': p.minutosCaminando, 'visita': p.lugar.duracionVisitaMin}),
              style: TextStyle(color: Colors.black.withValues(alpha: 0.65)),
            ),
            const SizedBox(height: 4),
            Text(p.motivo, style: const TextStyle(fontStyle: FontStyle.italic)),
            if (p.lugar.esDemo) ...[
              const SizedBox(height: 6),
              const Etiqueta.demo(),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _quitar(p.lugar),
                  icon: const Icon(Icons.remove_circle_outline),
                  label: Text(tr('Quitar')),
                ),
                TextButton.icon(
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => LugarScreen(lugar: p.lugar, todos: widget.lugares),
                  )),
                  icon: const Icon(Icons.info_outline),
                  label: Text(tr('Ver ficha')),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Recomendación contextual: "Te quedan X min. Cerca de tu última parada…"
  Widget _tarjetaSugerencia(Lugar s) {
    final min = Distancia.minutosCaminando(_ruta.paradas.last.lugar.punto, s.punto);
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      color: VgColores.azulGolfo.withValues(alpha: 0.06),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: Icon(CategoriaEstilo.de(s.categoriaClave).icono, color: VgColores.azulGolfo),
        title: Text(tr('Te quedan {min} min libres', {'min': _ruta.minutosLibres})),
        subtitle: Text(tr('A {min} min de tu última parada está {lugar}. ¿Por qué no vas?',
            {'min': min, 'lugar': s.nombre})),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => LugarScreen(lugar: s, todos: widget.lugares),
        )),
      ),
    );
  }
}
