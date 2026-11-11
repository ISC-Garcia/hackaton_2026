import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config.dart';
import 'screens/bienvenida_screen.dart';
import 'screens/configuracion_faltante_screen.dart';
import 'screens/principal_screen.dart';
import 'services/preferencias_service.dart';
import 'theme/app_theme.dart';

/// Punto de arranque de VeraGo.
///
/// 1. Prepara Flutter.
/// 2. Si hay claves, conecta con Supabase (una sola vez para toda la app).
/// 3. Revisa si ya se vio la bienvenida (guardado en el celular).
/// 4. Abre la app.
Future<void> main() async {
  // Necesario antes de usar paquetes que hablan con el celular.
  WidgetsFlutterBinding.ensureInitialized();

  if (Config.estaConfigurado) {
    await Supabase.initialize(
      url: Config.supabaseUrl,
      publishableKey: Config.supabaseKey, // clave pública, protegida por RLS
    );
  }

  final mostrarBienvenida = !await PreferenciasService().bienvenidaVista();

  runApp(VeraGoApp(mostrarBienvenida: mostrarBienvenida));
}

class VeraGoApp extends StatelessWidget {
  const VeraGoApp({super.key, required this.mostrarBienvenida});

  /// true solo la primera vez que se abre la app.
  final bool mostrarBienvenida;

  @override
  Widget build(BuildContext context) {
    final Widget inicio;
    if (!Config.estaConfigurado) {
      inicio = const ConfiguracionFaltanteScreen();
    } else if (mostrarBienvenida) {
      inicio = const BienvenidaScreen();
    } else {
      inicio = const PrincipalScreen();
    }

    return MaterialApp(
      title: 'VeraGo',
      debugShowCheckedModeBanner: false,
      theme: VgTema.claro,
      home: inicio,
    );
  }
}
