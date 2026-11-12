import 'package:flutter/material.dart';

import '../i18n/idioma.dart';
import '../theme/app_theme.dart';

/// CONFIRMACIÓN: se muestra después de registrar el negocio.
/// El negocio queda "pendiente" hasta que el equipo de VeraGo lo apruebe.
class NegocioRegistradoScreen extends StatelessWidget {
  const NegocioRegistradoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Column(
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: VgColores.verdePalma.withValues(alpha: 0.14),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_circle, size: 72, color: VgColores.verdePalma),
                ),
                const SizedBox(height: 24),
                Text(
                  tr('¡Tu negocio se ha registrado correctamente!'),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 12),
                Text(
                  tr('Tu solicitud está pendiente. Por favor espera mientras un administrador de VeraGo la revisa. Te contactaremos por teléfono o correo cuando sea aprobada.'),
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, height: 1.4),
                ),
                const SizedBox(height: 8),
                Text(
                  tr('También puedes revisar el estado entrando con tu cuenta en "Soy un negocio".'),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black.withValues(alpha: 0.6)),
                ),
                const SizedBox(height: 28),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(tr('Volver a VeraGo')),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
