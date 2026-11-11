import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../models/lugar.dart';
import '../services/distancia.dart';
import 'categoria_estilo.dart';
import 'etiqueta.dart';

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
    final estilo = CategoriaEstilo.de(lugar.categoriaClave);
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
              // En lugar de foto: bloque de color con el ícono de la categoría.
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: estilo.color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(estilo.icono, color: estilo.color, size: 28),
              ),
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
