import 'package:flutter/material.dart';

import '../services/validaciones.dart';

/// EDITOR DEL COSTO DE ENTRADA (SQL 014).
///
/// - Negocio: "No cobro entrada" o "Cobro entrada" + monto.
/// - Lugar público (admin): "Sin confirmar", "Gratis" o "Con costo" + monto.
///   "Sin confirmar" existe para no inventar precios de lugares reales.
///
/// Avisa con `alCambiar` el valor a guardar: null = sin dato, 0 = gratis,
/// > 0 = pesos. Si eligen "con costo" y no escriben el monto, el campo
/// marca error al validar el formulario.
class EditorCostoEntrada extends StatefulWidget {
  const EditorCostoEntrada({
    super.key,
    required this.inicial,
    required this.paraNegocio,
    required this.alCambiar,
  });

  final int? inicial;
  final bool paraNegocio;
  final ValueChanged<int?> alCambiar;

  @override
  State<EditorCostoEntrada> createState() => _EditorCostoEntradaState();
}

enum _Modo { sinDato, gratis, conCosto }

class _EditorCostoEntradaState extends State<EditorCostoEntrada> {
  late _Modo _modo;
  late final _monto = TextEditingController(
    text: (widget.inicial ?? 0) > 0 ? '${widget.inicial}' : '',
  );

  @override
  void initState() {
    super.initState();
    final c = widget.inicial;
    _modo = c == null
        ? _Modo.sinDato
        // Un negocio con 0 se trata como "no cobro entrada".
        : (c == 0 ? (widget.paraNegocio ? _Modo.sinDato : _Modo.gratis) : _Modo.conCosto);
  }

  @override
  void dispose() {
    _monto.dispose();
    super.dispose();
  }

  void _avisar() {
    widget.alCambiar(switch (_modo) {
      _Modo.sinDato => null,
      _Modo.gratis => 0,
      _Modo.conCosto => int.tryParse(_monto.text.trim()),
    });
  }

  @override
  Widget build(BuildContext context) {
    final opciones = widget.paraNegocio
        ? const {_Modo.sinDato: 'No cobro entrada', _Modo.conCosto: 'Cobro entrada'}
        : const {_Modo.sinDato: 'Sin confirmar', _Modo.gratis: 'Gratis', _Modo.conCosto: 'Con costo'};
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Costo de entrada', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        SegmentedButton<_Modo>(
          segments: [for (final o in opciones.entries) ButtonSegment(value: o.key, label: Text(o.value))],
          selected: {_modo},
          onSelectionChanged: (s) {
            setState(() => _modo = s.first);
            _avisar();
          },
        ),
        if (_modo == _Modo.conCosto) ...[
          const SizedBox(height: 10),
          TextFormField(
            controller: _monto,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Costo aproximado por persona (pesos)',
              prefixText: '\$ ',
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => _avisar(),
            validator: (v) {
              final t = (v ?? '').trim();
              if (t.isEmpty || t == '0') return 'Escribe el costo (o elige otra opción)';
              return Validaciones.costo(t);
            },
          ),
        ],
        if (!widget.paraNegocio && _modo == _Modo.sinDato)
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Text('La app dirá "Costo no disponible: confírmalo en el lugar". No pongas precios sin confirmar.',
                style: TextStyle(fontSize: 12)),
          ),
      ],
    );
  }
}
