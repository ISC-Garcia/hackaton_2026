import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;

import '../config.dart';
import '../models/lugar.dart';

/// "REPORTAR UN PROBLEMA" de un lugar.
///
/// Por qué así: no guardamos reportes en la base de datos (sería otra tabla
/// y otra pantalla de admin). La ventana arma un mensaje con el nombre del
/// lugar y lo copia, para pegarlo en un correo al equipo de VeraGo.
/// `Clipboard` es el portapapeles del celular (copiar y pegar).
class ReportarProblema {
  static const motivos = [
    'La ubicación está mal',
    'El horario está mal o está cerrado',
    'La información es falsa o engañosa',
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
          title: const Text('Reportar un problema'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('¿Qué pasa con ${lugar.nombre}?'),
                const SizedBox(height: 8),
                RadioGroup<String>(
                  groupValue: motivo,
                  onChanged: (v) => setStateDialogo(() => motivo = v ?? motivo),
                  child: Column(
                    children: [
                      for (final m in motivos)
                        RadioListTile<String>(
                          value: m,
                          title: Text(m),
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  Config.correoSoporte.isEmpty
                      ? 'Copia el reporte y envíalo al equipo de VeraGo.'
                      : 'Copia el reporte y envíalo a ${Config.correoSoporte}.',
                  style: const TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 4),
                const Text('No guardamos tu reporte en la app.', style: TextStyle(fontSize: 12)),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancelar')),
            FilledButton.icon(
              icon: const Icon(Icons.copy),
              label: const Text('Copiar reporte'),
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: mensaje(lugar, motivo)));
                if (!ctx.mounted) return;
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Reporte copiado. Pégalo en un correo al equipo de VeraGo.')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
