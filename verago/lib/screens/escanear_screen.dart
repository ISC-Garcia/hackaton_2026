import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../models/lugar.dart';
import '../services/distancia.dart';
import '../services/error_verago.dart';
import '../services/pasaporte_service.dart';
import '../services/rutas_service.dart';
import '../theme/app_theme.dart';
import 'lugar_screen.dart';

/// ESCANEAR QR: lee el código del comercio con la cámara
/// (paquete `mobile_scanner`) y lo envía a la función `registrar_visita`.
///
/// También permite escribir el código a mano, por si la cámara no
/// funciona (o para probar en un emulador).
///
/// Si el sello se obtiene, VeraGo sugiere otro lugar cercano para
/// seguir explorando.
/// Animación de "estampar" el sello: empieza grande, inclinado y
/// transparente, y cae a su tamaño normal con un pequeño rebote.
///
/// `TweenAnimationBuilder` anima un número de 0 a 1 durante 600 ms;
/// con ese número calculamos tamaño, giro y opacidad en cada cuadro.
class _SelloAnimado extends StatelessWidget {
  const _SelloAnimado();

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutBack, // el "rebote" final
      builder: (context, t, child) => Opacity(
        opacity: t.clamp(0.0, 1.0),
        child: Transform.rotate(
          angle: (1 - t) * -0.5, // de inclinado a derecho
          child: Transform.scale(scale: 2.2 - 1.2 * t, child: child), // de 2.2× a 1×
        ),
      ),
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: VgColores.verdePalma.withValues(alpha: 0.12),
          border: Border.all(color: VgColores.verdePalma, width: 3),
        ),
        child: const Icon(Icons.approval, size: 40, color: VgColores.verdePalma),
      ),
    );
  }
}

class EscanearScreen extends StatefulWidget {
  const EscanearScreen({super.key, required this.lugares, required this.sellados});

  final List<Lugar> lugares;

  /// Ids de lugares de los que ya tiene sello (para no sugerirlos).
  final Set<String> sellados;

  @override
  State<EscanearScreen> createState() => _EscanearScreenState();
}

class _EscanearScreenState extends State<EscanearScreen> {
  final _servicio = PasaporteService();
  final _camara = MobileScannerController(detectionSpeed: DetectionSpeed.noDuplicates);
  final _manual = TextEditingController();
  bool _procesando = false;

  @override
  void dispose() {
    _camara.dispose();
    _manual.dispose();
    super.dispose();
  }

  Future<void> _procesar(String codigo) async {
    if (_procesando || codigo.trim().isEmpty) return;
    setState(() => _procesando = true);
    await _camara.stop(); // pausar la cámara mientras validamos

    try {
      final r = await _servicio.registrarVisita(codigo);
      if (!mounted) return;
      await _mostrarResultado(r);
      if (!mounted) return;
      if (r.exito) {
        Navigator.of(context).pop(true); // vuelve al pasaporte y lo recarga
        return;
      }
    } on ErrorVeraGo catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.mensaje)));
      }
    }

    if (mounted) {
      setState(() => _procesando = false);
      await _camara.start();
    }
  }

  Future<void> _mostrarResultado(ResultadoEscaneo r) {
    // Sugerencia: el comercio más cercano al lugar sellado que aún no tenga.
    Lugar? sugerencia;
    Lugar? sellado;
    if (r.exito) {
      for (final l in widget.lugares) {
        if (l.id == r.lugarId) sellado = l;
      }
      if (sellado != null) {
        sugerencia = RutasService().sugerenciaCercana(
          sellado.punto,
          widget.lugares,
          {...widget.sellados, sellado.id},
        );
      }
    }

    return showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: r.exito
            ? const _SelloAnimado()
            : const Icon(Icons.info_outline, size: 48, color: VgColores.terracota),
        title: Text(r.exito ? '¡Nuevo sello!' : 'No se registró el sello'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(r.mensaje, textAlign: TextAlign.center),
            if (sugerencia != null && sellado != null) ...[
              const SizedBox(height: 16),
              Text(
                'A ${Distancia.minutosCaminando(sellado.punto, sugerencia.punto)} min de aquí '
                'está ${sugerencia.nombre}. ¿Por qué no vas?',
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ],
        ),
        actions: [
          if (sugerencia != null)
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => LugarScreen(lugar: sugerencia!, todos: widget.lugares),
                ));
              },
              child: const Text('Ver lugar'),
            ),
          FilledButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Listo')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Escanear QR')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Apunta la cámara al código QR que te muestra el comercio.'),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: SizedBox(
              height: 320,
              child: Stack(
                children: [
                  MobileScanner(
                    controller: _camara,
                    onDetect: (captura) {
                      final valor = captura.barcodes.firstOrNull?.rawValue;
                      if (valor != null) _procesar(valor);
                    },
                    errorBuilder: (context, error) => const ColoredBox(
                      color: Colors.black12,
                      child: Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Text(
                            'No pudimos usar la cámara. Revisa el permiso o escribe el código abajo.',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (_procesando)
                    const ColoredBox(
                      color: Colors.black38,
                      child: Center(child: CircularProgressIndicator(color: Colors.white)),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text('¿No funciona la cámara? Escribe el código:',
              style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          TextField(
            controller: _manual,
            decoration: const InputDecoration(
              hintText: 'VG-…',
              border: OutlineInputBorder(),
            ),
            autocorrect: false,
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _procesando ? null : () => _procesar(_manual.text),
            child: const Text('Validar código'),
          ),
        ],
      ),
    );
  }
}
