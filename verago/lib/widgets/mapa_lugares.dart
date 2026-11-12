import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../models/lugar.dart';
import '../services/geocodificacion_service.dart';
import '../theme/app_theme.dart';
import 'categoria_estilo.dart';

/// Mapa reutilizable con los lugares como marcadores.
///
/// Qué usa:
/// - `flutter_map`: dibuja el mapa y los marcadores.
/// - Mapas de OpenStreetMap: mapa libre y gratuito. Su política de uso pide
///   identificar la app (userAgentPackageName) y mostrar el crédito
///   "© OpenStreetMap", por eso aparece abajo a la derecha.
///
/// Si es interactivo, muestra botones:
/// - Dónde estoy (solo si la pantalla lo pide): pone el punto azul
///   "Estás aquí". La ubicación se toma UNA vez, al tocar; no te sigue.
/// - Centrar: regresa el mapa al punto inicial (el Zócalo en Explorar).
/// - Leyenda: qué significa cada color de marcador.
///
/// Se usa en Explorar, en la ficha del lugar y en la ruta.
class MapaLugares extends StatefulWidget {
  const MapaLugares({
    super.key,
    required this.lugares,
    required this.centro,
    this.zoom = 16,
    this.alTocarLugar,
    this.seleccionadoId,
    this.interactivo = true,
    this.linea = const [],
    this.lineaPorCalles = const [],
    this.miUbicacion,
    this.alPedirUbicacion,
    this.buscandoUbicacion = false,
    this.delMapa = const [],
    this.alTocarDelMapa,
    this.enfocar,
  });

  /// Lugares encontrados en OpenStreetMap (no son de VeraGo): pin morado.
  final List<LugarDelMapa> delMapa;
  final void Function(LugarDelMapa)? alTocarDelMapa;

  /// Si cambia, el mapa se mueve a este punto (ej. al primer resultado).
  final LatLng? enfocar;

  /// Dónde está el turista (punto azul). null = no lo sabemos.
  final LatLng? miUbicacion;

  /// Si no es null, aparece el botón "Mostrar dónde estoy".
  final VoidCallback? alPedirUbicacion;

  /// true mientras el celular busca la ubicación (el botón gira).
  final bool buscandoUbicacion;

  final List<Lugar> lugares;
  final LatLng centro;
  final double zoom;
  final void Function(Lugar)? alTocarLugar;
  final String? seleccionadoId;

  /// false = mapa fijo (para el mapa pequeño de la ficha).
  final bool interactivo;

  /// Línea PUNTEADA (tramo aproximado, en línea recta). Vacío = sin línea.
  final List<LatLng> linea;

  /// Línea CONTINUA por las calles (camino real de la ruta). Vacío = sin línea.
  final List<LatLng> lineaPorCalles;

  @override
  State<MapaLugares> createState() => _MapaLugaresState();
}

class _MapaLugaresState extends State<MapaLugares> {
  /// Permite mover el mapa desde código (botón "centrar").
  final _controlador = MapController();
  bool _verLeyenda = false;

  void _centrar() => _controlador.move(widget.centro, widget.zoom);

  /// Al llegar la ubicación del turista, movemos el mapa hacia ella.
  @override
  void didUpdateWidget(MapaLugares anterior) {
    super.didUpdateWidget(anterior);
    final yo = widget.miUbicacion;
    if (yo != null && yo != anterior.miUbicacion) _controlador.move(yo, widget.zoom);
    final foco = widget.enfocar;
    if (foco != null && foco != anterior.enfocar) _controlador.move(foco, 15);
  }

  @override
  Widget build(BuildContext context) {
    // Categorías presentes en el mapa, sin repetir (para la leyenda).
    final categorias = <String>{for (final l in widget.lugares) l.categoriaClave};

    return Stack(
      children: [
        FlutterMap(
          mapController: _controlador,
          options: MapOptions(
            initialCenter: widget.centro,
            initialZoom: widget.zoom,
            interactionOptions: InteractionOptions(
              flags: widget.interactivo
                  ? InteractiveFlag.all & ~InteractiveFlag.rotate
                  : InteractiveFlag.none,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.verago',
            ),
            if (widget.linea.length > 1 || widget.lineaPorCalles.length > 1)
              PolylineLayer(
                polylines: [
                  if (widget.lineaPorCalles.length > 1)
                    Polyline(points: widget.lineaPorCalles, strokeWidth: 5, color: VgColores.terracota),
                  if (widget.linea.length > 1)
                    Polyline(
                      points: widget.linea,
                      strokeWidth: 4,
                      color: VgColores.terracota,
                      pattern: StrokePattern.dashed(segments: const [10, 6]),
                    ),
                ],
              ),
            MarkerLayer(
              markers: [
                for (final lugar in widget.lugares)
                  Marker(
                    point: lugar.punto,
                    width: 44,
                    height: 44,
                    child: _Marcador(
                      lugar: lugar,
                      seleccionado: lugar.id == widget.seleccionadoId,
                      alTocar: widget.alTocarLugar == null ? null : () => widget.alTocarLugar!(lugar),
                    ),
                  ),
                for (final otro in widget.delMapa)
                  Marker(
                    point: otro.punto,
                    width: 40,
                    height: 40,
                    alignment: Alignment.topCenter, // la punta del pin en el lugar
                    child: Semantics(
                      label: '${otro.nombre} (lugar del mapa)',
                      button: widget.alTocarDelMapa != null,
                      child: GestureDetector(
                        onTap: widget.alTocarDelMapa == null ? null : () => widget.alTocarDelMapa!(otro),
                        child: const Icon(Icons.location_on, size: 40, color: Color(0xFF6A1B9A)),
                      ),
                    ),
                  ),
                // Al final, para que quede encima de los lugares.
                if (widget.miUbicacion case final yo?)
                  Marker(point: yo, width: 26, height: 26, child: const _EstasAqui()),
              ],
            ),
            const RichAttributionWidget(
              attributions: [TextSourceAttribution('© OpenStreetMap')],
            ),
          ],
        ),
        if (widget.interactivo) ...[
          // Botones arriba a la derecha
          Positioned(
            top: 12,
            right: 12,
            child: Column(
              children: [
                if (widget.alPedirUbicacion != null) ...[
                  _BotonMapa(
                    icono: Icons.my_location,
                    descripcion: 'Mostrar dónde estoy',
                    alPresionar: widget.buscandoUbicacion ? null : widget.alPedirUbicacion,
                    cargando: widget.buscandoUbicacion,
                  ),
                  const SizedBox(height: 8),
                ],
                // Antes este botón usaba el ícono de "mi ubicación" y confundía:
                // solo regresa el mapa al punto inicial.
                _BotonMapa(
                  icono: Icons.center_focus_strong_outlined,
                  descripcion: 'Volver a centrar el mapa',
                  alPresionar: _centrar,
                ),
                const SizedBox(height: 8),
                _BotonMapa(
                  icono: _verLeyenda ? Icons.close : Icons.info_outline,
                  descripcion: _verLeyenda ? 'Ocultar leyenda' : 'Ver leyenda de colores',
                  alPresionar: () => setState(() => _verLeyenda = !_verLeyenda),
                ),
              ],
            ),
          ),
          // Leyenda arriba a la izquierda
          if (_verLeyenda)
            Positioned(
              top: 12,
              left: 12,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final clave in CategoriaEstilo.nombres.keys)
                        if (categorias.contains(clave))
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 3),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircleAvatar(
                                  radius: 11,
                                  backgroundColor: CategoriaEstilo.de(clave).color,
                                  child: Icon(CategoriaEstilo.de(clave).icono, size: 13, color: Colors.white),
                                ),
                                const SizedBox(width: 8),
                                Text(CategoriaEstilo.nombres[clave]!, style: const TextStyle(fontSize: 13)),
                              ],
                            ),
                          ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ],
    );
  }
}

/// Botón redondo blanco sobre el mapa.
class _BotonMapa extends StatelessWidget {
  const _BotonMapa({
    required this.icono,
    required this.descripcion,
    required this.alPresionar,
    this.cargando = false,
  });

  final IconData icono;
  final String descripcion;
  final VoidCallback? alPresionar;
  final bool cargando;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 3,
      child: IconButton(
        tooltip: descripcion, // también lo lee el lector de pantalla
        icon: cargando
            ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))
            : Icon(icono, color: VgColores.azulGolfo),
        onPressed: alPresionar,
      ),
    );
  }
}

/// Punto azul "Estás aquí".
class _EstasAqui extends StatelessWidget {
  const _EstasAqui();

  @override
  Widget build(BuildContext context) => Semantics(
        label: 'Estás aquí',
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1E88E5),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: const [BoxShadow(color: Color(0x661E88E5), blurRadius: 10, spreadRadius: 4)],
          ),
        ),
      );
}

/// Marcador redondo con el ícono y color de la categoría.
class _Marcador extends StatelessWidget {
  const _Marcador({required this.lugar, required this.seleccionado, this.alTocar});

  final Lugar lugar;
  final bool seleccionado;
  final VoidCallback? alTocar;

  @override
  Widget build(BuildContext context) {
    final estilo = CategoriaEstilo.de(lugar.categoriaClave);
    return Semantics(
      label: lugar.nombre, // lector de pantalla
      button: alTocar != null,
      child: GestureDetector(
        onTap: alTocar,
        child: Container(
          decoration: BoxDecoration(
            color: estilo.color,
            shape: BoxShape.circle,
            border: Border.all(
              color: seleccionado ? VgColores.tinta : Colors.white,
              width: seleccionado ? 3 : 2,
            ),
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
          ),
          child: Icon(estilo.icono, color: Colors.white, size: 22),
        ),
      ),
    );
  }
}
