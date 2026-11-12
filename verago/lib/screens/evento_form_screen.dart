import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/evento.dart';
import '../models/lugar.dart';
import '../services/error_verago.dart';
import '../services/eventos_service.dart';
import '../services/lugares_service.dart';
import '../services/validaciones.dart';
import '../widgets/estado_vacio.dart';

/// FORMULARIO DE EVENTO (solo admin): crear uno nuevo o editar uno existente.
///
/// Al CREAR se puede marcar "Se repite": cada N días, M veces. La hora es la
/// de "Inicia" y "Termina" y se crea un evento por fecha.
///
/// Devuelve `true` al guardar, para que la Agenda se recargue.
/// La app solo muestra esta pantalla al admin, pero la seguridad real está
/// en la base de datos (regla RLS "admin administra eventos").
class EventoFormScreen extends StatefulWidget {
  const EventoFormScreen({super.key, this.evento});

  /// null = evento nuevo.
  final Evento? evento;

  @override
  State<EventoFormScreen> createState() => _EventoFormScreenState();
}

class _EventoFormScreenState extends State<EventoFormScreen> {
  final _servicio = EventosService();
  final _formulario = GlobalKey<FormState>();
  late final _titulo = TextEditingController(text: widget.evento?.titulo ?? '');
  late final _descripcion = TextEditingController(text: widget.evento?.descripcion ?? '');
  late final _costo = TextEditingController(text: widget.evento?.costoAproxMxn?.toString() ?? '');

  late Future<List<Lugar>> _lugares;
  String? _lugarId;
  late DateTime _inicia;
  late DateTime _termina;
  late String _estado;
  late bool _gratuito;
  bool _guardando = false;

  // Repetición (solo al crear).
  bool _repite = false;
  final _cadaDias = TextEditingController(text: '7');
  final _veces = TextEditingController(text: '4');

  bool get _esNuevo => widget.evento == null;

  @override
  void initState() {
    super.initState();
    final e = widget.evento;
    // Nuevo: empieza en la siguiente hora en punto y dura 2 horas.
    final ahora = DateTime.now();
    final siguienteHora = DateTime(ahora.year, ahora.month, ahora.day, ahora.hour + 1);
    _inicia = e?.inicia ?? siguienteHora;
    _termina = e?.termina ?? siguienteHora.add(const Duration(hours: 2));
    _lugarId = e?.lugarId;
    _estado = e?.estado ?? 'publicado';
    _gratuito = e?.esGratuito ?? true;
    // Lugares donde puede ocurrir un evento (sin los comerciantes que están
    // dentro de un Punto VeraGo: el evento se ubica en el punto).
    _lugares = LugaresService()
        .obtenerLugares()
        .then((ls) => ls.where((l) => !l.esInformal).toList());
  }

  @override
  void dispose() {
    _titulo.dispose();
    _descripcion.dispose();
    _costo.dispose();
    _cadaDias.dispose();
    _veces.dispose();
    super.dispose();
  }

  /// Elegir fecha y luego hora (dos ventanas del sistema).
  Future<DateTime?> _elegirFechaHora(DateTime actual) async {
    // La primera fecha permitida no puede ser posterior a la del evento: si
    // se edita uno que ya empezó (ej. exposición de varios días), Flutter
    // cerraría la app con un error.
    final ayer = DateTime.now().subtract(const Duration(days: 1));
    final primera = actual.isBefore(ayer) ? actual : ayer;
    final ultima = DateTime.now().add(const Duration(days: 365));
    final fecha = await showDatePicker(
      context: context,
      initialDate: actual.isAfter(ultima) ? ultima : actual,
      firstDate: primera,
      lastDate: ultima,
    );
    if (fecha == null || !mounted) return null;
    final hora = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(actual));
    if (hora == null) return null;
    return DateTime(fecha.year, fecha.month, fecha.day, hora.hour, hora.minute);
  }

  Future<void> _guardar() async {
    if (!_formulario.currentState!.validate()) return;
    final errorFechas = Validaciones.fechasEvento(_inicia, _termina);
    if (errorFechas != null) {
      _mensaje(errorFechas);
      return;
    }
    final cada = int.tryParse(_cadaDias.text.trim());
    final veces = int.tryParse(_veces.text.trim());
    if (_esNuevo && _repite) {
      final error = Validaciones.repeticion(cadaDias: cada, veces: veces, duracion: _termina.difference(_inicia));
      if (error != null) {
        _mensaje(error);
        return;
      }
    }
    final datos = DatosEvento(
      titulo: _titulo.text,
      descripcion: _descripcion.text,
      lugarId: _lugarId!,
      inicia: _inicia,
      termina: _termina,
      estado: _estado,
      esGratuito: _gratuito,
      costoAproxMxn: int.tryParse(_costo.text.trim()),
    );
    setState(() => _guardando = true);
    try {
      if (_esNuevo && _repite) {
        await _servicio.crearVarios(DatosEvento.repetir(datos, cadaDias: cada!, veces: veces!));
      } else if (_esNuevo) {
        await _servicio.crear(datos);
      } else {
        await _servicio.actualizar(widget.evento!.id, datos);
      }
      if (mounted) Navigator.of(context).pop(true);
    } on ErrorVeraGo catch (e) {
      _mensaje(e.mensaje);
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  void _mensaje(String texto) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));

  String _formato(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year} · '
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_esNuevo ? 'Nuevo evento' : 'Editar evento')),
      body: FutureBuilder<List<Lugar>>(
        future: _lugares,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return EstadoVacio(
              icono: Icons.wifi_off,
              titulo: 'Algo salió mal',
              mensaje: snapshot.error.toString(),
            );
          }
          return _formularioEvento(snapshot.data!);
        },
      ),
    );
  }

  static const _meses = ['ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sep', 'oct', 'nov', 'dic'];

  /// "Se repite": cada N días, M veces, con vista previa de las fechas.
  List<Widget> _repeticion() {
    final cada = int.tryParse(_cadaDias.text.trim());
    final veces = int.tryParse(_veces.text.trim());
    final error = _repite
        ? Validaciones.repeticion(cadaDias: cada, veces: veces, duracion: _termina.difference(_inicia))
        : null;
    String hora(DateTime d) => '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    final fechas = _repite && error == null
        ? [for (var i = 0; i < veces!; i++) _inicia.add(Duration(days: i * cada!))]
        : const <DateTime>[];
    Widget numero(TextEditingController c, String etiqueta, String sufijo) => Expanded(
          child: TextField(
            controller: c,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(2)],
            decoration: InputDecoration(labelText: etiqueta, suffixText: sufijo, border: const OutlineInputBorder()),
            onChanged: (_) => setState(() {}),
          ),
        );
    return [
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: const Text('Se repite'),
        subtitle: const Text('Crea varias fechas con la misma hora de inicio y fin.'),
        value: _repite,
        onChanged: (v) => setState(() => _repite = v),
      ),
      if (_repite) ...[
        Row(
          children: [
            numero(_cadaDias, 'Cada', 'días'),
            const SizedBox(width: 12),
            numero(_veces, 'Cuántas veces', 'veces'),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          error ??
              'Se crearán ${fechas.length} eventos, de ${hora(_inicia)} a ${hora(_termina)}: '
                  '${fechas.map((f) => '${f.day} ${_meses[f.month - 1]}').join(', ')}. '
                  'Cada fecha se puede editar o cancelar por separado.',
          style: TextStyle(fontSize: 13, color: error != null ? const Color(0xFF9B2C2C) : Colors.black.withValues(alpha: 0.7)),
        ),
      ],
    ];
  }

  Widget _formularioEvento(List<Lugar> lugares) {
    // Si el lugar guardado ya no existe en la lista, se pide elegir otro.
    if (_lugarId != null && !lugares.any((l) => l.id == _lugarId)) _lugarId = null;
    return Form(
      key: _formulario,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        children: [
          TextFormField(
            controller: _titulo,
            decoration: const InputDecoration(labelText: 'Título', border: OutlineInputBorder()),
            inputFormatters: Validaciones.nombreNegocioFormato(maximo: 80),
            validator: Validaciones.nombreNegocio('el título', maximo: 80),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _descripcion,
            maxLines: 3,
            maxLength: 400,
            decoration: const InputDecoration(labelText: 'Descripción', border: OutlineInputBorder()),
            validator: Validaciones.textoConLetras('la descripción', opcional: true),
          ),
          const SizedBox(height: 4),
          DropdownButtonFormField<String>(
            initialValue: _lugarId,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Lugar', border: OutlineInputBorder()),
            items: [
              for (final l in lugares) DropdownMenuItem(value: l.id, child: Text(l.nombre)),
            ],
            onChanged: (v) => setState(() => _lugarId = v),
            validator: (v) => v == null ? 'Elige el lugar del evento' : null,
          ),
          const SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.play_arrow_outlined),
            title: const Text('Inicia'),
            subtitle: Text(_formato(_inicia)),
            trailing: const Icon(Icons.edit_calendar_outlined),
            onTap: () async {
              final f = await _elegirFechaHora(_inicia);
              if (f == null) return;
              setState(() {
                // Si el fin quedaba antes del nuevo inicio, se mueve igual.
                final duracion = _termina.difference(_inicia);
                _inicia = f;
                if (!_termina.isAfter(_inicia)) _termina = _inicia.add(duracion);
              });
            },
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.stop_outlined),
            title: const Text('Termina'),
            subtitle: Text(_formato(_termina)),
            trailing: const Icon(Icons.edit_calendar_outlined),
            onTap: () async {
              final f = await _elegirFechaHora(_termina);
              if (f != null) setState(() => _termina = f);
            },
          ),
          if (_esNuevo) ..._repeticion(),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Gratuito'),
            value: _gratuito,
            onChanged: (v) => setState(() => _gratuito = v),
          ),
          if (!_gratuito)
            TextFormField(
              controller: _costo,
              keyboardType: TextInputType.number,
              inputFormatters: Validaciones.soloNumeros(6),
              decoration: const InputDecoration(
                labelText: 'Costo aproximado (pesos)',
                helperText: 'Si lo dejas vacío, la agenda dirá "Con costo".',
                prefixText: '\$ ',
                border: OutlineInputBorder(),
              ),
              validator: Validaciones.precio(),
            ),
          const SizedBox(height: 16),
          const Text('Estado', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'publicado', label: Text('Publicado')),
              ButtonSegment(value: 'pendiente', label: Text('Borrador')),
              ButtonSegment(value: 'cancelado', label: Text('Cancelado')),
            ],
            selected: {_estado},
            onSelectionChanged: (s) => setState(() => _estado = s.first),
          ),
          const SizedBox(height: 6),
          Text(
            switch (_estado) {
              'publicado' => 'Todos lo ven en la agenda.',
              'pendiente' => 'Solo lo ven los administradores.',
              _ => 'Se muestra tachado para avisar que se canceló.',
            },
            style: TextStyle(fontSize: 13, color: Colors.black.withValues(alpha: 0.65)),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _guardando ? null : _guardar,
            child: Text(_guardando
                ? 'Guardando…'
                : (_esNuevo ? (_repite ? 'Crear eventos' : 'Crear evento') : 'Guardar cambios')),
          ),
        ],
      ),
    );
  }
}
