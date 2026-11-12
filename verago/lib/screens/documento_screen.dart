import 'package:flutter/material.dart';

import '../config.dart';
import '../legal/documentos.dart';
import '../theme/app_theme.dart';

/// Muestra un documento (Aviso de privacidad, Términos, Reglas…).
/// Al final siempre agrega "Contacto" y la versión del documento.
class DocumentoScreen extends StatelessWidget {
  const DocumentoScreen({super.key, required this.documento});

  final DocumentoLegal documento;

  /// Atajo para abrir un documento desde cualquier pantalla.
  static Future<void> abrir(BuildContext context, DocumentoLegal documento) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => DocumentoScreen(documento: documento)));

  /// Cómo contactar al equipo (usa SOPORTE_CORREO de env.json si existe).
  static String get textoContacto => Config.correoSoporte.isEmpty
      ? 'Contacta al equipo de VeraGo.'
      : 'Escríbenos a ${Config.correoSoporte}.';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(documento.titulo)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
        children: [
          Text(documento.resumen, style: TextStyle(color: Colors.black.withValues(alpha: 0.65))),
          for (final s in documento.secciones) ...[
            const SizedBox(height: 20),
            Text(s.titulo, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            for (final p in s.parrafos)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(p, style: const TextStyle(height: 1.4)),
              ),
          ],
          const SizedBox(height: 20),
          Text('Contacto', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(textoContacto),
          const SizedBox(height: 24),
          Text(
            DocumentoLegal.version,
            style: const TextStyle(fontSize: 12, color: VgColores.azulGolfo),
          ),
        ],
      ),
    );
  }
}
