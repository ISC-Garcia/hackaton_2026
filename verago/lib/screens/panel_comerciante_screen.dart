import 'package:flutter/material.dart';

import '../i18n/idioma.dart';
import '../legal/documentos.dart';
import '../models/lugar.dart';
import '../services/auth_service.dart';
import '../services/eliminar_service.dart';
import '../services/error_verago.dart';
import '../services/lugares_service.dart';
import '../services/negocios_service.dart';
import '../theme/app_theme.dart';
import '../widgets/categoria_estilo.dart';
import '../widgets/eliminar_lugar.dart';
import '../widgets/estado_vacio.dart';
import 'cambiar_ubicacion_screen.dart';
import 'documento_screen.dart';
import 'editar_negocio_screen.dart';
import 'editar_vitrina_screen.dart';
import 'estado_negocio_screen.dart';
import 'estadisticas_screen.dart';
import 'lugar_screen.dart';
import 'negocio_screen.dart';
import 'qr_comercio_screen.dart';

/// PANEL DEL COMERCIANTE (negocio aprobado).
///
/// Tres acciones (elegidas por el equipo):
/// 1. Mostrar mi QR (cambia cada 60 s). Solo negocios FORMALES: los de
///    un Punto VeraGo no dan sellos.
/// 2. Ver mi ficha (como la ven los turistas).
/// 3. Editar mis datos.
/// 4. Pedir cambio de ubicación (lo acepta el admin; SQL 013).
/// 5. Mi vitrina: productos, servicios y promoción (SQL 015).
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

  Future<void> _editarVitrina(Lugar negocio) async {
    final cambio = await Navigator.of(context).push<bool>(MaterialPageRoute(
      builder: (_) => EditarVitrinaScreen(negocio: negocio),
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
      appBar: AppBar(title: Text(tr('Mi negocio'))),
      body: FutureBuilder<Lugar?>(
        future: _futuro,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return EstadoVacio(
              icono: Icons.wifi_off,
              titulo: tr('Algo salió mal'),
              mensaje: snapshot.error.toString(),
              textoBoton: tr('Reintentar'),
              alPresionar: _recargar,
            );
          }
          final negocio = snapshot.data;
          if (negocio == null) {
            return EstadoVacio(
              icono: Icons.storefront,
              titulo: tr('Sin negocio registrado'),
              mensaje: tr('Esta cuenta no tiene un negocio en VeraGo.'),
              textoBoton: tr('Registrar mi negocio'),
              alPresionar: () => Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const NegocioScreen()),
              ),
            );
          }
          if (negocio.estadoAprobacion != 'aprobado') {
            return EstadoNegocioScreen(negocio: negocio, dentroDelPanel: true);
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
                      n.esInformal ? '${tr(n.giroNombre ?? n.categoriaNombre)} · ${n.direccion ?? ''}' : tr('Local propio · {categoriaNombre}', {'categoriaNombre': tr(n.categoriaNombre)}),
                      style: const TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 6),
                    Text(tr('✓ Aprobado'), style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
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
            titulo: tr('Mostrar mi QR'),
            texto: tr('Los turistas lo escanean para ganar el sello de tu negocio.'),
            alTocar: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const QrComercioScreen())),
          )
        else
          Padding(
            padding: EdgeInsets.only(bottom: 10),
            child: Text(
              tr('Los negocios de un Punto VeraGo no dan sellos del pasaporte: solo los negocios formales (local propio). Los turistas te encuentran en el mapa y en las rutas, dentro de tu punto.'),
              style: TextStyle(fontSize: 12),
            ),
          ),
        _Accion(
          icono: Icons.storefront,
          titulo: tr('Mi vitrina'),
          texto: n.tieneVitrina
              ? (n.promocion != null
                  ? tr('{n} productos · con promoción. Toca para editar.', {'n': n.productos.length})
                  : tr('{n} productos. Toca para editar.', {'n': n.productos.length}))
              : tr('Agrega tus productos, servicios y una promoción para los turistas.'),
          alTocar: () => _editarVitrina(n),
        ),
        _Accion(
          icono: Icons.visibility_outlined,
          titulo: tr('Ver mi ficha'),
          texto: tr('Así ven los turistas tu negocio en VeraGo.'),
          alTocar: () => _verFicha(n),
        ),
        _Accion(
          icono: Icons.edit_outlined,
          titulo: tr('Editar mis datos'),
          texto: n.esFormal
              ? tr('Foto, descripción, teléfono, horario y costo de entrada.')
              : tr('Foto, descripción y teléfono. Tu horario lo asigna VeraGo en tu punto.'),
          alTocar: () => _editar(n),
        ),
        if (n.tieneCambioPendiente)
          Card(
            margin: const EdgeInsets.only(bottom: 10),
            color: VgColores.terracota.withValues(alpha: 0.08),
            child: ListTile(
              leading: const Icon(Icons.schedule, color: VgColores.terracota),
              title: Text(tr('Cambio de ubicación en revisión')),
              subtitle: Text(tr('Pediste: {direccion}. Mientras VeraGo lo revisa, sigues en tu ubicación actual.',
                  {'direccion': n.cambioDireccion ?? '—'})),
              trailing: TextButton(onPressed: _cancelarCambio, child: Text(tr('Cancelar'))),
            ),
          )
        else
          _Accion(
            icono: Icons.edit_location_alt_outlined,
            titulo: n.esFormal ? tr('Cambiar ubicación') : tr('Cambiar de Punto VeraGo'),
            texto: tr('VeraGo debe aceptar el cambio; mientras tanto sigues donde estás.'),
            alTocar: () => _cambiarUbicacion(n),
          ),
        _Accion(
          icono: Icons.query_stats,
          titulo: tr('Mis estadísticas'),
          texto: tr('Cuántos sellos ha dado tu negocio por día (sin datos personales).'),
          alTocar: () => Navigator.of(context)
              .push(MaterialPageRoute(builder: (_) => const EstadisticasScreen(deMiNegocio: true))),
        ),
        _Accion(
          icono: Icons.gavel_outlined,
          titulo: tr('Términos y reglas para negocios'),
          texto: tr('Lo que aceptaste al registrarte y cómo trabaja VeraGo.'),
          alTocar: () => DocumentoScreen.abrir(context, Documentos.terminosNegocios),
        ),
        const SizedBox(height: 16),
        TextButton.icon(
          onPressed: () async {
            await AuthService().salir();
            if (mounted) Navigator.of(context).pop();
          },
          icon: const Icon(Icons.logout),
          label: Text(tr('Cerrar sesión')),
        ),
        // Eliminar MI negocio (mi cuenta sigue). Si ya tiene sellos, se oculta.
        TextButton.icon(
          onPressed: () async {
            final listo = await EliminarLugar.ejecutar(context, n, ocultar: EliminarService().ocultarMiNegocio);
            if (listo && mounted) Navigator.of(context).pop(true);
          },
          style: TextButton.styleFrom(foregroundColor: const Color(0xFF9B2C2C)),
          icon: const Icon(Icons.delete_outline),
          label: Text(tr('Eliminar mi negocio')),
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
