import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Pieza reutilizable para pantallas sin contenido o con error.
///
/// Qué hace: muestra un ícono, un título, un mensaje y, opcionalmente,
/// un botón (por ejemplo "Reintentar").
/// Por qué existe: así todas las pantallas avisan de la misma forma,
/// en lugar de dejar la pantalla en blanco.
class EstadoVacio extends StatelessWidget {
  const EstadoVacio({
    super.key,
    required this.icono,
    required this.titulo,
    required this.mensaje,
    this.textoBoton,
    this.alPresionar,
  });

  final IconData icono;
  final String titulo;
  final String mensaje;
  final String? textoBoton;
  final VoidCallback? alPresionar;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icono, size: 56, color: VgColores.azulGolfo),
            const SizedBox(height: 16),
            Text(
              titulo,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(mensaje, textAlign: TextAlign.center),
            if (textoBoton != null && alPresionar != null) ...[
              const SizedBox(height: 20),
              FilledButton(onPressed: alPresionar, child: Text(textoBoton!)),
            ],
          ],
        ),
      ),
    );
  }
}
