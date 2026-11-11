import 'package:flutter/material.dart';

import '../widgets/estado_vacio.dart';

/// Rutas: el visitante indica tiempo e intereses y VeraGo arma un recorrido.
/// Estado: Fase 1 (solo la pestaña). El generador llega en la Fase 3.
class RutasScreen extends StatelessWidget {
  const RutasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rutas')),
      body: const EstadoVacio(
        icono: Icons.route_outlined,
        titulo: 'Tu recorrido a la medida',
        mensaje: 'Dinos cuánto tiempo tienes y qué te gusta, y armamos tu ruta.',
      ),
    );
  }
}
