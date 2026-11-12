import 'package:flutter/material.dart';

import '../legal/documentos.dart';
import '../models/lugar.dart';
import '../services/auth_service.dart';
import '../services/error_verago.dart';
import '../services/lugares_service.dart';
import '../services/negocios_service.dart';
import '../theme/app_theme.dart';
import '../widgets/categoria_estilo.dart';
import '../widgets/estado_vacio.dart';
import 'cambiar_ubicacion_screen.dart';
import 'documento_screen.dart';
import 'editar_negocio_screen.dart';
import 'estado_negocio_screen.dart';
import 'lugar_screen.dart';
import 'qr_comercio_screen.dart';

/// PANEL DEL COMERCIANTE (negocio aprobado).
///
/// Tres acciones (elegidas por el equipo):
/// 1. Mostrar mi QR (cambia cada 60 s). Solo negocios FORMALES: los de
///    un Punto VeraGo no dan sellos.
/// 2. Ver mi ficha (como la ven los turistas).
/// 3. Editar mis datos.
/// 4. Pedir cambio de ubicación (lo acepta el admin; SQL 013).
class PanelComercianteScreen extends StatefulWidget {
  const PanelComercianteScreen({super.key});

  @override
  State<PanelComercianteScreen> createState() => _PanelComercianteScreenState();
}

class _PanelComercianteScreenState extends State<PanelComercianteScreen> {
  final _servicio = NegociosService();
  late Future<Lugar?> _futuro;

  @override
  void initState() {
    super.initState();
    _futuro = _servicio.miNegocio();
  }

  void _recargar() => setState(() {
        _futuro = _servicio.miNegocio()..ignore();
      });

  Future<void> _verFicha(Lugar negocio) async {
    // La ficha necesita todos los lugares (para "Cerca de aquí").
    final List<Lugar> todos;
    try {
      todos = await LugaresService().obtenerLugares();
    } on ErrorVeraGo catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.mensaje)));
      return;
    }
    if (!mounted) return;
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => LugarScreen(lugar: negocio, todos: todos),
    ));
  }

  Future<void> _editar(Lugar negocio) async {
    final cambio = await Navigator.of(context).push<bool>(MaterialPageRoute(
      builder: (_) => EditarNegocioScreen(negocio: negocio),
    ));
    if (cambio == true) _recargar();
  }

  Future<void> _cambiarUbicacion(Lugar negocio) async {
    final envio = await Navigator.of(context).push<bool>(MaterialPageRoute(
      builder: (_) => CambiarUbicacionScreen(negocio: negocio),
    ));
    if (envio == true) _recargar();
  }

  Future<void> _cancelarCambio() async {
    try {
      await _servicio.cancelarCambioUbicacion();
      _recargar();
    } on ErrorVeraGo catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.mensaje)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mi negocio')),
      body: FutureBuilder<Lugar?>(
        future: _futuro,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return EstadoVacio(
              icono: Icons.wifi_off,
              titulo: 'Algo salió mal',
              mensaje: snapshot.error.toString(),
              textoBoton: 'Reintentar',
              alPresionar: _recargar,
            );
          }
          final negocio = snapshot.data;
          if (negocio == null) {
            return const EstadoVacio(
              icono: Icons.storefront,
              titulo: 'Sin negocio registrado',
              mensaje: 'Esta cuenta no tiene un negocio en VeraGo.',
            );
          }
          if (negocio.estadoAprobacion != 'aprobado') {
            return EstadoNegocioScreen(negocio: negocio);
          }
          return _panel(negocio);
        },
      ),
    );
  }

  Widget _panel(Lugar n) {
    final estilo = CategoriaEstilo.de(n.categoriaClave);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: VgColores.azulGolfo, borderRadius: BorderRadius.circular(20)),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: Colors.white,
                child: Icon(estilo.icono, color: estilo.color, size: 30),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(n.nombre,
                        style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(
                      n.esInformal ? '${n.giroNombre ?? n.categoriaNombre} · ${n.direccion ?? ''}' : 'Local propio · ${n.categoriaNombre}',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 6),
                    const Text('✓ Aprobado', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        // Solo los negocios FORMALES dan sellos (regla del equipo).
        if (n.esFormal)
          _Accion(
            icono: Icons.qr_code_2,
            titulo: 'Mostrar mi QR',
            texto: 'Los turistas lo escanean para ganar el sello de tu negocio.',
            alTocar: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const QrComercioScreen())),
          )
        else
          const Padding(
            padding: EdgeInsets.only(bottom: 10),
            child: Text(
              'Los negocios de un Punto VeraGo no dan sellos del pasaporte: solo los '
              'negocios formales (local propio). Los turistas te encuentran en el mapa '
              'y en las rutas, dentro de tu punto.',
              style: TextStyle(fontSize: 12),
            ),
          ),
        _Accion(
          icono: Icons.visibility_outlined,
          titulo: 'Ver mi ficha',
          texto: 'Así ven los turistas tu negocio en VeraGo.',
          alTocar: () => _verFicha(n),
        ),
        _Accion(
          icono: Icons.edit_outlined,
          titulo: 'Editar mis datos',
          texto: n.esFormal
              ? 'Descripción, teléfono y horario.'
              : 'Descripción y teléfono. Tu horario lo asigna VeraGo en tu punto.',
          alTocar: () => _editar(n),
        ),
        if (n.tieneCambioPendiente)
          Card(
            margin: const EdgeInsets.only(bottom: 10),
            color: VgColores.terracota.withValues(alpha: 0.08),
            child: ListTile(
              leading: const Icon(Icons.schedule, color: VgColores.terracota),
              title: const Text('Cambio de ubicación en revisión'),
              subtitle: Text('Pediste: ${n.cambioDireccion ?? '—'}. Mientras VeraGo lo revisa, '
                  'sigues en tu ubicación actual.'),
              trailing: TextButton(onPressed: _cancelarCambio, child: const Text('Cancelar')),
            ),
          )
        else
          _Accion(
            icono: Icons.edit_location_alt_outlined,
            titulo: n.esFormal ? 'Cambiar ubicación' : 'Cambiar de Punto VeraGo',
            texto: 'VeraGo debe aceptar el cambio; mientras tanto sigues donde estás.',
            alTocar: () => _cambiarUbicacion(n),
          ),
        _Accion(
          icono: Icons.gavel_outlined,
          titulo: 'Términos y reglas para negocios',
          texto: 'Lo que aceptaste al registrarte y cómo trabaja VeraGo.',
          alTocar: () => DocumentoScreen.abrir(context, Documentos.terminosNegocios),
        ),
        const SizedBox(height: 16),
        TextButton.icon(
          onPressed: () async {
            await AuthService().salir();
            if (mounted) Navigator.of(context).pop();
          },
          icon: const Icon(Icons.logout),
          label: const Text('Cerrar sesión'),
        ),
      ],
    );
  }
}

class _Accion extends StatelessWidget {
  const _Accion({required this.icono, required this.titulo, required this.texto, required this.alTocar});

  final IconData icono;
  final String titulo;
  final String texto;
  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.only(bottom: 10),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Icon(icono, color: VgColores.terracota, size: 30),
          title: Text(titulo, style: const TextStyle(fontWeight: FontWeight.w700)),
          subtitle: Text(texto),
          trailing: const Icon(Icons.chevron_right),
          onTap: alTocar,
        ),
      );
}
