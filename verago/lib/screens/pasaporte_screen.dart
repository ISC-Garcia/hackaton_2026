import 'package:flutter/material.dart';

import '../widgets/estado_vacio.dart';

/// Pasaporte: colección de sellos de los lugares visitados.
/// Estado: Fase 1 (solo la pestaña). Sellos y escaneo QR llegan en la Fase 4.
class PasaporteScreen extends StatelessWidget {
  const PasaporteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pasaporte')),
      body: const EstadoVacio(
        icono: Icons.approval_outlined,
        titulo: 'Tu pasaporte VeraGo',
        mensaje: 'Escanea el QR de los comercios participantes y colecciona sus sellos.',
      ),
    );
  }
}
