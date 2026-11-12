import 'package:flutter/material.dart';

import '../i18n/idioma.dart';
import '../models/lugar.dart';
import '../theme/app_theme.dart';

/// Etiqueta pequeña de texto con fondo de color (ej. "Abierto", "Ficticio").
/// El texto se escribe en español y se traduce al dibujarse (`tr`), así las
/// etiquetas pueden seguir siendo `const`.
class Etiqueta extends StatelessWidget {
  const Etiqueta(this.texto, {super.key, required this.color, this.icono});

  final String texto;
  final Color color;
  final IconData? icono;

  /// Etiqueta obligatoria para todo dato ficticio de demostración.
  const Etiqueta.demo({super.key})
      : texto = 'Ficticio · demostración',
        color = const Color(0xFF6B6B6B),
        icono = Icons.science_outlined;

  /// Etiqueta según si el lugar está abierto. Siempre lleva TEXTO, no solo
  /// color, para que se entienda aunque alguien no distinga colores.
  factory Etiqueta.apertura(EstadoApertura estado) {
    switch (estado) {
      case EstadoApertura.abierto:
        return const Etiqueta('Abierto ahora', color: VgColores.verdePalma, icono: Icons.schedule);
      case EstadoApertura.cerrado:
        return const Etiqueta('Cerrado', color: Color(0xFF9B2C2C), icono: Icons.schedule);
      case EstadoApertura.sinDatos:
        return const Etiqueta('Horario no disponible', color: Color(0xFF6B6B6B), icono: Icons.schedule);
    }
  }

  /// Tipo de negocio: "Negocio formal" (local propio, da sellos) o
  /// "No formal · Punto VeraGo". null si el lugar no es un negocio.
  static Etiqueta? tipoNegocio(Lugar l) {
    if (l.esFormal) {
      return const Etiqueta('Negocio formal', color: VgColores.verdePalma, icono: Icons.store);
    }
    if (l.esInformal) {
      return const Etiqueta('No formal · Punto VeraGo', color: VgColores.terracota, icono: Icons.storefront_outlined);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icono != null) ...[
            Icon(icono, size: 14, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            tr(texto),
            style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
