import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../models/lugar.dart';
import '../services/distancia.dart';
import 'etiqueta.dart';
import 'foto_lugar.dart';

/// Tarjeta de un lugar para listas: ícono de categoría, nombre,
/// distancia caminando y etiquetas (abierto, pasaporte, ficticio).
class TarjetaLugar extends StatelessWidget {
  const TarjetaLugar({
    super.key,
    required this.lugar,
    required this.desde,
    required this.alTocar,
  });

  final Lugar lugar;

  /// Punto desde el que se mide la distancia (por defecto, el Zócalo).
  final LatLng desde;
  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: alTocar,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Foto del lugar; si no tiene, bloque de color con su ícono.
              FotoLugar(lugar: lugar, ancho: 56, alto: 56),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lugar.nombre,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${lugar.categoriaNombre} · ${Distancia.texto(desde, lugar.punto)}',
                      style: TextStyle(color: Colors.black.withValues(alpha: 0.6)),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        Etiqueta.apertura(lugar.estadoEn(DateTime.now())),
                        ?Etiqueta.tipoNegocio(lugar),
                        // Solo si cobra entrada (gratis o sin dato no ocupan espacio).
                        if ((lugar.costoEntradaMxn ?? 0) > 0)
                          Etiqueta('Entrada ≈ \$${lugar.costoEntradaMxn}',
                              color: const Color(0xFF6B4E16), icono: Icons.confirmation_number_outlined),
                        if (lugar.promocion != null)
                          const Etiqueta('Promoción', color: Color(0xFFB8492F), icono: Icons.local_offer_outlined),
                        if (lugar.participaPasaporte)
                          const Etiqueta('Da sello', color: Color(0xFF0B3C5D), icono: Icons.approval),
                        if (lugar.esDemo) const Etiqueta.demo(),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
