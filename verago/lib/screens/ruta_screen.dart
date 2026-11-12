import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../models/lugar.dart';
import '../services/distancia.dart';
import '../services/rutas_service.dart';
import '../theme/app_theme.dart';
import '../widgets/categoria_estilo.dart';
import '../widgets/estado_vacio.dart';
import '../widgets/etiqueta.dart';
import '../widgets/mapa_lugares.dart';
import 'lugar_screen.dart';

/// RESULTADO DE LA RUTA: mapa con la línea del recorrido y la lista de
/// paradas con hora de llegada, caminata, tiempo de visita y motivo.
///
/// La ruta se puede modificar: "Quitar" saca una parada y vuelve a generar
/// el recorrido sin ella. Al final, si sobra tiempo, sugiere un comercio
/// cercano para seguir explorando.
class RutaScreen extends StatefulWidget {
  const RutaScreen({super.key, required this.peticion, required this.lugares});

  final PeticionRuta peticion;
  final List<Lugar> lugares;

  @override
  State<RutaScreen> createState() => _RutaScreenState();
}

class _RutaScreenState extends State<RutaScreen> {
  final _servicio = RutasService();
  late PeticionRuta _peticion;
  late Ruta _ruta;

  @override
  void initState() {
    super.initState();
    _peticion = widget.peticion;
    _ruta = _servicio.generar(_peticion, widget.lugares);
  }

  void _quitar(Lugar lugar) {
    setState(() {
      _peticion = PeticionRuta(
        inicio: _peticion.inicio,
        nombreInicio: _peticion.nombreInicio,
        horaInicio: _peticion.horaInicio,
        minutosDisponibles: _peticion.minutosDisponibles,
        intereses: _peticion.intereses,
        ritmo: _peticion.ritmo,
        excluir: {..._peticion.excluir, lugar.id},
      );
      _ruta = _servicio.generar(_peticion, widget.lugares);
    });
  }

  String _hora(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  /// Título de la ruta según los intereses (ej. "Historia y sabores").
  String _titulo() {
    final i = _peticion.intereses;
    final historia = i.contains('historia') || i.contains('museo');
    final sabores = i.contains('restaurante') || i.contains('cafeteria');
    if (historia && sabores) return 'Entre historia y sabores';
    if (historia) return 'Recorrido histórico';
    if (sabores) return 'Ruta de sabores';
    return 'Tu recorrido por el centro';
  }

  @override
  Widget build(BuildContext context) {
    final paradas = _ruta.paradas;
    if (paradas.isEmpty) {
      return Scaffold(
        appBar: AppBar(),
        body: EstadoVacio(
          icono: Icons.route_outlined,
          titulo: 'No encontramos una ruta',
          mensaje: 'Con ese tiempo, horario o intereses no alcanzamos a incluir lugares '
              'abiertos. Prueba con más tiempo o elige más intereses.',
          textoBoton: 'Cambiar preferencias',
          alPresionar: () => Navigator.of(context).pop(),
        ),
      );
    }

    final linea = <LatLng>[_peticion.inicio, ...paradas.map((p) => p.lugar.punto)];
    final incluidos = paradas.map((p) => p.lugar.id).toSet();
    final sugerencia = _ruta.minutosLibres >= 15
        ? _servicio.sugerenciaCercana(paradas.last.lugar.punto, widget.lugares, incluidos)
        : null;

    return Scaffold(
      appBar: AppBar(title: Text(_titulo())),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          SizedBox(
            height: 260,
            child: MapaLugares(
              lugares: paradas.map((p) => p.lugar).toList(),
              centro: paradas.first.lugar.punto,
              zoom: 15.5,
              linea: linea,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              '${paradas.length} paradas · ${_ruta.minutosCaminando} min caminando · '
              'termina a las ${_hora(_ruta.fin)}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          for (var i = 0; i < paradas.length; i++) _paradaTile(i + 1, paradas[i]),
          if (paradas.any((p) => p.lugar.horarios.isEmpty))
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Text(
                'Algunos lugares no tienen horario cargado: confirma en el lugar antes de ir. '
                'Los tiempos de caminata son aproximados.',
                style: TextStyle(fontSize: 12, color: Colors.black.withValues(alpha: 0.6)),
              ),
            ),
          if (sugerencia != null) _tarjetaSugerencia(sugerencia),
        ],
      ),
    );
  }

  Widget _paradaTile(int numero, Parada p) {
    final estilo = CategoriaEstilo.de(p.lugar.categoriaClave);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: estilo.color,
                  child: Text('$numero',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(p.lugar.nombre,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                ),
                Text(_hora(p.llegada), style: const TextStyle(fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${p.minutosCaminando} min caminando · visita sugerida ${p.lugar.duracionVisitaMin} min',
              style: TextStyle(color: Colors.black.withValues(alpha: 0.65)),
            ),
            const SizedBox(height: 4),
            Text(p.motivo, style: const TextStyle(fontStyle: FontStyle.italic)),
            if (p.lugar.esDemo) ...[
              const SizedBox(height: 6),
              const Etiqueta.demo(),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _quitar(p.lugar),
                  icon: const Icon(Icons.remove_circle_outline),
                  label: const Text('Quitar'),
                ),
                TextButton.icon(
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => LugarScreen(lugar: p.lugar, todos: widget.lugares),
                  )),
                  icon: const Icon(Icons.info_outline),
                  label: const Text('Ver ficha'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Recomendación contextual: "Te quedan X min. Cerca de tu última parada…"
  Widget _tarjetaSugerencia(Lugar s) {
    final min = Distancia.minutosCaminando(_ruta.paradas.last.lugar.punto, s.punto);
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      color: VgColores.azulGolfo.withValues(alpha: 0.06),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: Icon(CategoriaEstilo.de(s.categoriaClave).icono, color: VgColores.azulGolfo),
        title: Text('Te quedan ${_ruta.minutosLibres} min libres'),
        subtitle: Text('A $min min de tu última parada está ${s.nombre}. ¿Por qué no vas?'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => LugarScreen(lugar: s, todos: widget.lugares),
        )),
      ),
    );
  }
}
