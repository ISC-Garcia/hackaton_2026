import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../services/distancia.dart';
import '../services/municipio_veracruz.dart';
import '../theme/app_theme.dart';

/// Mapa pequeño para marcar dónde está un lugar o negocio.
///
/// Cómo funciona: `MapOptions.onTap` entrega la coordenada (LatLng) del
/// punto tocado; la guardamos y dibujamos un marcador ahí.
///
/// LÍMITE: solo acepta puntos DENTRO del municipio de Veracruz.
/// - Se dibuja el contorno del municipio.
/// - El mapa no deja irse lejos (`cameraConstraint`).
/// - Un toque fuera del contorno no se acepta y se avisa.
class SelectorUbicacion extends StatelessWidget {
  const SelectorUbicacion({super.key, required this.valor, required this.alCambiar});

  /// Ubicación elegida (null si aún no toca el mapa).
  final LatLng? valor;
  final ValueChanged<LatLng> alCambiar;

  /// Mensaje al tocar fuera (público para probarlo).
  static const fueraDelMunicipio =
      'Solo puedes marcar lugares dentro del municipio de Veracruz (la línea azul del mapa).';

  void _alTocar(BuildContext context, LatLng punto) {
    if (!MunicipioVeracruz.contiene(punto)) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text(fueraDelMunicipio)));
      return;
    }
    alCambiar(punto);
  }

  @override
  Widget build(BuildContext context) {
    final elegido = valor;
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: 220,
        child: FlutterMap(
          options: MapOptions(
            initialCenter: elegido ?? Distancia.zocalo,
            initialZoom: 16,
            minZoom: 11, // lo más lejos: se ve todo el municipio
            // El centro del mapa no puede salir del rectángulo del municipio.
            cameraConstraint: CameraConstraint.containCenter(bounds: MunicipioVeracruz.limites),
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
            ),
            onTap: (_, punto) => _alTocar(context, punto),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.verago',
            ),
            // Contorno del municipio de Veracruz.
            PolygonLayer(polygons: [
              for (final poly in MunicipioVeracruz.poligonos)
                Polygon(
                  points: poly,
                  color: VgColores.azulGolfo.withValues(alpha: 0.04),
                  borderColor: VgColores.azulGolfo,
                  borderStrokeWidth: 2,
                ),
            ]),
            if (elegido != null)
              MarkerLayer(markers: [
                Marker(
                  point: elegido,
                  width: 44,
                  height: 44,
                  alignment: Alignment.topCenter, // la punta del ícono toca el lugar
                  child: const Icon(Icons.location_on, size: 44, color: VgColores.terracota),
                ),
              ]),
            const RichAttributionWidget(attributions: [TextSourceAttribution('© OpenStreetMap')]),
          ],
        ),
      ),
    );
  }
}
