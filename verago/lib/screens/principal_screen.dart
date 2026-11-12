import 'package:flutter/material.dart';

import '../i18n/idioma.dart';
import 'agenda_screen.dart';
import 'explorar_screen.dart';
import 'pasaporte_screen.dart';
import 'rutas_screen.dart';

/// Pantalla principal con la barra inferior de 4 pestañas
/// (sección 15.2 del documento): Explorar, Rutas, Agenda, Pasaporte.
///
/// Cómo funciona: guarda en `_pestana` cuál está seleccionada.
/// Al tocar otra, `setState` cambia el número y Flutter vuelve a dibujar.
/// `IndexedStack` mantiene vivas las 4 pantallas, así no se pierde lo
/// que el usuario tenía abierto al cambiar de pestaña.
class PrincipalScreen extends StatefulWidget {
  const PrincipalScreen({super.key});

  @override
  State<PrincipalScreen> createState() => _PrincipalScreenState();
}

class _PrincipalScreenState extends State<PrincipalScreen> {
  int _pestana = 0;

  static const _pantallas = [
    ExplorarScreen(),
    RutasScreen(),
    AgendaScreen(),
    PasaporteScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _pestana, children: _pantallas),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _pestana,
        onDestinationSelected: (i) {
          FocusScope.of(context).unfocus(); // cierra el teclado al cambiar de pestaña
          setState(() => _pestana = i);
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.explore_outlined),
            selectedIcon: const Icon(Icons.explore),
            label: tr('Explorar'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.route_outlined),
            selectedIcon: const Icon(Icons.route),
            label: tr('Rutas'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.event_outlined),
            selectedIcon: const Icon(Icons.event),
            label: tr('Agenda'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.approval_outlined),
            selectedIcon: const Icon(Icons.approval),
            label: tr('Pasaporte'),
          ),
        ],
      ),
    );
  }
}
