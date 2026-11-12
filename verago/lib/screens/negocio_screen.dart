import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show TextInputFormatter;
import 'package:latlong2/latlong.dart';

import '../config.dart';
import '../legal/documentos.dart';
import '../models/lugar.dart';
import '../services/auth_service.dart';
import '../services/error_verago.dart';
import '../services/geocodificacion_service.dart';
import '../services/negocios_service.dart';
import '../services/validaciones.dart';
import '../theme/app_theme.dart';
import '../widgets/estado_vacio.dart';
import '../widgets/selector_ubicacion.dart';
import '../widgets/vg_logo.dart';
import 'documento_screen.dart';
import 'estado_negocio_screen.dart';
import 'negocio_registrado_screen.dart';
import 'panel_comerciante_screen.dart';

/// "SOY UN NEGOCIO": una sola pantalla con dos estados.
///
/// - Estado predeterminado: REGISTRO del negocio (siempre aparece primero).
/// - Estado alternativo: INICIO DE SESIÓN de un negocio ya registrado.
///
/// El cambio entre los dos es un simple `setState(() { _modoLogin = ... })`:
/// no se abre otra pantalla ni se regresa a la bienvenida.
class NegocioScreen extends StatefulWidget {
  const NegocioScreen({super.key});

  @override
  State<NegocioScreen> createState() => _NegocioScreenState();
}

class _NegocioScreenState extends State<NegocioScreen> {
  final _servicio = NegociosService();
  final _auth = AuthService();
  final _formulario = GlobalKey<FormState>();

  // Establecimiento
  final _nombre = TextEditingController();
  final _descripcion = TextEditingController();
  final _direccion = TextEditingController();
  final _telefono = TextEditingController();
  // Encargado
  final _encargado = TextEditingController();
  final _correo = TextEditingController();
  final _contrasena = TextEditingController();
  final _confirmar = TextEditingController();

  bool _modoLogin = false;
  bool _formal = true; // local propio (true) o espacio en Punto VeraGo (false)
  bool _ocultar = true;
  bool _enviando = false;
  bool _faltaUbicacion = false;
  bool _buscandoDireccion = false;

  int? _categoriaId;
  LatLng? _ubicacion;
  String? _puntoId;
  int? _giroId;
  Set<int> _ocupados = {};

  late Future<(List<Lugar>, List<Giro>)> _datos;

  /// Categorías que puede elegir un comercio formal (ids de la tabla categorias).
  static const _categoriasComercio = {
    3: 'Cafetería',
    4: 'Restaurante',
    5: 'Tienda o artesanías',
    7: 'Cultura',
  };

  @override
  void initState() {
    super.initState();
    _datos = _cargarDatos();
    _abrirMiNegocioSiYaTiene();
  }

  /// Correo de la sesión abierta (turista o admin), o null si no hay sesión.
  /// Con sesión NO pedimos otra vez nombre, correo ni contraseña.
  String? get _correoSesion => _auth.usuario?.email;

  /// Si la cuenta con sesión ya tiene negocio (por ejemplo un admin, que no
  /// ve "Panel de mi negocio" en el Pasaporte), abrimos su panel directo.
  Future<void> _abrirMiNegocioSiYaTiene() async {
    if (_auth.usuario == null) return;
    try {
      final negocio = await _servicio.miNegocio();
      if (negocio == null || !mounted) return;
      Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (_) => negocio.estadoAprobacion == 'aprobado'
            ? const PanelComercianteScreen()
            : EstadoNegocioScreen(negocio: negocio),
      ));
    } on ErrorVeraGo {
      // Sin internet: se queda en el formulario; al registrar se revisa otra vez.
    }
  }

  Future<void> _usarOtraCuenta() async {
    await _auth.salir();
    if (mounted) setState(() {});
  }

  Future<(List<Lugar>, List<Giro>)> _cargarDatos() async =>
      (await _servicio.obtenerPuntos(), await _servicio.obtenerGiros());

  @override
  void dispose() {
    for (final c in [
      _nombre, _descripcion, _direccion, _telefono,
      _encargado, _correo, _contrasena, _confirmar,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _elegirPunto(String? id) async {
    setState(() {
      _puntoId = id;
      _giroId = null;
      _ocupados = {};
    });
    if (id == null) return;
    try {
      final ocupados = await _servicio.girosOcupados(id);
      if (mounted) setState(() => _ocupados = ocupados);
    } on ErrorVeraGo catch (e) {
      _aviso('Aviso', e.mensaje);
    }
  }

  /// Al tocar el mapa: guarda el punto y pide su dirección a OpenStreetMap.
  Future<void> _alTocarMapa(LatLng punto) async {
    setState(() {
      _ubicacion = punto;
      _faltaUbicacion = false;
      _buscandoDireccion = true;
    });
    final direccion = await GeocodificacionService().direccionDe(punto);
    if (!mounted || _ubicacion != punto) return; // tocó otro punto mientras tanto
    setState(() {
      _buscandoDireccion = false;
      if (direccion != null) _direccion.text = direccion;
    });
    if (direccion == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('No pudimos obtener la dirección del mapa. Escríbela tú.'),
      ));
    }
  }

  Future<void> _registrar() async {
    final formularioOk = _formulario.currentState!.validate();
    setState(() => _faltaUbicacion = _formal && _ubicacion == null);
    if (!formularioOk || _faltaUbicacion) return;
    // Ventana emergente: aceptar términos antes de enviar (Confirmar / Cancelar).
    if (!await _confirmarTerminos()) return;

    setState(() => _enviando = true);
    try {
      final conSesion = _correoSesion != null;
      await _servicio.registrar(
        nombreEncargado: conSesion ? null : _encargado.text,
        correo: conSesion ? null : _correo.text,
        contrasena: conSesion ? null : _contrasena.text,
        s: SolicitudNegocio(
          formal: _formal,
          nombre: _nombre.text,
          descripcion: _descripcion.text,
          telefono: _telefono.text,
          categoriaId: _formal ? _categoriaId : null,
          direccion: _formal ? _direccion.text : null,
          latitud: _formal ? _ubicacion!.latitude : null,
          longitud: _formal ? _ubicacion!.longitude : null,
          puntoId: _formal ? null : _puntoId,
          giroId: _formal ? null : _giroId,
        ),
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const NegocioRegistradoScreen()),
      );
    } on ErrorVeraGo catch (e) {
      await _aviso('No pudimos registrar tu negocio', e.mensaje);
      // Si el giro se ocupó mientras llenaba el formulario, refrescamos.
      if (!_formal && _puntoId != null) _elegirPunto(_puntoId);
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  /// Ventana "Confirmar / Cancelar" con los términos para negocios.
  /// Devuelve true solo si toca "Confirmar".
  Future<bool> _confirmarTerminos() async {
    final acepto = await showDialog<bool>(
      context: context,
      barrierDismissible: false, // hay que elegir Confirmar o Cancelar
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar registro'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Vas a registrar "${_nombre.text.trim()}" en VeraGo.'),
              const SizedBox(height: 10),
              const Text(
                'Al confirmar, declaras que los datos son verdaderos y aceptas los Términos para '
                'negocios, las Reglas operativas y el Aviso de privacidad de VeraGo.',
              ),
              const SizedBox(height: 10),
              const Text(
                'Tu solicitud quedará pendiente hasta que el equipo de VeraGo la revise.',
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 4),
              for (final d in const [Documentos.terminosNegocios, Documentos.reglasOperativas, Documentos.avisoPrivacidad])
                TextButton(
                  style: TextButton.styleFrom(padding: EdgeInsets.zero, alignment: Alignment.centerLeft),
                  onPressed: () => DocumentoScreen.abrir(ctx, d),
                  child: Text('Leer ${d.titulo}'),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Confirmar')),
        ],
      ),
    );
    return acepto == true;
  }

  Future<void> _entrar() async {
    if (!_formulario.currentState!.validate()) return;
    setState(() => _enviando = true);
    try {
      await _auth.entrar(_correo.text, _contrasena.text);
      final negocio = await _servicio.miNegocio();
      if (!mounted) return;
      if (negocio == null) {
        await _aviso(
          'Sin negocio registrado',
          'Esta cuenta no tiene un negocio en VeraGo. Regístralo con el formulario '
              '"Registrar mi negocio" usando otro correo, o escríbenos.',
        );
        return;
      }
      // Aprobado → panel. Pendiente, rechazado o suspendido → estado.
      Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (_) => negocio.estadoAprobacion == 'aprobado'
            ? const PanelComercianteScreen()
            : EstadoNegocioScreen(negocio: negocio),
      ));
    } on ErrorVeraGo catch (e) {
      await _aviso('No pudimos entrar', e.mensaje);
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  void _olvideContrasena() {
    final correo = Config.correoSoporte;
    _aviso(
      'Recuperar contraseña',
      correo.isEmpty
          ? 'Contacta al equipo de VeraGo y te ayudamos a recuperar el acceso a tu comercio.'
          : 'Escríbenos a $correo desde el correo de tu cuenta y te ayudamos a recuperar '
              'el acceso a tu comercio.',
    );
  }

  Future<void> _aviso(String titulo, String texto) async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(titulo),
        content: Text(texto),
        actions: [
          FilledButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Entendido')),
        ],
      ),
    );
  }

  /// Cambia entre registro e inicio de sesión sin salir de esta pantalla.
  void _cambiarModo() => setState(() {
        _modoLogin = !_modoLogin;
        _formulario.currentState?.reset();
      });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Soy un negocio'),
        leading: IconButton(
          tooltip: 'Volver a VeraGo',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Form(
        key: _formulario,
        child: _modoLogin ? _vistaLogin() : _vistaRegistro(),
      ),
    );
  }

  // ------------------------------------------------------------------
  // ESTADO PREDETERMINADO: REGISTRO
  // ------------------------------------------------------------------
  Widget _vistaRegistro() {
    return FutureBuilder<(List<Lugar>, List<Giro>)>(
      future: _datos,
      builder: (context, snapshot) {
        final encabezado = [
          const Center(child: VgLogo(altura: 110)),
          const SizedBox(height: 12),
          Text('¡Forma parte de VeraGo!', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 6),
          const Text(
            'Registra tu establecimiento y conecta tu negocio con los turistas que visitan Veracruz.',
            style: TextStyle(fontSize: 16, height: 1.4),
          ),
        ];
        // Mientras carga o si falla, el título y "Iniciar sesión" siguen visibles.
        if (snapshot.connectionState != ConnectionState.done || snapshot.hasError) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
            children: [
              ...encabezado,
              const SizedBox(height: 24),
              if (snapshot.hasError)
                EstadoVacio(
                  icono: Icons.wifi_off,
                  titulo: 'No pudimos cargar el formulario',
                  mensaje: snapshot.error.toString(),
                  textoBoton: 'Reintentar',
                  alPresionar: () => setState(() {
                    _datos = _cargarDatos()..ignore();
                  }),
                )
              else
                const Center(child: CircularProgressIndicator()),
              ..._pieLogin(),
            ],
          );
        }
        final (puntos, giros) = snapshot.data!;
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
          children: [
            ...encabezado,
            const _Seccion('Información del establecimiento'),
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: true, icon: Icon(Icons.store), label: Text('Local propio')),
                ButtonSegment(value: false, icon: Icon(Icons.storefront_outlined), label: Text('Punto VeraGo')),
              ],
              selected: {_formal},
              onSelectionChanged: (s) => setState(() => _formal = s.first),
            ),
            const SizedBox(height: 6),
            Text(
              _formal
                  ? 'Tienes tu propio local en el centro.'
                  : 'Quieres una mesa en un Punto VeraGo. Solo hay un negocio por giro en cada punto.',
              style: TextStyle(fontSize: 13, color: Colors.black.withValues(alpha: 0.65)),
            ),
            const SizedBox(height: 16),
            _campo(_nombre, 'Nombre comercial', Validaciones.obligatorio('el nombre comercial')),
            if (_formal)
              DropdownButtonFormField<int>(
                initialValue: _categoriaId,
                decoration: _decoracion('Categoría del establecimiento'),
                items: [
                  for (final c in _categoriasComercio.entries)
                    DropdownMenuItem(value: c.key, child: Text(c.value)),
                ],
                onChanged: (v) => setState(() => _categoriaId = v),
                validator: (v) => v == null ? 'Elige una categoría' : null,
              )
            else ...[
              DropdownButtonFormField<String>(
                initialValue: _puntoId,
                decoration: _decoracion('Punto VeraGo'),
                items: [
                  for (final p in puntos) DropdownMenuItem(value: p.id, child: Text(p.nombre)),
                ],
                onChanged: _elegirPunto,
                validator: (v) => v == null ? 'Elige un punto' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                key: ValueKey('giro-$_puntoId'), // se reinicia al cambiar de punto
                initialValue: _giroId,
                decoration: _decoracion('Giro del negocio'),
                items: [
                  for (final g in giros)
                    DropdownMenuItem(
                      value: g.id,
                      enabled: !_ocupados.contains(g.id),
                      child: Text(_ocupados.contains(g.id) ? '${g.nombre} (ocupado)' : g.nombre),
                    ),
                ],
                onChanged: (v) => setState(() => _giroId = v),
                validator: (v) => v == null ? 'Elige un giro disponible' : null,
              ),
            ],
            const SizedBox(height: 12),
            _campo(_descripcion, 'Descripción breve', Validaciones.obligatorio('una descripción', minimo: 10),
                maxLength: 160, lineas: 2),
            if (_formal) ...[
              // Primero el mapa: la dirección se llena sola a partir del punto,
              // así siempre coinciden.
              const Text('1. Toca el mapa para marcar dónde está tu local:',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              SelectorUbicacion(valor: _ubicacion, alCambiar: _alTocarMapa),
              if (_faltaUbicacion)
                const Padding(
                  padding: EdgeInsets.only(top: 6),
                  child: Text('Marca la ubicación de tu local en el mapa',
                      style: TextStyle(color: Color(0xFF9B2C2C))),
                ),
              const SizedBox(height: 12),
              const Text('2. Revisa la dirección (se llena sola con el mapa):',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: TextFormField(
                  controller: _direccion,
                  validator: Validaciones.obligatorio('la dirección', minimo: 5),
                  decoration: _decoracion(
                    'Dirección',
                    ayuda: _buscandoDireccion
                        ? 'Buscando la dirección del punto…'
                        : 'Puedes ajustarla: número, referencias…',
                    sufijo: _buscandoDireccion
                        ? const Padding(padding: EdgeInsets.all(14), child: _Cargando(oscuro: true))
                        : null,
                  ),
                ),
              ),
            ],
            _campo(_telefono, 'Teléfono de contacto (10 números)', Validaciones.telefono,
                teclado: TextInputType.phone, maxLength: 10, formateadores: Validaciones.soloDiezDigitos),
            const _Seccion('Información del encargado'),
            if (_correoSesion case final correo?)
              // Ya hay sesión: el negocio se liga a esta cuenta.
              Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: const Icon(Icons.verified_user_outlined, color: VgColores.azulGolfo),
                  title: const Text('Se registrará con tu cuenta'),
                  subtitle: Text('$correo\nNo necesitas escribir tus datos ni tu contraseña.'),
                  isThreeLine: true,
                  trailing: TextButton(
                    onPressed: _enviando ? null : _usarOtraCuenta,
                    child: const Text('Usar otra'),
                  ),
                ),
              )
            else ...[
              _campo(_encargado, 'Nombre completo del propietario o encargado',
                  Validaciones.obligatorio('el nombre completo', minimo: 3)),
              _campo(_correo, 'Correo electrónico', Validaciones.correo, teclado: TextInputType.emailAddress),
              _campoContrasena(_contrasena, 'Contraseña', Validaciones.contrasenaSegura,
                  ayuda: 'Mínimo 8 caracteres, con letras y números'),
              _campoContrasena(_confirmar, 'Confirmar contraseña',
                  (v) => v != _contrasena.text ? 'Las contraseñas no coinciden' : null),
            ],
            const SizedBox(height: 8),
            FilledButton(
              onPressed: _enviando ? null : _registrar,
              child: _enviando ? const _Cargando() : const Text('Registrar mi negocio'),
            ),
            if (_correoSesion == null) ..._pieLogin(),
          ],
        );
      },
    );
  }

  /// "¿Tu negocio ya está registrado? Iniciar sesión"
  List<Widget> _pieLogin() => [
        const SizedBox(height: 20),
        const Center(child: Text('¿Tu negocio ya está registrado?')),
        Center(
          child: TextButton(onPressed: _enviando ? null : _cambiarModo, child: const Text('Iniciar sesión')),
        ),
      ];

  // ------------------------------------------------------------------
  // ESTADO ALTERNATIVO: INICIO DE SESIÓN
  // ------------------------------------------------------------------
  Widget _vistaLogin() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
      children: [
        Text('Entra a tu comercio', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 6),
        const Text('Consulta el estado de tu solicitud o administra tu negocio.',
            style: TextStyle(fontSize: 16, height: 1.4)),
        const SizedBox(height: 20),
        _campo(_correo, 'Correo electrónico', Validaciones.correo, teclado: TextInputType.emailAddress),
        _campoContrasena(_contrasena, 'Contraseña',
            (v) => (v ?? '').isEmpty ? 'Escribe tu contraseña' : null),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(onPressed: _olvideContrasena, child: const Text('¿Olvidaste tu contraseña?')),
        ),
        FilledButton(
          onPressed: _enviando ? null : _entrar,
          child: _enviando ? const _Cargando() : const Text('Entrar a mi comercio'),
        ),
        const SizedBox(height: 20),
        const Center(child: Text('¿Aún no registras tu negocio?')),
        Center(
          child: TextButton(onPressed: _enviando ? null : _cambiarModo, child: const Text('Registrar mi negocio')),
        ),
      ],
    );
  }

  // ------------------------------------------------------------------
  // Piezas del formulario
  // ------------------------------------------------------------------
  InputDecoration _decoracion(String etiqueta, {String? ayuda, Widget? sufijo}) => InputDecoration(
        labelText: etiqueta,
        helperText: ayuda,
        border: const OutlineInputBorder(),
        filled: true,
        fillColor: Colors.white,
        suffixIcon: sufijo,
      );

  Widget _campo(
    TextEditingController c,
    String etiqueta,
    String? Function(String?) validador, {
    TextInputType? teclado,
    int? maxLength,
    int lineas = 1,
    List<TextInputFormatter>? formateadores,
  }) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextFormField(
          controller: c,
          decoration: _decoracion(etiqueta),
          validator: validador,
          keyboardType: teclado,
          inputFormatters: formateadores,
          maxLength: maxLength,
          maxLines: lineas,
        ),
      );

  Widget _campoContrasena(
    TextEditingController c,
    String etiqueta,
    String? Function(String?) validador, {
    String? ayuda,
  }) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextFormField(
          controller: c,
          obscureText: _ocultar,
          validator: validador,
          decoration: _decoracion(
            etiqueta,
            ayuda: ayuda,
            sufijo: IconButton(
              tooltip: _ocultar ? 'Mostrar contraseña' : 'Ocultar contraseña',
              icon: Icon(_ocultar ? Icons.visibility_outlined : Icons.visibility_off_outlined),
              onPressed: () => setState(() => _ocultar = !_ocultar),
            ),
          ),
        ),
      );
}

class _Seccion extends StatelessWidget {
  const _Seccion(this.texto);
  final String texto;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 24, bottom: 12),
        child: Text(texto, style: Theme.of(context).textTheme.titleLarge),
      );
}

class _Cargando extends StatelessWidget {
  const _Cargando({this.oscuro = false});

  /// true = sobre fondo claro (dentro de un campo).
  final bool oscuro;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: oscuro ? VgColores.azulGolfo : VgColores.arena,
        ),
      );
}
