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
/// Se usa en Explorar, en la ficha del lugar y (Fase 3) en la ruta.
class MapaLugares extends StatelessWidget {
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

  /// Puntos de una línea a dibujar (la ruta). Vacío = sin línea.
  final List<LatLng> linea;

  final List<Lugar> lugares;
  final LatLng centro;
  final double zoom;
  final void Function(Lugar)? alTocarLugar;
  final String? seleccionadoId;

  /// false = mapa fijo (para el mapa pequeño de la ficha).
  final bool interactivo;

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      options: MapOptions(
        initialCenter: centro,
        initialZoom: zoom,
        interactionOptions: InteractionOptions(
          flags: interactivo ? InteractiveFlag.all & ~InteractiveFlag.rotate : InteractiveFlag.none,
        ),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.verago',
        ),
        if (linea.length > 1)
          PolylineLayer(
            polylines: [
              Polyline(
                points: linea,
                strokeWidth: 4,
                color: VgColores.terracota,
                pattern: StrokePattern.dashed(segments: const [10, 6]),
              ),
            ],
          ),
        MarkerLayer(
          markers: [
            for (final lugar in lugares)
              Marker(
                point: lugar.punto,
                width: 44,
                height: 44,
                child: _Marcador(
                  lugar: lugar,
                  seleccionado: lugar.id == seleccionadoId,
                  alTocar: alTocarLugar == null ? null : () => alTocarLugar!(lugar),
                ),
              ),
          ],
        ),
        const RichAttributionWidget(
          attributions: [TextSourceAttribution('© OpenStreetMap')],
        ),
      ],
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
