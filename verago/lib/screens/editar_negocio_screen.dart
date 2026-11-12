import 'package:flutter/material.dart';

import '../models/lugar.dart';
import '../services/error_verago.dart';
import '../services/negocios_service.dart';
import '../services/validaciones.dart';
import '../widgets/editor_horario.dart';

/// EDITAR MIS DATOS (comerciante).
///
/// - Todos: descripción y teléfono.
/// - Formal: también horario. La DIRECCIÓN ya no se edita aquí: va con
///   "Cambiar ubicación" en el panel, porque la debe aceptar el admin.
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

  /// Horario editable: un valor por día (0 = domingo); null = cerrado.
  late final List<Horario?> _horario = EditorHorario.desde(widget.negocio);

  bool _guardando = false;

  @override
  void dispose() {
    _descripcion.dispose();
    _telefono.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formulario.currentState!.validate()) return;
    final errorHorario = EditorHorario.validar(_horario);
    if (errorHorario != null) {
      _mensaje(errorHorario);
      return;
    }
    setState(() => _guardando = true);
    try {
      await _servicio.actualizar(
        descripcion: _descripcion.text,
        telefono: _telefono.text,
        direccionActual: widget.negocio.direccion ?? '',
      );
      if (widget.negocio.esFormal) await _servicio.guardarHorario(_horario.whereType<Horario>().toList());
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
              maxLength: 10,
              inputFormatters: Validaciones.soloDiezDigitos,
              decoration: const InputDecoration(
                  labelText: 'Teléfono de contacto (10 números)', border: OutlineInputBorder()),
              validator: Validaciones.telefono,
            ),
            if (formal) ...[
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.place_outlined),
                title: Text(widget.negocio.direccion ?? '—'),
                subtitle: const Text('Para cambiar tu ubicación o dirección usa "Cambiar ubicación" '
                    'en tu panel (VeraGo la revisa).'),
              ),
              const SizedBox(height: 20),
              Text('Horario', style: Theme.of(context).textTheme.titleLarge),
              EditorHorario(horario: _horario, alCambiar: () => setState(() {})),
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
}
