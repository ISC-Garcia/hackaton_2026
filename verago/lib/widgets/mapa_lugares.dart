import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../models/lugar.dart';
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
/// Si es interactivo, muestra dos botones:
/// - Leyenda: qué significa cada color de marcador.
/// - Centrar: regresa el mapa al punto inicial (el Zócalo en Explorar).
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
  });

  final List<Lugar> lugares;
  final LatLng centro;
  final double zoom;
  final void Function(Lugar)? alTocarLugar;
  final String? seleccionadoId;

  /// false = mapa fijo (para el mapa pequeño de la ficha).
  final bool interactivo;

  /// Puntos de una línea a dibujar (la ruta). Vacío = sin línea.
  final List<LatLng> linea;

  @override
  State<MapaLugares> createState() => _MapaLugaresState();
}

class _MapaLugaresState extends State<MapaLugares> {
  /// Permite mover el mapa desde código (botón "centrar").
  final _controlador = MapController();
  bool _verLeyenda = false;

  void _centrar() => _controlador.move(widget.centro, widget.zoom);

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
            if (widget.linea.length > 1)
              PolylineLayer(
                polylines: [
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
                _BotonMapa(
                  icono: Icons.my_location,
                  descripcion: 'Centrar el mapa',
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
  const _BotonMapa({required this.icono, required this.descripcion, required this.alPresionar});

  final IconData icono;
  final String descripcion;
  final VoidCallback alPresionar;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 3,
      child: IconButton(
        tooltip: descripcion, // también lo lee el lector de pantalla
        icon: Icon(icono, color: VgColores.azulGolfo),
        onPressed: alPresionar,
      ),
    );
  }
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
