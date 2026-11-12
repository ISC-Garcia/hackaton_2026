import 'package:flutter/material.dart';

import '../i18n/idioma.dart';
import '../legal/documentos.dart';
import '../models/sello.dart';
import '../services/auth_service.dart';
import '../services/error_verago.dart';
import '../services/pasaporte_service.dart';
import '../services/preferencias_service.dart';
import '../services/validaciones.dart';
import '../theme/app_theme.dart';
import '../widgets/boton_idioma.dart';
import '../widgets/categoria_estilo.dart';
import 'bienvenida_screen.dart';
import 'documento_screen.dart';
import 'negocio_screen.dart';

/// AJUSTES del usuario (se abre con el engrane del Pasaporte).
///
/// Secciones:
/// 1. Mi cuenta: correo, rol y cambiar nombre (solo con sesión).
/// 2. Mis intereses: los que se marcan solos en Rutas (se guardan en el celular).
/// 3. Ver la bienvenida otra vez.
/// 4. Privacidad: qué datos guardamos y cerrar sesión.
/// 5. Legal y confianza: aviso de privacidad, términos y reglas.
///
/// Devuelve `true` al cerrarse si cambió algo que el Pasaporte debe recargar.
class AjustesScreen extends StatefulWidget {
  const AjustesScreen({super.key, this.perfil});

  /// Perfil del usuario con sesión; null si es invitado.
  final Perfil? perfil;

  @override
  State<AjustesScreen> createState() => _AjustesScreenState();
}

class _AjustesScreenState extends State<AjustesScreen> {
  final _pasaporte = PasaporteService();
  final _prefs = PreferenciasService();
  final _auth = AuthService();
  late final TextEditingController _nombre;

  Set<String> _intereses = {};
  bool _guardandoNombre = false;
  bool _huboCambios = false;

  @override
  void initState() {
    super.initState();
    _nombre = TextEditingController(text: widget.perfil?.nombre ?? '');
    _prefs.leerIntereses().then((i) {
      if (mounted) setState(() => _intereses = i);
    });
  }

  @override
  void dispose() {
    _nombre.dispose();
    super.dispose();
  }

  void _mensaje(String texto) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));

  Future<void> _guardarNombre() async {
    final nombre = _nombre.text.trim();
    final error = Validaciones.nombrePersona()(nombre);
    if (error != null) {
      _mensaje(tr(error));
      return;
    }
    setState(() => _guardandoNombre = true);
    try {
      await _pasaporte.cambiarNombre(nombre);
      _huboCambios = true;
      _mensaje(tr('Nombre guardado.'));
    } on ErrorVeraGo catch (e) {
      _mensaje(tr(e.mensaje));
    } finally {
      if (mounted) setState(() => _guardandoNombre = false);
    }
  }

  Future<void> _cambiarInteres(String clave, bool elegido) async {
    setState(() {
      _intereses = {..._intereses};
      elegido ? _intereses.add(clave) : _intereses.remove(clave);
    });
    await _prefs.guardarIntereses(_intereses);
  }

  void _verBienvenida() {
    // Borra todas las pantallas abiertas y muestra la bienvenida desde cero.
    // Al terminarla, la bienvenida abre la app normal.
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const BienvenidaScreen()),
      (_) => false,
    );
  }

  /// Borrar la cuenta: ventana de confirmación clara (no se puede deshacer).
  Future<void> _borrarCuenta() async {
    final seguro = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.delete_forever_outlined, color: Color(0xFF9B2C2C), size: 40),
        title: Text(tr('¿Borrar tu cuenta para siempre?')),
        content: Text(
          tr('Se borran tu cuenta, tu nombre y todos tus sellos. Si tienes un negocio: si aún no se aprobaba, se borra; si ya estaba en la app, se oculta.\n\nEsto no se puede deshacer.'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text(tr('Cancelar'))),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF9B2C2C)),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(tr('Borrar para siempre')),
          ),
        ],
      ),
    );
    if (seguro != true || !mounted) return;
    final error = await _pasaporte.borrarMiCuenta();
    if (!mounted) return;
    if (error != null) {
      _mensaje(tr(error));
      return;
    }
    // La cuenta ya no existe: cerramos la sesión guardada en el celular.
    try {
      await _auth.salir();
    } catch (_) {}
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('Tu cuenta se borró.'))));
    Navigator.of(context).pop(true);
  }

  Future<void> _cerrarSesion() async {
    await _auth.salir();
    if (mounted) Navigator.of(context).pop(true);
  }

  static String _nombreRol(String rol) => switch (rol) {
        'comerciante' => tr('Comerciante'),
        'admin' => tr('Administrador'),
        _ => tr('Visitante'),
      };

  @override
  Widget build(BuildContext context) {
    final perfil = widget.perfil;
    return PopScope(
      // Al regresar con el botón atrás, avisamos al Pasaporte si hubo cambios.
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.of(context).pop(_huboCambios);
      },
      child: Scaffold(
        appBar: AppBar(title: Text(tr('Ajustes'))),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
          children: [
            // 0. Idioma (visitantes que no hablan español). Al cambiarlo se
            // reabre la app en la pantalla principal, ya traducida.
            const _Titulo('Idioma'),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.language, color: VgColores.azulGolfo),
              title: Text(Idioma.disponibles[Idioma.codigo]!),
              subtitle: const Text('Español · English · Français · Deutsch · Português'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => BotonIdioma.elegir(context),
            ),
            // 1. Mi cuenta
            if (perfil != null) ...[
              const _Titulo('Mi cuenta'),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Dato(icono: Icons.mail_outline, texto: _pasaporte.miCorreo ?? '—'),
                      _Dato(icono: Icons.badge_outlined, texto: tr('Rol: {rol}', {'rol': _nombreRol(perfil.rol)})),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _nombre,
                        textCapitalization: TextCapitalization.words,
                        inputFormatters: Validaciones.nombrePersonaFormato, // sin números
                        decoration: InputDecoration(
                          labelText: tr('Mi nombre'),
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: FilledButton(
                          onPressed: _guardandoNombre ? null : _guardarNombre,
                          child: Text(_guardandoNombre ? tr('Guardando…') : tr('Guardar nombre')),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // 2. Mis intereses
            const _Titulo('Mis intereses'),
            Text(tr('Se marcan solos al pedir una ruta. Se guardan en este celular.')),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final c in CategoriaEstilo.nombres.entries)
                  FilterChip(
                    avatar: Icon(CategoriaEstilo.de(c.key).icono, size: 18),
                    label: Text(tr(c.value)),
                    selected: _intereses.contains(c.key),
                    onSelected: (sel) => _cambiarInteres(c.key, sel),
                  ),
              ],
            ),

            // Acceso para comerciantes
            const _Titulo('¿Tienes un negocio?'),
            OutlinedButton.icon(
              onPressed: () async {
                await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NegocioScreen()));
                // Al volver al Pasaporte, que se recargue (pudo cambiar el rol).
                _huboCambios = true;
              },
              icon: const Icon(Icons.storefront_outlined),
              label: Text(tr('Soy un negocio')),
            ),

            // 3. Bienvenida
            const _Titulo('Guía de la app'),
            OutlinedButton.icon(
              onPressed: _verBienvenida,
              icon: const Icon(Icons.replay),
              label: Text(tr('Ver la guía de la app otra vez')),
            ),

            // 4. Privacidad
            const _Titulo('Privacidad'),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: VgColores.azulGolfo.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tr('Qué guardamos'), style: const TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(tr('• Tu correo y tu nombre.\n• Los sellos que ganas (lugar y fecha).')),
                  const SizedBox(height: 10),
                  Text(tr('Qué NO guardamos'), style: const TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(tr('• Tu ubicación: se usa en tu celular para el mapa (si das permiso). Solo el inicio de una ruta desde "Mi ubicación" se envía para dibujar el camino.\n• No te seguimos en segundo plano.')),
                  const SizedBox(height: 10),
                  Text(tr('Tus intereses y tu idioma se guardan solo en este celular.')),
                ],
              ),
            ),
            // 5. Legal y confianza
            const _Titulo('Legal y confianza'),
            for (final d in Documentos.todos)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.description_outlined, color: VgColores.azulGolfo),
                title: Text(tr(d.titulo)),
                subtitle: Text(tr(d.resumen)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => DocumentoScreen.abrir(context, d),
              ),
            if (perfil != null) ...[
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: _cerrarSesion,
                style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF9B2C2C)),
                icon: const Icon(Icons.logout),
                label: Text(tr('Cerrar sesión')),
              ),
              const SizedBox(height: 8),
              if (perfil.esAdmin)
                Text(tr('Una cuenta de administrador no se borra desde la app.'),
                    style: const TextStyle(fontSize: 12), textAlign: TextAlign.center)
              else
                TextButton.icon(
                  onPressed: _borrarCuenta,
                  style: TextButton.styleFrom(foregroundColor: const Color(0xFF9B2C2C)),
                  icon: const Icon(Icons.delete_forever_outlined),
                  label: Text(tr('Borrar mi cuenta')),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Titulo extends StatelessWidget {
  const _Titulo(this.texto);
  final String texto;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 24, bottom: 10),
        child: Text(tr(texto), style: Theme.of(context).textTheme.titleLarge),
      );
}

class _Dato extends StatelessWidget {
  const _Dato({required this.icono, required this.texto});
  final IconData icono;
  final String texto;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(icono, size: 20, color: VgColores.azulGolfo),
            const SizedBox(width: 10),
            Expanded(child: Text(texto)),
          ],
        ),
      );
}
