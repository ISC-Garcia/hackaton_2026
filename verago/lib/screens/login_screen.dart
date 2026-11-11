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

  bool _crearCuenta = false;
  bool _enviando = false;

  @override
  void dispose() {
    _nombre.dispose();
    _correo.dispose();
    _contrasena.dispose();
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
              decoration: const InputDecoration(labelText: 'Contraseña', border: OutlineInputBorder()),
              obscureText: true,
              validator: (v) => (v == null || v.length < 6) ? 'Mínimo 6 caracteres' : null,
            ),
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
