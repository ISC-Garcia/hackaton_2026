import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'admin_lugares_screen.dart';
import 'agenda_screen.dart';
import 'admin_negocios_screen.dart';
import 'estadisticas_screen.dart';

/// PANEL DE ADMINISTRACIÓN (solo rol admin).
///
/// Por qué existe: solo los desarrolladores entran a Supabase; el admin de
/// VeraGo hace su trabajo desde aquí. La app solo muestra el botón al admin,
/// pero la seguridad real la dan las reglas RLS de la base de datos.
class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    void abrir(Widget pantalla) =>
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => pantalla));

    return Scaffold(
      appBar: AppBar(title: const Text('Administración')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _Opcion(
            icono: Icons.storefront_outlined,
            titulo: 'Solicitudes de negocios',
            texto: 'Aprobar, rechazar o suspender negocios y asignar horarios.',
            alTocar: () => abrir(const AdminNegociosScreen()),
          ),
          _Opcion(
            icono: Icons.place_outlined,
            titulo: 'Lugares y Puntos VeraGo',
            texto: 'Crear y editar lugares públicos y Puntos VeraGo con su horario.',
            alTocar: () => abrir(const AdminLugaresScreen()),
          ),
          _Opcion(
            icono: Icons.event_outlined,
            titulo: 'Agenda',
            texto: 'Crear, editar, cancelar o eliminar eventos (botón "Nuevo evento").',
            // Antes solo cerraba el panel y regresaba al Pasaporte.
            alTocar: () => abrir(const AgendaScreen()),
          ),
          _Opcion(
            icono: Icons.bar_chart,
            titulo: 'Estadísticas',
            texto: 'Datos reales de uso de la app (solo totales).',
            alTocar: () => abrir(const EstadisticasScreen()),
          ),
        ],
      ),
    );
  }
}

class _Opcion extends StatelessWidget {
  const _Opcion({required this.icono, required this.titulo, required this.texto, required this.alTocar});

  final IconData icono;
  final String titulo;
  final String texto;
  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.only(bottom: 10),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Icon(icono, color: VgColores.azulGolfo, size: 30),
          title: Text(titulo, style: const TextStyle(fontWeight: FontWeight.w700)),
          subtitle: Text(texto),
          trailing: const Icon(Icons.chevron_right),
          onTap: alTocar,
        ),
      );
}
