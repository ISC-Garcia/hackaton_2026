import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// BOTÓN DE EMERGENCIA 911.
///
/// Qué hace: abre la app de llamadas del celular con el 911 ya escrito
/// (enlace "tel:911"). La persona solo toca "llamar" en su teléfono.
/// Por qué así: VeraGo NO es un servicio de emergencia ni avisa a nadie;
/// solo acerca el número. (Decisión del equipo: se abre directo, sin
/// pregunta previa.)
///
/// Usa el paquete `url_launcher` (oficial de Flutter) para abrir otras apps.
class BotonEmergencia {
  static final numero = Uri(scheme: 'tel', path: '911');

  static const _color = Color(0xFFC62828);

  /// Abre la app de llamadas. Si el aparato no puede (ej. una tableta sin
  /// teléfono o la web en computadora), avisa que marquen el 911.
  static Future<void> llamar(BuildContext context) async {
    var abrio = false;
    try {
      abrio = await launchUrl(numero);
    } catch (_) {
      abrio = false;
    }
    if (!abrio && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('No pudimos abrir la app de llamadas. Marca 911 desde tu teléfono.'),
      ));
    }
  }

  /// Botón pequeño para la barra de arriba (Explorar).
  static Widget icono(BuildContext context) => IconButton(
        tooltip: 'Emergencia: llamar al 911',
        icon: const Icon(Icons.emergency_outlined, color: _color),
        onPressed: () => llamar(context),
      );

  /// Botón grande y visible para la pantalla de la ruta.
  static Widget flotante(BuildContext context) => FloatingActionButton.extended(
        heroTag: 'emergencia-911',
        tooltip: 'Emergencia: llamar al 911',
        backgroundColor: _color,
        foregroundColor: Colors.white,
        onPressed: () => llamar(context),
        icon: const Icon(Icons.emergency_outlined),
        label: const Text('911'),
      );
}
