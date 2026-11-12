import 'package:flutter/material.dart';

import '../i18n/idioma.dart';
import '../theme/app_theme.dart';

/// DIRECCIÓN QUE DA EL MAPA (solo texto, NO es un campo para escribir).
///
/// Se usa debajo del mapa en: registro de negocio, cambio de ubicación y
/// lugares del admin. La dirección sale del punto tocado (Nominatim); para
/// cambiarla hay que mover el punto. Así la dirección siempre coincide con el
/// mapa y nadie puede escribir otra distinta.
///
/// Es un `FormField`: el formulario lo revisa al guardar (si no hay punto,
/// si aún se está buscando o si no se pudo obtener la dirección).
class DireccionDelMapa extends StatelessWidget {
  const DireccionDelMapa({
    super.key,
    required this.direccion,
    required this.hayPunto,
    required this.buscando,
    this.alReintentar,
    this.titulo = 'Dirección (según el mapa)',
  });

  /// Dirección obtenida del mapa ('' si aún no hay).
  final String direccion;

  /// ¿Ya se tocó el mapa?
  final bool hayPunto;

  /// ¿Se está pidiendo la dirección a OpenStreetMap?
  final bool buscando;

  /// Volver a pedir la dirección (si falló, ej. sin internet).
  final VoidCallback? alReintentar;

  /// Título en español (se traduce al dibujarse).
  final String titulo;

  String? _validar() {
    if (!hayPunto) return tr('Primero toca el mapa');
    if (buscando) return tr('Espera a que se cargue la dirección');
    if (direccion.trim().isEmpty) return tr('No hay dirección: toca el mapa o "Reintentar"');
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final hayDireccion = direccion.trim().isNotEmpty;
    final String texto;
    if (buscando) {
      texto = tr('Buscando la dirección del punto…');
    } else if (hayDireccion) {
      texto = direccion;
    } else if (hayPunto) {
      texto = tr('No pudimos obtener la dirección (¿sin internet?). Toca "Reintentar".');
    } else {
      texto = tr('Toca el mapa para ver aquí la dirección.');
    }

    return FormField<String>(
      // La llave cambia con los datos: así el aviso rojo se borra solo
      // cuando llega la dirección.
      key: ValueKey('$hayPunto|$buscando|$direccion'),
      validator: (_) => _validar(),
      builder: (estado) {
        final error = estado.errorText;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: VgColores.azulGolfo.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: error != null ? const Color(0xFF9B2C2C) : Colors.transparent),
              ),
              child: Row(
                children: [
                  const Icon(Icons.place_outlined, color: VgColores.azulGolfo),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(tr(titulo), style: TextStyle(fontSize: 12, color: Colors.black.withValues(alpha: 0.6))),
                        const SizedBox(height: 2),
                        Text(
                          texto,
                          style: TextStyle(
                            fontWeight: hayDireccion ? FontWeight.w600 : FontWeight.w400,
                            color: hayDireccion ? VgColores.tinta : Colors.black.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (buscando)
                    const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  else if (hayPunto && !hayDireccion && alReintentar != null)
                    IconButton(
                      tooltip: tr('Reintentar'),
                      icon: const Icon(Icons.refresh),
                      onPressed: alReintentar,
                    ),
                ],
              ),
            ),
            if (error != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
                child: Text(error, style: const TextStyle(color: Color(0xFF9B2C2C), fontSize: 12)),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
              child: Text(
                tr('La dirección sale del punto del mapa: para cambiarla, mueve el punto.'),
                style: TextStyle(fontSize: 12, color: Colors.black.withValues(alpha: 0.55)),
              ),
            ),
          ],
        );
      },
    );
  }
}
