import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/lugar.dart';
import '../services/error_verago.dart';
import '../services/negocios_service.dart';

/// MI VITRINA (comerciante): productos o servicios y una promoción.
///
/// Es la "vitrina digital" del documento original: lo que el turista ve en
/// la ficha del negocio. Solo texto (sin fotos, decisión de MVP).
/// Se publica al guardar; si es engañosa, se reporta y VeraGo la corrige.
class EditarVitrinaScreen extends StatefulWidget {
  const EditarVitrinaScreen({super.key, required this.negocio});

  final Lugar negocio;

  /// Máximo de productos (igual que en la base de datos).
  static const maximo = 20;

  @override
  State<EditarVitrinaScreen> createState() => _EditarVitrinaScreenState();
}

/// Una fila editable: nombre y precio.
class _Fila {
  _Fila(String nombre, int? precio)
      : nombre = TextEditingController(text: nombre),
        precio = TextEditingController(text: precio?.toString() ?? '');
  final TextEditingController nombre;
  final TextEditingController precio;
  void dispose() {
    nombre.dispose();
    precio.dispose();
  }
}

class _EditarVitrinaScreenState extends State<EditarVitrinaScreen> {
  final _formulario = GlobalKey<FormState>();
  late final _filas = [for (final p in widget.negocio.productos) _Fila(p.nombre, p.precioMxn)];
  late final _promocion = TextEditingController(text: widget.negocio.promocion ?? '');
  bool _guardando = false;

  @override
  void dispose() {
    for (final f in _filas) {
      f.dispose();
    }
    _promocion.dispose();
    super.dispose();
  }

  void _agregar() => setState(() => _filas.add(_Fila('', null)));

  void _quitar(int i) => setState(() => _filas.removeAt(i).dispose());

  Future<void> _guardar() async {
    if (!_formulario.currentState!.validate()) return;
    setState(() => _guardando = true);
    try {
      await NegociosService().guardarVitrina(
        [
          for (final f in _filas)
            ProductoVitrina(nombre: f.nombre.text.trim(), precioMxn: int.tryParse(f.precio.text.trim())),
        ],
        _promocion.text,
      );
      if (mounted) Navigator.of(context).pop(true);
    } on ErrorVeraGo catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.mensaje)));
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mi vitrina')),
      body: Form(
        key: _formulario,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
          children: [
            const Text('Lo que escribas aquí lo ven los turistas en la ficha de tu negocio. '
                'Usa precios reales y aproximados por persona.'),
            const SizedBox(height: 16),
            Text('Promoción (opcional)', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            TextFormField(
              controller: _promocion,
              maxLength: 140,
              maxLines: 2,
              decoration: const InputDecoration(
                hintText: 'Ej. 2x1 en café de 4 a 6 pm',
                border: OutlineInputBorder(),
              ),
              validator: (v) {
                final t = (v ?? '').trim();
                return t.isNotEmpty && t.length < 3 ? 'Escribe al menos 3 letras o déjala vacía' : null;
              },
            ),
            const SizedBox(height: 8),
            Text('Productos o servicios', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            if (_filas.isEmpty)
              const Text('Aún no tienes productos. Agrega los más importantes.'),
            for (var i = 0; i < _filas.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextFormField(
                        controller: _filas[i].nombre,
                        maxLength: 60,
                        decoration: const InputDecoration(labelText: 'Nombre', border: OutlineInputBorder(), counterText: ''),
                        validator: (v) => (v ?? '').trim().length < 2 ? 'Escribe el nombre' : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _filas[i].precio,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
                        decoration: const InputDecoration(
                          labelText: 'Precio',
                          prefixText: '\$ ',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Quitar',
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => _quitar(i),
                    ),
                  ],
                ),
              ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _filas.length >= EditarVitrinaScreen.maximo ? null : _agregar,
                icon: const Icon(Icons.add),
                label: Text(_filas.length >= EditarVitrinaScreen.maximo
                    ? 'Máximo ${EditarVitrinaScreen.maximo} productos'
                    : 'Agregar producto o servicio'),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _guardando ? null : _guardar,
              child: Text(_guardando ? 'Guardando…' : 'Guardar vitrina'),
            ),
          ],
        ),
      ),
    );
  }
}
