import 'package:flutter/material.dart';

import '../i18n/idioma.dart';
import '../screens/principal_screen.dart';
import '../theme/app_theme.dart';

/// BOTÓN DE IDIOMA (🌐): abre una lista con los 5 idiomas.
///
/// Al elegir uno se guarda y la app se vuelve a dibujar en ese idioma:
/// - `alCambiar` (opcional): qué hacer después (ej. la Bienvenida solo se
///   redibuja con setState).
/// - Si no se da, se reabre la pantalla principal para que TODAS las pestañas
///   se dibujen de nuevo en el idioma nuevo.
class BotonIdioma extends StatelessWidget {
  const BotonIdioma({super.key, this.alCambiar, this.conTexto = false});

  final VoidCallback? alCambiar;

  /// true = botón con el nombre del idioma (Bienvenida); false = solo ícono.
  final bool conTexto;

  /// Lista de idiomas. Público para usarlo desde Ajustes.
  static Future<void> elegir(BuildContext context, {VoidCallback? alCambiar}) async {
    final elegido = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        // ListView con shrinkWrap: se desplaza si la pantalla es bajita.
        child: ListView(
          shrinkWrap: true,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(tr('Idioma'), textAlign: TextAlign.center, style: Theme.of(ctx).textTheme.titleLarge),
            ),
            for (final i in Idioma.disponibles.entries)
              ListTile(
                leading: Icon(
                  i.key == Idioma.codigo ? Icons.radio_button_checked : Icons.radio_button_off,
                  color: VgColores.azulGolfo,
                ),
                title: Text(i.value),
                trailing: Text(i.key.toUpperCase(), style: const TextStyle(color: Colors.black45)),
                onTap: () => Navigator.of(ctx).pop(i.key),
              ),
          ],
        ),
      ),
    );
    if (elegido == null || elegido == Idioma.codigo) return;
    await Idioma.cambiar(elegido);
    if (!context.mounted) return;
    if (alCambiar != null) {
      alCambiar();
    } else {
      // Reabre la app desde la pantalla principal, ya en el idioma nuevo.
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const PrincipalScreen()),
        (_) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (conTexto) {
      return TextButton.icon(
        onPressed: () => elegir(context, alCambiar: alCambiar),
        icon: const Icon(Icons.language),
        label: Text(Idioma.disponibles[Idioma.codigo]!),
      );
    }
    return IconButton(
      tooltip: tr('Idioma'),
      icon: const Icon(Icons.language),
      onPressed: () => elegir(context, alCambiar: alCambiar),
    );
  }
}
