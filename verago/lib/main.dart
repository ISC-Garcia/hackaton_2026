import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config.dart';
import 'screens/configuracion_faltante_screen.dart';
import 'screens/principal_screen.dart';
import 'theme/app_theme.dart';

/// Punto de arranque de VeraGo.
///
/// 1. Prepara Flutter.
/// 2. Si hay claves, conecta con Supabase (una sola vez para toda la app).
/// 3. Abre la app.
Future<void> main() async {
  // Necesario antes de usar paquetes que hablan con el celular.
  WidgetsFlutterBinding.ensureInitialized();

  if (Config.estaConfigurado) {
    await Supabase.initialize(
      url: Config.supabaseUrl,
      publishableKey: Config.supabaseKey, // clave pública, protegida por RLS
    );
  }

  runApp(const VeraGoApp());
}

class VeraGoApp extends StatelessWidget {
  const VeraGoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VeraGo',
      debugShowCheckedModeBanner: false,
      theme: VgTema.claro,
      home: Config.estaConfigurado
          ? const PrincipalScreen()
          : const ConfiguracionFaltanteScreen(),
    );
  }
}
