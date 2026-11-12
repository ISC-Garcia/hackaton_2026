import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;

import '../config.dart';
import '../i18n/idioma.dart';
import '../models/lugar.dart';

/// "REPORTAR UN PROBLEMA" de un lugar.
///
/// Por qué así: no guardamos reportes en la base de datos (sería otra tabla
/// y otra pantalla de admin). La ventana arma un mensaje con el nombre del
/// lugar y lo copia, para pegarlo en un correo al equipo de VeraGo.
/// `Clipboard` es el portapapeles del celular (copiar y pegar).
/// El reporte copiado va SIEMPRE en español (lo lee el equipo); solo la
/// ventana se muestra en el idioma de la app.
class ReportarProblema {
  static const motivos = [
    'La ubicación está mal',
    'El horario está mal o está cerrado',
    'La información es falsa o engañosa',
    'La foto no corresponde o es inapropiada',
    'El QR no funciona',
    'Otro',
  ];

  /// Texto del reporte (separado para poder probarlo).
  static String mensaje(Lugar lugar, String motivo) =>
      'Reporte para VeraGo\nLugar: ${lugar.nombre}\nId: ${lugar.id}\nProblema: $motivo\nDetalles: ';

  static Future<void> abrir(BuildContext context, Lugar lugar) {
    var motivo = motivos.first;
    return showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialogo) => AlertDialog(
          title: Text(tr('Reportar un problema')),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tr('¿Qué pasa con {lugar}?', {'lugar': lugar.nombre})),
                const SizedBox(height: 8),
                RadioGroup<String>(
                  groupValue: motivo,
                  onChanged: (v) => setStateDialogo(() => motivo = v ?? motivo),
                  child: Column(
                    children: [
                      for (final m in motivos)
                        RadioListTile<String>(
                          value: m,
                          title: Text(tr(m)),
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  Config.correoSoporte.isEmpty
                      ? tr('Copia el reporte y envíalo al equipo de VeraGo.')
                      : tr('Copia el reporte y envíalo a {correo}.', {'correo': Config.correoSoporte}),
                  style: const TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(tr('No guardamos tu reporte en la app.'), style: const TextStyle(fontSize: 12)),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: Text(tr('Cancelar'))),
            FilledButton.icon(
              icon: const Icon(Icons.copy),
              label: Text(tr('Copiar reporte')),
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: mensaje(lugar, motivo)));
                if (!ctx.mounted) return;
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(tr('Reporte copiado. Pégalo en un correo al equipo de VeraGo.'))),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
