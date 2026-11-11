import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/error_verago.dart';

/// INICIAR SESIÓN / CREAR CUENTA con correo y contraseña.
///
/// Solo se pide cuando hace falta (para guardar sellos). Explorar, rutas y
/// agenda funcionan sin cuenta.
/// Las validaciones de aquí son comodidad (avisar rápido); la seguridad
/// real la hace Supabase Auth.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _auth = AuthService();
  final _formulario = GlobalKey<FormState>();
  final _nombre = TextEditingController();
  final _correo = TextEditingController();
  final _contrasena = TextEditingController();
  final _confirmar = TextEditingController();

  bool _crearCuenta = false;
  bool _enviando = false;

  /// true = la contraseña se ve como puntos. El botón de ojo lo cambia.
  bool _ocultar = true;

  /// Botón de ojo para ver u ocultar la contraseña.
  Widget get _botonOjo => IconButton(
        tooltip: _ocultar ? 'Mostrar contraseña' : 'Ocultar contraseña',
        icon: Icon(_ocultar ? Icons.visibility_outlined : Icons.visibility_off_outlined),
        onPressed: () => setState(() => _ocultar = !_ocultar),
      );

  @override
  void dispose() {
    _nombre.dispose();
    _correo.dispose();
    _contrasena.dispose();
    _confirmar.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    if (!_formulario.currentState!.validate()) return;
    setState(() => _enviando = true);
    try {
      if (_crearCuenta) {
        final conSesion = await _auth.registrar(_nombre.text, _correo.text, _contrasena.text);
        if (!mounted) return;
        if (!conSesion) {
          _aviso('Te enviamos un correo para confirmar tu cuenta. Después entra aquí.');
          setState(() => _crearCuenta = false);
          return;
        }
      } else {
        await _auth.entrar(_correo.text, _contrasena.text);
      }
      if (mounted) Navigator.of(context).pop(true);
    } on ErrorVeraGo catch (e) {
      _aviso(e.mensaje);
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  void _aviso(String texto) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_crearCuenta ? 'Crear cuenta' : 'Iniciar sesión')),
      body: Form(
        key: _formulario,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text('Con tu cuenta guardamos los sellos de tu pasaporte.'),
            const SizedBox(height: 20),
            if (_crearCuenta) ...[
              TextFormField(
                controller: _nombre,
                decoration: const InputDecoration(labelText: 'Tu nombre', border: OutlineInputBorder()),
                textCapitalization: TextCapitalization.words,
                validator: (v) => (v == null || v.trim().length < 2) ? 'Escribe tu nombre' : null,
              ),
              const SizedBox(height: 12),
            ],
            TextFormField(
              controller: _correo,
              decoration: const InputDecoration(labelText: 'Correo', border: OutlineInputBorder()),
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              validator: (v) => (v == null || !v.contains('@')) ? 'Escribe un correo válido' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _contrasena,
              decoration: InputDecoration(
                labelText: 'Contraseña',
                border: const OutlineInputBorder(),
                suffixIcon: _botonOjo,
              ),
              obscureText: _ocultar,
              validator: (v) => (v == null || v.length < 6) ? 'Mínimo 6 caracteres' : null,
            ),
            // Solo al crear cuenta: escribir la contraseña dos veces evita
            // que alguien se registre con un error de dedo y no pueda entrar.
            if (_crearCuenta) ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: _confirmar,
                decoration: InputDecoration(
                  labelText: 'Confirmar contraseña',
                  border: const OutlineInputBorder(),
                  suffixIcon: _botonOjo,
                ),
                obscureText: _ocultar,
                validator: (v) => v != _contrasena.text ? 'Las contraseñas no coinciden' : null,
              ),
            ],
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _enviando ? null : _enviar,
              child: _enviando
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(_crearCuenta ? 'Crear cuenta' : 'Entrar'),
            ),
            TextButton(
              onPressed: _enviando ? null : () => setState(() => _crearCuenta = !_crearCuenta),
              child: Text(_crearCuenta ? 'Ya tengo cuenta' : 'No tengo cuenta: crear una'),
            ),
          ],
        ),
      ),
    );
  }
}
