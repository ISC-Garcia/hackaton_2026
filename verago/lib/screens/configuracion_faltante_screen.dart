import 'package:flutter/material.dart';

import '../widgets/estado_vacio.dart';

/// Se muestra si la app se ejecutó sin las claves de Supabase.
/// Por qué: en lugar de fallar con un error raro, explica qué hacer.
class ConfiguracionFaltanteScreen extends StatelessWidget {
  const ConfiguracionFaltanteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(
        child: EstadoVacio(
          icono: Icons.settings_outlined,
          titulo: 'Falta configurar Supabase',
          mensaje: 'Llena SUPABASE_URL y SUPABASE_KEY en env.json y ejecuta:\n\n'
              'flutter run --dart-define-from-file=env.json',
        ),
      ),
    );
  }
}
