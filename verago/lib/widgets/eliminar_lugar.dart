import 'package:flutter/material.dart';

import '../i18n/idioma.dart';
import '../models/lugar.dart';
import '../services/eliminar_service.dart';
import '../services/error_verago.dart';

/// FLUJO PARA ELIMINAR un lugar, Punto VeraGo o negocio (admin o comerciante).
///
/// 1. Pregunta a la base de datos si se puede.
/// 2. Punto con negocios → explica que primero hay que vaciarlo.
///    Con sellos → explica por qué no y ofrece OCULTARLO.
///    Se puede → confirmación clara ("para siempre") y elimina.
///
/// Devuelve true si se eliminó o se ocultó (para recargar la pantalla).
class EliminarLugar {
  static Future<bool> ejecutar(
    BuildContext context,
    Lugar lugar, {
    required Future<void> Function() ocultar,
    EliminarService? servicio,
  }) async {
    final s = servicio ?? EliminarService();
    final avisos = ScaffoldMessenger.of(context);
    final RevisionEliminar r;
    try {
      r = await s.revisar(lugar.id);
    } on ErrorVeraGo catch (e) {
      avisos.showSnackBar(SnackBar(content: Text(e.mensaje)));
      return false;
    }
    if (!context.mounted) return false;

    if (r.estado == 'TIENE_NEGOCIOS') {
      await _aviso(
        context,
        tr('No se puede eliminar todavía'),
        r.negocios == 1
            ? tr('"{nombre}" tiene 1 negocio dentro. Cámbialo de Punto VeraGo o elimínalo primero, para que no se quede sin punto.',
                {'nombre': lugar.nombre})
            : tr('"{nombre}" tiene {n} negocios dentro. Cámbialos de Punto VeraGo o elimínalos primero, para que ninguno se quede sin punto.',
                {'nombre': lugar.nombre, 'n': r.negocios}),
      );
      return false;
    }

    if (r.estado == 'TIENE_SELLOS') {
      final ocultarlo = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(tr('No se puede eliminar')),
          content: Text(
            '${r.sellos == 1 ? tr('"{nombre}" ya tiene 1 sello de turistas.', {'nombre': lugar.nombre}) : tr('"{nombre}" ya tiene {n} sellos de turistas.', {'nombre': lugar.nombre, 'n': r.sellos})} '
            '${tr('Si se eliminara, perderían esos sellos y podrían bajar de insignia.\n\nPuedes OCULTARLO: deja de aparecer en la app y los turistas conservan sus sellos.')}',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text(tr('Cancelar'))),
            FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: Text(tr('Ocultarlo'))),
          ],
        ),
      );
      if (ocultarlo != true) return false;
      try {
        await ocultar();
        avisos.showSnackBar(SnackBar(content: Text(tr('Se ocultó. Ya no aparece en la app.'))));
        return true;
      } on ErrorVeraGo catch (e) {
        avisos.showSnackBar(SnackBar(content: Text(e.mensaje)));
        return false;
      }
    }

    // Se puede eliminar: confirmación clara.
    final seguro = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.delete_forever_outlined, color: Color(0xFF9B2C2C), size: 40),
        title: Text(tr('¿Eliminar "{nombre}" para siempre?', {'nombre': lugar.nombre})),
        content: Text(
          '${tr('Se borran también su foto, su horario y sus códigos QR.')}'
          '${r.eventos == 1 ? '\n\n${tr('1 evento quedará sin lugar en la Agenda.')}' : ''}'
          '${r.eventos > 1 ? '\n\n${tr('{n} eventos quedarán sin lugar en la Agenda.', {'n': r.eventos})}' : ''}'
          '\n\n${tr('Esto no se puede deshacer.')}',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text(tr('Cancelar'))),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF9B2C2C)),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(tr('Eliminar')),
          ),
        ],
      ),
    );
    if (seguro != true) return false;
    try {
      await s.eliminar(lugar.id, fotoUrl: lugar.fotoUrl);
      avisos.showSnackBar(SnackBar(content: Text(tr('"{nombre}" se eliminó.', {'nombre': lugar.nombre}))));
      return true;
    } on ErrorVeraGo catch (e) {
      avisos.showSnackBar(SnackBar(content: Text(e.mensaje)));
      return false;
    }
  }

  static Future<void> _aviso(BuildContext context, String titulo, String texto) => showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(titulo),
          content: Text(texto),
          actions: [FilledButton(onPressed: () => Navigator.of(ctx).pop(), child: Text(tr('Entendido')))],
        ),
      );
}
