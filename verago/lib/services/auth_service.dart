import 'package:supabase_flutter/supabase_flutter.dart';

import 'error_verago.dart';

/// SERVICIO de cuentas (Supabase Auth): registrarse, entrar y salir.
///
/// Supabase guarda la sesión en el celular y la renueva sola, así que el
/// visitante no tiene que volver a entrar cada vez que abre la app.
class AuthService {
  GoTrueClient get _auth => Supabase.instance.client.auth;

  /// Usuario con sesión abierta, o null si es invitado.
  /// (El try/catch evita fallar si Supabase no está configurado, por
  /// ejemplo en las pruebas automáticas).
  User? get usuario {
    try {
      return _auth.currentUser;
    } catch (_) {
      return null;
    }
  }

  /// Avisa cada vez que alguien entra o sale (para redibujar pantallas).
  Stream<AuthState> get cambios {
    try {
      return _auth.onAuthStateChange;
    } catch (_) {
      return const Stream.empty();
    }
  }

  Future<void> entrar(String correo, String contrasena) async {
    try {
      await _auth.signInWithPassword(email: correo.trim(), password: contrasena);
    } on AuthException catch (e) {
      throw ErrorVeraGo(_mensaje(e));
    } catch (_) {
      throw const ErrorVeraGo('Revisa tu conexión a internet e intenta de nuevo.');
    }
  }

  /// Crea la cuenta. El nombre viaja como "metadato" y el trigger
  /// `crear_perfil` (archivo 001 del SQL) lo guarda en la tabla perfiles.
  /// Devuelve true si ya quedó con sesión; false si Supabase pide confirmar
  /// el correo primero.
  Future<bool> registrar(String nombre, String correo, String contrasena) async {
    try {
      final r = await _auth.signUp(
        email: correo.trim(),
        password: contrasena,
        data: {'nombre': nombre.trim()},
      );
      return r.session != null;
    } on AuthException catch (e) {
      throw ErrorVeraGo(_mensaje(e));
    } catch (_) {
      throw const ErrorVeraGo('Revisa tu conexión a internet e intenta de nuevo.');
    }
  }

  Future<void> salir() => _auth.signOut();

  /// Traduce los errores de Supabase Auth a mensajes claros.
  String _mensaje(AuthException e) {
    final m = e.message.toLowerCase();
    if (m.contains('invalid login')) return 'Correo o contraseña incorrectos.';
    if (m.contains('already registered')) return 'Ese correo ya tiene cuenta. Entra con tu contraseña.';
    if (m.contains('not confirmed')) {
      return 'Tu correo aún no está confirmado. Abre el enlace que te enviamos '
          'o pide al administrador que confirme tu cuenta.';
    }
    if (m.contains('rate limit')) {
      return 'Se enviaron demasiados correos. Espera unos minutos o pide al '
          'administrador que confirme tu cuenta.';
    }
    if (m.contains('password')) return 'La contraseña debe tener al menos 6 caracteres.';
    return 'No pudimos completar la operación. Intenta de nuevo.';
  }
}
