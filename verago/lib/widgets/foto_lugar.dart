import 'package:flutter/material.dart';

import '../i18n/idioma.dart';
import '../models/lugar.dart';
import '../services/error_verago.dart';
import '../services/fotos_service.dart';
import 'categoria_estilo.dart';

/// FOTO DE UN LUGAR. Si no tiene foto (o no carga, por ejemplo sin
/// internet), muestra el bloque de color con el ícono de su categoría, como
/// antes.
class FotoLugar extends StatelessWidget {
  const FotoLugar({super.key, required this.lugar, required this.ancho, required this.alto, this.radio = 12});

  final Lugar lugar;
  final double ancho;
  final double alto;
  final double radio;

  @override
  Widget build(BuildContext context) {
    final estilo = CategoriaEstilo.de(lugar.categoriaClave);
    final respaldo = Container(
      width: ancho,
      height: alto,
      decoration: BoxDecoration(
        color: estilo.color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(radio),
      ),
      child: Icon(estilo.icono, color: estilo.color, size: (alto * 0.45).clamp(20, 64).toDouble()),
    );
    final url = lugar.fotoUrl;
    if (url == null) return respaldo;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radio),
      child: Image.network(
        url,
        width: ancho,
        height: alto,
        fit: BoxFit.cover, // llena el espacio recortando los bordes
        semanticLabel: tr('Foto de {nombre}', {'nombre': lugar.nombre}),
        loadingBuilder: (_, hijo, progreso) => progreso == null ? hijo : respaldo,
        errorBuilder: (_, _, _) => respaldo,
      ),
    );
  }
}

/// EDITOR DE FOTO: vista previa + "Elegir foto", "Tomar foto" y "Quitar".
/// Sube a Supabase Storage y llama a `alGuardar` con la URL nueva (o null al
/// quitar). Quien lo usa decide cómo guardarla (admin o comerciante).
class EditorFoto extends StatefulWidget {
  const EditorFoto({super.key, required this.lugar, required this.alGuardar});

  final Lugar lugar;

  /// Guarda la URL en la base de datos. Si falla, debe lanzar ErrorVeraGo.
  final Future<void> Function(String? url) alGuardar;

  @override
  State<EditorFoto> createState() => _EditorFotoState();
}

class _EditorFotoState extends State<EditorFoto> {
  final _fotos = FotosService();
  late String? _url = widget.lugar.fotoUrl;
  bool _trabajando = false;

  Future<void> _cambiar({required bool camara}) async {
    setState(() => _trabajando = true);
    try {
      final nueva = await _fotos.elegirYSubir(widget.lugar.id, camara: camara);
      if (nueva == null) return; // canceló
      await widget.alGuardar(nueva);
      final anterior = _url;
      if (mounted) setState(() => _url = nueva);
      await _fotos.borrarArchivo(anterior); // no dejar fotos viejas guardadas
      _aviso(tr('Foto guardada.'));
    } on ErrorVeraGo catch (e) {
      _aviso(e.mensaje);
    } finally {
      if (mounted) setState(() => _trabajando = false);
    }
  }

  Future<void> _quitar() async {
    setState(() => _trabajando = true);
    try {
      await widget.alGuardar(null);
      final anterior = _url;
      if (mounted) setState(() => _url = null);
      await _fotos.borrarArchivo(anterior);
      _aviso(tr('Foto quitada.'));
    } on ErrorVeraGo catch (e) {
      _aviso(e.mensaje);
    } finally {
      if (mounted) setState(() => _trabajando = false);
    }
  }

  void _aviso(String t) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t)));
  }

  @override
  Widget build(BuildContext context) {
    final vista = Lugar(
      id: widget.lugar.id,
      nombre: widget.lugar.nombre,
      descripcion: null,
      categoriaClave: widget.lugar.categoriaClave,
      categoriaNombre: widget.lugar.categoriaNombre,
      latitud: widget.lugar.latitud,
      longitud: widget.lugar.longitud,
      direccion: null,
      telefono: null,
      interes: 3,
      duracionVisitaMin: 30,
      esComercio: widget.lugar.esComercio,
      esDemo: false,
      participaPasaporte: false,
      horarios: const [],
      fotoUrl: _url,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(tr('Foto'), style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Stack(
          alignment: Alignment.center,
          children: [
            FotoLugar(lugar: vista, ancho: double.infinity, alto: 170),
            if (_trabajando) const CircularProgressIndicator(),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            OutlinedButton.icon(
              onPressed: _trabajando ? null : () => _cambiar(camara: false),
              icon: const Icon(Icons.photo_library_outlined),
              label: Text(_url == null ? tr('Elegir foto') : tr('Cambiar foto')),
            ),
            OutlinedButton.icon(
              onPressed: _trabajando ? null : () => _cambiar(camara: true),
              icon: const Icon(Icons.photo_camera_outlined),
              label: Text(tr('Tomar foto')),
            ),
            if (_url != null)
              TextButton.icon(
                onPressed: _trabajando ? null : _quitar,
                style: TextButton.styleFrom(foregroundColor: const Color(0xFF9B2C2C)),
                icon: const Icon(Icons.delete_outline),
                label: Text(tr('Quitar')),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(tr('Usa una foto propia del lugar (sin personas reconocibles). Se ve en la app al instante.'),
            style: TextStyle(fontSize: 12)),
      ],
    );
  }
}
