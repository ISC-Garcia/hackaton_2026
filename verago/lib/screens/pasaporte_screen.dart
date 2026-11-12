import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthState;

import '../i18n/idioma.dart';
import '../models/insignia.dart';
import '../models/lugar.dart';
import '../models/sello.dart';
import '../services/auth_service.dart';
import '../services/lugares_service.dart';
import '../services/pasaporte_service.dart';
import '../theme/app_theme.dart';
import '../widgets/categoria_estilo.dart';
import '../widgets/estado_vacio.dart';
import '../widgets/insignia_visual.dart';
import 'ajustes_screen.dart';
import 'escanear_screen.dart';
import 'admin_screen.dart';
import 'login_screen.dart';
import 'negocio_screen.dart';
import 'panel_comerciante_screen.dart';

/// Datos que necesita la pantalla del pasaporte, cargados juntos.
class DatosPasaporte {
  const DatosPasaporte(this.perfil, this.sellos, this.lugares);
  final Perfil perfil;
  final List<Sello> sellos;
  final List<Lugar> lugares;
}

/// PASAPORTE: colección de sellos de los lugares visitados.
///
/// - Invitado: explica el pasaporte y ofrece iniciar sesión.
/// - Con sesión: colección (qué comercios ya selló y cuáles faltan),
///   historial y botón para escanear.
/// - Comerciante: botón para mostrar el QR de su comercio.
/// - Admin: acceso a estadísticas (datos simulados).
class PasaporteScreen extends StatefulWidget {
  const PasaporteScreen({super.key, this.cargadorDePrueba});

  /// SOLO para pruebas automáticas: entrega datos falsos y simula sesión,
  /// para dibujar la pantalla sin Supabase. En la app real es null.
  final Future<DatosPasaporte> Function()? cargadorDePrueba;

  @override
  State<PasaporteScreen> createState() => _PasaporteScreenState();
}

class _PasaporteScreenState extends State<PasaporteScreen> {
  final _auth = AuthService();
  final _pasaporte = PasaporteService();
  final _lugares = LugaresService();
  Future<DatosPasaporte>? _futuro;
  StreamSubscription<AuthState>? _suscripcion;

  @override
  void initState() {
    super.initState();
    if (_auth.usuario != null) _futuro = _cargar();
    // Si alguien entra o sale, recargamos la pantalla.
    _suscripcion = _auth.cambios.listen((_) {
      if (!mounted) return;
      setState(() {
        _futuro = _auth.usuario != null ? (_cargar()..ignore()) : null;
      });
    });
  }

  @override
  void dispose() {
    _suscripcion?.cancel(); // dejar de escuchar al cerrar la pantalla
    super.dispose();
  }

  bool get _conSesion => widget.cargadorDePrueba != null || _auth.usuario != null;

  Future<DatosPasaporte> _cargar() async {
    final prueba = widget.cargadorDePrueba;
    if (prueba != null) return _ultimos = await prueba();
    final resultados = await Future.wait([
      _pasaporte.miPerfil(),
      _pasaporte.misSellos(),
      _lugares.obtenerLugares(),
    ]);
    return _ultimos = DatosPasaporte(
      resultados[0] as Perfil,
      resultados[1] as List<Sello>,
      resultados[2] as List<Lugar>,
    );
  }

  /// Últimos datos cargados (Ajustes usa el perfil).
  DatosPasaporte? _ultimos;

  Future<void> _abrirAjustes() async {
    final cambio = await Navigator.of(context).push<bool>(MaterialPageRoute(
      builder: (_) => AjustesScreen(perfil: _conSesion ? _ultimos?.perfil : null),
    ));
    if (!mounted) return;
    // Si cambió el nombre o se cerró sesión, recargamos.
    if (cambio == true || !_conSesion) {
      setState(() {
      _futuro = _conSesion ? (_cargar()..ignore()) : null;
    });
    }
  }

  void _recargar() => setState(() {
        _futuro = _cargar()..ignore();
      });

  Future<void> _iniciarSesion() async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LoginScreen()));
    // Al regresar del login, volvemos a revisar la sesión y cargamos los
    // datos. No dependemos solo del aviso de Supabase (más seguro).
    if (!mounted) return;
    setState(() {
      _futuro = _conSesion ? (_cargar()..ignore()) : null;
    });
  }

  /// "Soy un negocio": abre directo el registro de negocios.
  Widget _botonSoyNegocio() => OutlinedButton.icon(
        onPressed: () async {
          await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NegocioScreen()));
          // Al volver: si registró su negocio con la sesión abierta, ahora es
          // comerciante y debe ver "Panel de mi negocio" (antes no se recargaba).
          if (mounted && _conSesion) _recargar();
        },
        icon: const Icon(Icons.storefront_outlined),
        label: Text(tr('Soy un negocio')),
      );

  Future<void> _escanear(DatosPasaporte d) async {
    final hubo = await Navigator.of(context).push<bool>(MaterialPageRoute(
      builder: (_) => EscanearScreen(
        lugares: d.lugares,
        sellados: d.sellos.map((s) => s.lugarId).toSet(),
      ),
    ));
    if (hubo == true) _recargar();
  }

  @override
  Widget build(BuildContext context) {
    final conSesion = _conSesion;
    // Si hay sesión pero aún no empezó la carga, la empezamos aquí.
    // Evita que la pantalla se quede vacía o cargando para siempre.
    if (conSesion && _futuro == null) _futuro = _cargar();
    return Scaffold(
      appBar: AppBar(
        title: Text(tr('Pasaporte')),
        actions: [
          IconButton(
            tooltip: tr('Ajustes'),
            icon: const Icon(Icons.settings_outlined),
            onPressed: _abrirAjustes,
          ),
        ],
      ),
      body: !conSesion
          ? Center(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    EstadoVacio(
                      icono: Icons.approval_outlined,
                      titulo: tr('Tu pasaporte VeraGo'),
                      mensaje: tr('Escanea el QR de los comercios participantes y colecciona sus sellos. Necesitas una cuenta para guardarlos.'),
                      textoBoton: tr('Iniciar sesión'),
                      alPresionar: _iniciarSesion,
                    ),
                    _botonSoyNegocio(),
                  ],
                ),
              ),
            )
          : FutureBuilder<DatosPasaporte>(
              future: _futuro,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return EstadoVacio(
                    icono: Icons.wifi_off,
                    titulo: tr('Algo salió mal'),
                    mensaje: tr(snapshot.error.toString()),
                    textoBoton: tr('Reintentar'),
                    alPresionar: _recargar,
                  );
                }
                return _contenido(snapshot.data!);
              },
            ),
    );
  }

  Widget _contenido(DatosPasaporte d) {
    final sellados = d.sellos.map((s) => s.lugarId).toSet();
    final participantes = d.lugares.where((l) => l.participaPasaporte).toList();
    final logrados = participantes.where((l) => sellados.contains(l.id)).length;
    final insignia = Insignia.calcular(logrados: logrados, total: participantes.length);

    return RefreshIndicator(
      onRefresh: () async {
        _recargar();
        await _futuro;
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        children: [
          // Encabezado
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: VgColores.azulGolfo,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tr('Hola, {nombre}', {'nombre': d.perfil.nombre}),
                    style: const TextStyle(color: Colors.white, fontSize: 18)),
                const SizedBox(height: 8),
                Text(
                  tr('{n} de {total}', {'n': logrados, 'total': participantes.length}),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'serif',
                    fontFamilyFallback: ['Georgia'],
                  ),
                ),
                Text(tr('comercios sellados en tu pasaporte'),
                    style: const TextStyle(color: Colors.white70)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (insignia.total > 0) TarjetaInsignia(progreso: insignia),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => _escanear(d),
            icon: const Icon(Icons.qr_code_scanner),
            label: Text(tr('Escanear QR')),
          ),
          if (d.perfil.esComerciante) ...[
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () async {
                await Navigator.of(context)
                    .push(MaterialPageRoute(builder: (_) => const PanelComercianteScreen()));
                // Al volver: si eliminó su negocio, ya no es comerciante.
                if (mounted) _recargar();
              },
              icon: const Icon(Icons.storefront_outlined),
              label: const Text('Panel de mi negocio'),
            ),
          ] else ...[
            const SizedBox(height: 8),
            _botonSoyNegocio(),
          ],
          if (d.perfil.esAdmin) ...[
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => Navigator.of(context)
                  .push(MaterialPageRoute(builder: (_) => const AdminScreen())),
              icon: const Icon(Icons.admin_panel_settings_outlined),
              label: const Text('Panel de administración'),
            ),
          ],
          const SizedBox(height: 24),
          Text(tr('Tu colección'), style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.8,
            children: [
              for (final l in participantes) _SelloVisual(lugar: l, obtenido: sellados.contains(l.id)),
            ],
          ),
          const SizedBox(height: 24),
          Text(tr('Historial'), style: Theme.of(context).textTheme.titleLarge),
          if (d.sellos.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(tr('Aún no tienes sellos. Visita un comercio participante y escanea su QR.')),
            )
          else
            for (final s in d.sellos)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(CategoriaEstilo.de(s.categoriaClave).icono,
                    color: CategoriaEstilo.de(s.categoriaClave).color),
                title: Text(s.lugarNombre),
                subtitle: Text(
                  '${s.fecha.day}/${s.fecha.month}/${s.fecha.year} · '
                  '${s.fecha.hour.toString().padLeft(2, '0')}:${s.fecha.minute.toString().padLeft(2, '0')}',
                ),
              ),
        ],
      ),
    );
  }
}

/// INSIGNIA: la actual (o la primera bloqueada), cuánto falta para la
/// siguiente y la fila de los 5 niveles. Es pública para poder probarla.
class TarjetaInsignia extends StatelessWidget {
  const TarjetaInsignia({super.key, required this.progreso});

  final ProgresoInsignia progreso;

  @override
  Widget build(BuildContext context) {
    final p = progreso;
    final actual = p.actual;
    final siguiente = p.siguiente;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                InsigniaVisual(nivel: actual?.numero ?? 1, tamano: 64, bloqueada: actual == null),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(actual == null ? tr('Sin insignia todavía') : tr(actual.nombre),
                          style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 2),
                      Text(
                          actual == null
                              ? tr('Consigue sellos para ganar tu primera insignia.')
                              : tr(actual.descripcion),
                          style: TextStyle(color: Colors.black.withValues(alpha: 0.65))),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (siguiente != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(value: p.avance, minHeight: 8),
              ),
              const SizedBox(height: 6),
              Text(
                p.faltan == 1
                    ? tr('Te falta 1 sello para "{nivel}"', {'nivel': tr(siguiente.nombre)})
                    : tr('Te faltan {n} sellos para "{nivel}"', {'n': p.faltan, 'nivel': tr(siguiente.nombre)}),
                style: const TextStyle(fontSize: 13),
              ),
            ] else
              Text(tr('¡Tienes todas las insignias!'), style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            // Los 5 niveles: ganados a color, los demás con candado.
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (final n in Insignia.niveles)
                  Tooltip(
                    message: tr('{nivel}: {n} sellos', {'nivel': tr(n.nombre), 'n': p.metas[n.numero - 1]}),
                    child: InsigniaVisual(nivel: n.numero, tamano: 34, bloqueada: n.numero > p.nivel),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Un sello de la colección: a color si ya se obtuvo, gris si falta.
class _SelloVisual extends StatelessWidget {
  const _SelloVisual({required this.lugar, required this.obtenido});

  final Lugar lugar;
  final bool obtenido;

  @override
  Widget build(BuildContext context) {
    final estilo = CategoriaEstilo.de(lugar.categoriaClave);
    final color = obtenido ? estilo.color : Colors.black26;
    return Semantics(
      label: '${lugar.nombre}: ${obtenido ? tr('sello obtenido') : tr('sello pendiente')}',
      child: Column(
        children: [
          // Sello ganado con foto: la foto del negocio dentro del círculo y un
          // distintivo de "sellado". Sin foto (o si no carga): el ícono.
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 72,
                height: 72,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: obtenido ? estilo.color.withValues(alpha: 0.14) : Colors.transparent,
                  border: Border.all(color: color, width: 2.5),
                ),
                child: obtenido && lugar.fotoUrl != null
                    ? Image.network(
                        lugar.fotoUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Icon(estilo.icono, color: color, size: 32),
                      )
                    : Icon(obtenido ? estilo.icono : Icons.lock_outline, color: color, size: 32),
              ),
              if (obtenido && lugar.fotoUrl != null)
                Positioned(
                  right: -2,
                  bottom: -2,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: estilo.color,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(Icons.approval, size: 14, color: Colors.white),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            lugar.nombre,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12, color: obtenido ? VgColores.tinta : Colors.black45),
          ),
        ],
      ),
    );
  }
}
