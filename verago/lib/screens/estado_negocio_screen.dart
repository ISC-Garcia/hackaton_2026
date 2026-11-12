import 'package:flutter/material.dart';

import '../models/lugar.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';

/// ESTADO DE LA SOLICITUD: se muestra si el negocio NO está aprobado.
/// pendiente → en revisión; rechazado → no aprobado; suspendido → pausado.
class EstadoNegocioScreen extends StatelessWidget {
  const EstadoNegocioScreen({super.key, required this.negocio});

  final Lugar negocio;

  ({IconData icono, Color color, String titulo, String mensaje}) get _contenido {
    switch (negocio.estadoAprobacion) {
      case 'rechazado':
        return (
          icono: Icons.cancel_outlined,
          color: const Color(0xFF9B2C2C),
          titulo: 'Tu solicitud no fue aprobada',
          mensaje: 'El equipo de VeraGo revisó "${negocio.nombre}" y no pudo aprobarlo. '
              'Escríbenos para conocer el motivo o volver a intentarlo.',
        );
      case 'suspendido':
        return (
          icono: Icons.pause_circle_outline,
          color: VgColores.terracota,
          titulo: 'Tu negocio está suspendido',
          mensaje: '"${negocio.nombre}" no aparece por ahora en VeraGo. '
              'Contacta al equipo de VeraGo para reactivarlo.',
        );
      default:
        return (
          icono: Icons.hourglass_top,
          color: VgColores.azulGolfo,
          titulo: 'Solicitud en revisión',
          mensaje: '"${negocio.nombre}" está pendiente de revisión por el equipo de VeraGo. '
              'Te avisaremos cuando sea aprobado.',
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _contenido;
    return Scaffold(
      appBar: AppBar(title: const Text('Mi negocio')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            children: [
              Icon(c.icono, size: 80, color: c.color),
              const SizedBox(height: 20),
              Text(c.titulo, textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 12),
              Text(c.mensaje, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, height: 1.4)),
              const SizedBox(height: 28),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Volver a VeraGo'),
              ),
              TextButton(
                onPressed: () async {
                  await AuthService().salir();
                  if (context.mounted) Navigator.of(context).pop();
                },
                child: const Text('Cerrar sesión'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
