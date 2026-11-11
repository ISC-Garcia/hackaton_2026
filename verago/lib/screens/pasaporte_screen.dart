import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthState;

import '../models/lugar.dart';
import '../models/sello.dart';
import '../services/auth_service.dart';
import '../services/lugares_service.dart';
import '../services/pasaporte_service.dart';
import '../theme/app_theme.dart';
import '../widgets/categoria_estilo.dart';
import '../widgets/estado_vacio.dart';
import 'ajustes_screen.dart';
import 'escanear_screen.dart';
import 'estadisticas_screen.dart';
import 'login_screen.dart';
import 'qr_comercio_screen.dart';

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
      setState(() => _futuro = _auth.usuario != null ? _cargar() : null);
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
      setState(() => _futuro = _conSesion ? _cargar() : null);
    }
  }

  void _recargar() => setState(() => _futuro = _cargar());

  Future<void> _iniciarSesion() async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LoginScreen()));
    // Al regresar del login, volvemos a revisar la sesión y cargamos los
    // datos. No dependemos solo del aviso de Supabase (más seguro).
    if (!mounted) return;
    setState(() => _futuro = _conSesion ? _cargar() : null);
  }

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
        title: const Text('Pasaporte'),
        actions: [
          IconButton(
            tooltip: 'Ajustes',
            icon: const Icon(Icons.settings_outlined),
            onPressed: _abrirAjustes,
          ),
        ],
      ),
      body: !conSesion
          ? EstadoVacio(
              icono: Icons.approval_outlined,
              titulo: 'Tu pasaporte VeraGo',
              mensaje: 'Escanea el QR de los comercios participantes y colecciona sus sellos. '
                  'Necesitas una cuenta para guardarlos.',
              textoBoton: 'Iniciar sesión',
              alPresionar: _iniciarSesion,
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
                    titulo: 'Algo salió mal',
                    mensaje: snapshot.error.toString(),
                    textoBoton: 'Reintentar',
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
                Text('Hola, ${d.perfil.nombre}',
                    style: const TextStyle(color: Colors.white, fontSize: 18)),
                const SizedBox(height: 8),
                Text(
                  '$logrados de ${participantes.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'serif',
                    fontFamilyFallback: ['Georgia'],
                  ),
                ),
                const Text('comercios sellados en tu pasaporte',
                    style: TextStyle(color: Colors.white70)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => _escanear(d),
            icon: const Icon(Icons.qr_code_scanner),
            label: const Text('Escanear QR'),
          ),
          if (d.perfil.esComerciante) ...[
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => Navigator.of(context)
                  .push(MaterialPageRoute(builder: (_) => const QrComercioScreen())),
              icon: const Icon(Icons.qr_code_2),
              label: const Text('Mostrar el QR de mi comercio'),
            ),
          ],
          if (d.perfil.esAdmin) ...[
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => Navigator.of(context)
                  .push(MaterialPageRoute(builder: (_) => const EstadisticasScreen())),
              icon: const Icon(Icons.bar_chart),
              label: const Text('Estadísticas (datos simulados)'),
            ),
          ],
          const SizedBox(height: 24),
          Text('Tu colección', style: Theme.of(context).textTheme.titleLarge),
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
          Text('Historial', style: Theme.of(context).textTheme.titleLarge),
          if (d.sellos.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text('Aún no tienes sellos. Visita un comercio participante y escanea su QR.'),
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
      label: '${lugar.nombre}: ${obtenido ? 'sello obtenido' : 'sello pendiente'}',
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: obtenido ? estilo.color.withValues(alpha: 0.14) : Colors.transparent,
              border: Border.all(color: color, width: 2.5),
            ),
            child: Icon(obtenido ? estilo.icono : Icons.lock_outline, color: color, size: 32),
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
