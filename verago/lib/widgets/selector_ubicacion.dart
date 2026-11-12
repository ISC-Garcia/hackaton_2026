import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../services/distancia.dart';
import '../theme/app_theme.dart';

/// Mapa pequeño para que el comerciante FORMAL toque dónde está su local.
///
/// Cómo funciona: `MapOptions.onTap` entrega la coordenada (LatLng) del
/// punto tocado; la guardamos y dibujamos un marcador ahí.
class SelectorUbicacion extends StatelessWidget {
  const SelectorUbicacion({super.key, required this.valor, required this.alCambiar});

  /// Ubicación elegida (null si aún no toca el mapa).
  final LatLng? valor;
  final ValueChanged<LatLng> alCambiar;

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
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
            ),
            onTap: (_, punto) => alCambiar(punto),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.verago',
            ),
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
