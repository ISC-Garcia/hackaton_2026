import 'package:flutter/material.dart';

import '../models/lugar.dart';
import '../services/error_verago.dart';
import '../services/negocios_service.dart';
import '../services/validaciones.dart';

/// EDITAR MIS DATOS (comerciante).
///
/// - Todos: descripción y teléfono.
/// - Formal: también dirección y horario.
/// - Informal: el horario lo asigna VeraGo en su punto; no se edita aquí.
/// El nombre comercial y el estado solo los cambia el equipo de VeraGo.
class EditarNegocioScreen extends StatefulWidget {
  const EditarNegocioScreen({super.key, required this.negocio});

  final Lugar negocio;

  @override
  State<EditarNegocioScreen> createState() => _EditarNegocioScreenState();
}

class _EditarNegocioScreenState extends State<EditarNegocioScreen> {
  final _servicio = NegociosService();
  final _formulario = GlobalKey<FormState>();
  late final _descripcion = TextEditingController(text: widget.negocio.descripcion ?? '');
  late final _telefono = TextEditingController(text: widget.negocio.telefono ?? '');
  late final _direccion = TextEditingController(text: widget.negocio.direccion ?? '');

  /// Horario editable: un valor por día (0 = domingo); null = cerrado.
  late final List<Horario?> _horario = [for (var d = 0; d < 7; d++) widget.negocio.horarioDel(d)];

  bool _guardando = false;

  static const _dias = ['Domingo', 'Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado'];

  @override
  void dispose() {
    _descripcion.dispose();
    _telefono.dispose();
    _direccion.dispose();
    super.dispose();
  }

  Future<void> _elegirHora(int dia, {required bool apertura}) async {
    final actual = _horario[dia] ?? Horario(diaSemana: dia, abre: 9 * 60, cierra: 18 * 60);
    final minutos = apertura ? actual.abre : actual.cierra;
    final elegida = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: minutos ~/ 60, minute: minutos % 60),
    );
    if (elegida == null) return;
    final m = elegida.hour * 60 + elegida.minute;
    setState(() {
      _horario[dia] = Horario(
        diaSemana: dia,
        abre: apertura ? m : actual.abre,
        cierra: apertura ? actual.cierra : m,
      );
    });
  }

  Future<void> _guardar() async {
    if (!_formulario.currentState!.validate()) return;
    final dias = _horario.whereType<Horario>().toList();
    if (dias.any((h) => h.cierra <= h.abre)) {
      _mensaje('En cada día, la hora de cierre debe ser después de la de apertura.');
      return;
    }
    setState(() => _guardando = true);
    try {
      await _servicio.actualizar(
        descripcion: _descripcion.text,
        telefono: _telefono.text,
        direccion: _direccion.text,
      );
      if (widget.negocio.esFormal) await _servicio.guardarHorario(dias);
      if (mounted) Navigator.of(context).pop(true);
    } on ErrorVeraGo catch (e) {
      _mensaje(e.mensaje);
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  void _mensaje(String texto) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));

  @override
  Widget build(BuildContext context) {
    final formal = widget.negocio.esFormal;
    return Scaffold(
      appBar: AppBar(title: const Text('Editar mis datos')),
      body: Form(
        key: _formulario,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
          children: [
            Text(widget.negocio.nombre, style: Theme.of(context).textTheme.titleLarge),
            const Text('El nombre comercial solo lo cambia el equipo de VeraGo.',
                style: TextStyle(fontSize: 12)),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descripcion,
              maxLength: 160,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Descripción breve', border: OutlineInputBorder()),
              validator: Validaciones.obligatorio('una descripción', minimo: 10),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _telefono,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Teléfono de contacto', border: OutlineInputBorder()),
              validator: Validaciones.telefono,
            ),
            if (formal) ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: _direccion,
                decoration: const InputDecoration(labelText: 'Dirección', border: OutlineInputBorder()),
                validator: Validaciones.obligatorio('la dirección', minimo: 5),
              ),
              const SizedBox(height: 20),
              Text('Horario', style: Theme.of(context).textTheme.titleLarge),
              for (var d = 0; d < 7; d++) _filaDia(d),
            ] else
              const Padding(
                padding: EdgeInsets.only(top: 16),
                child: Text('Tu horario lo asigna el equipo de VeraGo en tu Punto VeraGo.'),
              ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _guardando ? null : _guardar,
              child: Text(_guardando ? 'Guardando…' : 'Guardar cambios'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filaDia(int d) {
    final h = _horario[d];
    return Row(
      children: [
        SizedBox(width: 92, child: Text(_dias[d])),
        Switch(
          value: h != null,
          onChanged: (abierto) => setState(() {
            _horario[d] = abierto ? Horario(diaSemana: d, abre: 9 * 60, cierra: 18 * 60) : null;
          }),
        ),
        if (h == null)
          const Text('Cerrado')
        else ...[
          TextButton(
            onPressed: () => _elegirHora(d, apertura: true),
            child: Text(Horario.formato(h.abre)),
          ),
          const Text('a'),
          TextButton(
            onPressed: () => _elegirHora(d, apertura: false),
            child: Text(Horario.formato(h.cierra)),
          ),
        ],
      ],
    );
  }
}
