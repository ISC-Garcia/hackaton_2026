import 'package:flutter/material.dart';

import '../config.dart';
import '../i18n/idioma.dart';
import '../legal/documentos.dart';
import '../services/traductor_service.dart';
import '../theme/app_theme.dart';

/// Muestra un documento (Aviso de privacidad, Términos, Reglas…).
/// Al final siempre agrega "Contacto" y la versión del documento.
///
/// IDIOMA: si la app no está en español, el documento se traduce con Gemini
/// y se avisa que la versión válida es la de español.
class DocumentoScreen extends StatefulWidget {
  const DocumentoScreen({super.key, required this.documento});

  final DocumentoLegal documento;

  /// Atajo para abrir un documento desde cualquier pantalla.
  static Future<void> abrir(BuildContext context, DocumentoLegal documento) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => DocumentoScreen(documento: documento)));

  /// Cómo contactar al equipo (usa SOPORTE_CORREO de env.json si existe).
  static String get textoContacto => Config.correoSoporte.isEmpty
      ? tr('Contacta al equipo de VeraGo.')
      : tr('Escríbenos a {correo}.', {'correo': Config.correoSoporte});

  @override
  State<DocumentoScreen> createState() => _DocumentoScreenState();
}

class _DocumentoScreenState extends State<DocumentoScreen> {
  DocumentoLegal get documento => widget.documento;

  /// Original → traducción (vacío en español o mientras llega).
  Map<String, String> _traducido = const {};
  bool _traduciendo = false;

  @override
  void initState() {
    super.initState();
    if (!Idioma.esEspanol) _traducir();
  }

  Future<void> _traducir() async {
    setState(() => _traduciendo = true);
    final r = await TraductorService().traducir([
      for (final s in documento.secciones) ...[s.titulo, ...s.parrafos],
    ]);
    if (mounted) {
      setState(() {
        _traducido = r;
        _traduciendo = false;
      });
    }
  }

  String _t(String original) => _traducido[original] ?? original;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(tr(documento.titulo))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
        children: [
          Text(tr(documento.resumen), style: TextStyle(color: Colors.black.withValues(alpha: 0.65))),
          if (!Idioma.esEspanol)
            Container(
              margin: const EdgeInsets.only(top: 12),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: VgColores.azulGolfo.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  if (_traduciendo)
                    const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  else
                    const Icon(Icons.translate, size: 18, color: VgColores.azulGolfo),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      tr('Traducción automática con IA. La versión válida es la de español.'),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          for (final s in documento.secciones) ...[
            const SizedBox(height: 20),
            Text(_t(s.titulo), style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            for (final p in s.parrafos)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(_t(p), style: const TextStyle(height: 1.4)),
              ),
          ],
          const SizedBox(height: 20),
          Text(tr('Contacto'), style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(DocumentoScreen.textoContacto),
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
