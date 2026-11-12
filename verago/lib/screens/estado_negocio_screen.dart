import 'package:flutter/material.dart';

import '../models/lugar.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import 'panel_comerciante_screen.dart';

/// ESTADO DE LA SOLICITUD: se muestra si el negocio NO está aprobado.
/// pendiente → en revisión (espera al admin); rechazado → no aprobado;
/// suspendido → pausado.
///
/// La app no envía notificaciones: el equipo de VeraGo avisa por teléfono o
/// correo. Por eso hay un botón "Revisar de nuevo" para consultar el estado.
class EstadoNegocioScreen extends StatelessWidget {
  const EstadoNegocioScreen({super.key, required this.negocio, this.dentroDelPanel = false});

  final Lugar negocio;

  /// true = se dibuja dentro del panel, que ya tiene su barra de título
  /// (así no salen dos barras encimadas).
  final bool dentroDelPanel;

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
          mensaje: '"${negocio.nombre}" está pendiente. Por favor espera mientras un administrador '
              'de VeraGo revisa tu solicitud.',
        );
    }
  }

  bool get _pendiente => negocio.estadoAprobacion == 'pendiente';

  @override
  Widget build(BuildContext context) {
    final c = _contenido;
    final cuerpo = Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          children: [
            Icon(c.icono, size: 80, color: c.color),
            const SizedBox(height: 20),
            Text(c.titulo, textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 12),
            Text(c.mensaje, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, height: 1.4)),
            if (_pendiente) ...[
              const SizedBox(height: 20),
              const _QuePasaAhora(),
            ],
            const SizedBox(height: 28),
            // Vuelve a abrir el panel: si ya lo aprobaron, muestra el panel;
            // si no, este mismo estado.
            OutlinedButton.icon(
              onPressed: () => Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const PanelComercianteScreen()),
              ),
              icon: const Icon(Icons.refresh),
              label: const Text('Revisar de nuevo'),
            ),
            const SizedBox(height: 8),
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
    );
    if (dentroDelPanel) return cuerpo;
    return Scaffold(appBar: AppBar(title: const Text('Mi negocio')), body: cuerpo);
  }
}

/// Qué revisa el admin y qué sigue, para que el comerciante sepa qué esperar.
class _QuePasaAhora extends StatelessWidget {
  const _QuePasaAhora();

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: VgColores.azulGolfo.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('¿Qué pasa ahora?', style: TextStyle(fontWeight: FontWeight.w700)),
            SizedBox(height: 8),
            Text('• Revisamos tus datos y que la dirección coincida con el mapa.'),
            Text('• Si es un Punto VeraGo, confirmamos tu giro y el acuerdo del espacio.'),
            Text('• No necesitas hacer nada más. Te contactaremos por teléfono o correo.'),
            Text('• Mientras tanto, tu negocio no aparece en la app.'),
          ],
        ),
      );
}
