import 'dart:async';

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../services/error_verago.dart';
import '../services/pasaporte_service.dart';
import '../theme/app_theme.dart';
import '../widgets/estado_vacio.dart';

/// QR DEL COMERCIO: lo ve el comerciante en su celular y se lo muestra al
/// visitante.
///
/// Cómo funciona:
/// - Pide un código a la función `generar_codigo_qr` (dura 60 segundos).
/// - Lo dibuja como QR (paquete `qr_flutter`).
/// - Un temporizador (`Timer`) cuenta los segundos y, al llegar a 0,
///   pide un código nuevo. Así una foto del QR no sirve después de un minuto.
class QrComercioScreen extends StatefulWidget {
  const QrComercioScreen({super.key});

  @override
  State<QrComercioScreen> createState() => _QrComercioScreenState();
}

class _QrComercioScreenState extends State<QrComercioScreen> {
  final _servicio = PasaporteService();
  List<({String id, String nombre})> _comercios = [];
  String? _comercioId;
  String? _codigo;
  DateTime? _venceEn;
  String? _error;
  bool _cargando = true;
  bool _pidiendo = false; // evita pedir dos códigos a la vez
  int _segundosSinCodigo = 0; // para reintentar si falló la red
  Timer? _reloj;

  @override
  void initState() {
    super.initState();
    _iniciar();
  }

  @override
  void dispose() {
    _reloj?.cancel(); // detener el temporizador al salir
    super.dispose();
  }

  Future<void> _iniciar() async {
    try {
      final comercios = await _servicio.misComercios();
      if (!mounted) return;
      setState(() {
        _comercios = comercios;
        _comercioId = comercios.isEmpty ? null : comercios.first.id;
        _cargando = false;
      });
      if (_comercioId != null) await _nuevoCodigo();
      _reloj = Timer.periodic(const Duration(seconds: 1), (_) => _tic());
    } on ErrorVeraGo catch (e) {
      if (mounted) {
        setState(() {
          _error = e.mensaje;
          _cargando = false;
        });
      }
    }
  }

  Future<void> _nuevoCodigo() async {
    final id = _comercioId;
    if (id == null || _pidiendo) return;
    _pidiendo = true;
    try {
      final r = await _servicio.generarCodigo(id);
      if (!mounted) return;
      setState(() {
        _codigo = r.codigo;
        // La cuenta regresiva se mide con el reloj de ESTE celular (60 s desde
        // que llegó el código). Si usáramos la hora del servidor, un celular
        // con la hora mal pediría códigos sin parar.
        _venceEn = DateTime.now().add(const Duration(seconds: 60));
        _error = null;
      });
    } on ErrorVeraGo catch (e) {
      if (mounted) setState(() => _error = e.mensaje);
    } finally {
      _pidiendo = false;
      _segundosSinCodigo = 0;
    }
  }

  int get _segundosRestantes {
    final v = _venceEn;
    if (v == null) return 0;
    final s = v.difference(DateTime.now()).inSeconds;
    return s < 0 ? 0 : s;
  }

  void _tic() {
    if (!mounted) return;
    // Pedimos el nuevo código 5 s antes de que venza el actual.
    if (_codigo != null && _segundosRestantes <= 5) {
      _codigo = null;
      _nuevoCodigo();
    } else if (_codigo == null && !_pidiendo && ++_segundosSinCodigo >= 10) {
      // Falló (por ejemplo, sin internet): reintentamos cada 10 s.
      _nuevoCodigo();
    }
    setState(() {}); // redibuja la cuenta regresiva
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('QR de mi comercio')),
      body: _cuerpo(),
    );
  }

  Widget _cuerpo() {
    if (_cargando) return const Center(child: CircularProgressIndicator());
    if (_comercios.isEmpty) {
      return EstadoVacio(
        icono: Icons.storefront,
        titulo: 'Sin comercio asignado',
        mensaje: _error ??
            'Tu negocio aún no da sellos. Solo los negocios formales aprobados por VeraGo '
                'muestran QR (los de un Punto VeraGo no dan sellos).',
      );
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (_comercios.length > 1)
          DropdownButtonFormField<String>(
            initialValue: _comercioId,
            decoration: const InputDecoration(labelText: 'Comercio', border: OutlineInputBorder()),
            items: [
              for (final c in _comercios) DropdownMenuItem(value: c.id, child: Text(c.nombre)),
            ],
            onChanged: (id) {
              setState(() => _comercioId = id);
              _nuevoCodigo();
            },
          )
        else
          Text(_comercios.first.nombre,
              textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 16),
        const Text(
          'Muestra este código al visitante para que gane su sello.',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Center(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: _codigo == null
                ? const SizedBox(width: 260, height: 260, child: Center(child: CircularProgressIndicator()))
                : QrImageView(data: _codigo!, size: 260),
          ),
        ),
        const SizedBox(height: 12),
        if (_codigo != null) ...[
          Text(
            'Cambia en $_segundosRestantes s',
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w700, color: VgColores.azulGolfo),
          ),
          const SizedBox(height: 8),
          // Texto del código: para escribirlo a mano si la cámara falla.
          SelectableText(
            _codigo!,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.black.withValues(alpha: 0.55)),
          ),
        ],
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF9B2C2C))),
        ],
      ],
    );
  }
}
