import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show LengthLimitingTextInputFormatter;

import 'package:latlong2/latlong.dart';

import '../models/lugar.dart';
import '../services/distancia.dart';
import '../services/error_verago.dart';
import '../services/geocodificacion_service.dart';
import '../services/lugares_service.dart';
import '../services/ubicacion_service.dart';
import '../theme/app_theme.dart';
import '../widgets/boton_emergencia.dart';
import '../widgets/categoria_estilo.dart';
import '../widgets/estado_vacio.dart';
import '../widgets/etiqueta.dart';
import '../widgets/mapa_lugares.dart';
import '../widgets/tarjeta_lugar.dart';
import 'chat_guia_screen.dart';
import 'lugar_screen.dart';

/// EXPLORAR: descubre los lugares del centro en un mapa o en una lista.
///
/// Cómo funciona:
/// 1. Al abrir, pide los lugares a `LugaresService` (una sola vez).
/// 2. `FutureBuilder` muestra "cargando", luego los datos o un error.
/// 3. Búsqueda y filtros se aplican en el celular sobre la lista ya cargada
///    (son pocos lugares, no hace falta volver a pedirlos).
/// 3b. "Buscar en el mapa": si lo que busca no es un lugar de VeraGo (ej.
///    "Tecnológico"), se busca en OpenStreetMap (Nominatim) y se muestra con
///    un pin morado. Solo al tocar el botón o "buscar" en el teclado (regla de
///    Nominatim), y solo se envía el texto. No se guarda.
/// 4. Al abrir, pide la ubicación UNA vez (si la persona da permiso) para
///    el punto azul y medir distancias desde ella; si no, usa el Zócalo.
///    El botón "Mostrar dónde estoy" la vuelve a pedir. No se guarda ni se
///    envía a nadie.
class ExplorarScreen extends StatefulWidget {
  const ExplorarScreen({super.key});

  @override
  State<ExplorarScreen> createState() => _ExplorarScreenState();
}

class _ExplorarScreenState extends State<ExplorarScreen> {
  final _servicio = LugaresService();
  late Future<List<Lugar>> _futuro;

  String _busqueda = '';
  String? _categoria; // clave de la categoría elegida; null = todas
  bool _verMapa = true;
  Lugar? _seleccionado;

  /// Resultados de OpenStreetMap para la búsqueda actual.
  List<LugarDelMapa> _delMapa = const [];
  LugarDelMapa? _delMapaSeleccionado;
  bool _buscandoEnMapa = false;

  Future<void> _buscarEnMapa() async {
    final texto = _busqueda.trim();
    if (texto.length < 3) {
      _aviso('Escribe al menos 3 letras para buscar en el mapa.');
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _buscandoEnMapa = true);
    final resultados = await GeocodificacionService().buscar(texto);
    if (!mounted) return;
    setState(() {
      _buscandoEnMapa = false;
      _delMapa = resultados;
      _delMapaSeleccionado = resultados.isEmpty ? null : resultados.first;
      _seleccionado = null;
      if (resultados.isNotEmpty) _verMapa = true;
    });
    if (resultados.isEmpty) _aviso('No encontramos "$texto" en el mapa de Veracruz.');
  }

  /// Dónde está el turista (null = no la ha pedido o está lejos del centro).
  LatLng? _miUbicacion;
  bool _buscandoUbicacion = false;

  /// Si está a más de esto del Zócalo, no está en el centro: seguimos
  /// midiendo desde el Zócalo (si no, todo diría "a 300 km").
  static const _metrosMaximos = 15000;

  /// Desde dónde se miden las distancias.
  LatLng get _origen => _miUbicacion ?? Distancia.zocalo;

  /// Texto de arriba. Antes decía siempre "Centro Histórico" aunque la
  /// persona estuviera en otro lado (ej. en el Tecnológico).
  /// Con su ubicación, decimos a cuánto está del Centro Histórico (se
  /// calcula en el celular; no se envía a nadie).
  String get _textoZona {
    final yo = _miUbicacion;
    if (yo == null) return 'Mostrando el Centro Histórico · distancias desde el Zócalo';
    final metros = Distancia.metros(Distancia.zocalo, yo);
    if (metros <= _metrosCentro) return 'Estás en el Centro Histórico · distancias desde donde estás';
    return 'Estás a ${(metros / 1000).toStringAsFixed(1)} km del Centro Histórico · '
        'distancias desde donde estás';
  }

  /// Radio aproximado del Centro Histórico alrededor del Zócalo.
  static const _metrosCentro = 1200;

  /// automatico = true al abrir la app: si no hay permiso o GPS, no
  /// molestamos con mensajes y seguimos desde el Zócalo.
  Future<void> _mostrarDondeEstoy({bool automatico = false}) async {
    if (!automatico) setState(() => _buscandoUbicacion = true);
    try {
      final yo = await UbicacionService().obtenerUbicacion();
      if (!mounted) return;
      if (Distancia.metros(Distancia.zocalo, yo) > _metrosMaximos) {
        setState(() => _miUbicacion = null);
        if (!automatico) {
          _aviso('Estás lejos del Centro Histórico. Seguimos midiendo las distancias desde el Zócalo.');
        }
      } else {
        setState(() => _miUbicacion = yo);
      }
    } on ErrorVeraGo catch (e) {
      if (!automatico) _aviso(e.mensaje);
    } catch (_) {
      // Celular o navegador sin GPS: seguimos desde el Zócalo.
    } finally {
      if (mounted && !automatico) setState(() => _buscandoUbicacion = false);
    }
  }

  void _aviso(String texto) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));
  }

  /// Texto del buscador (para poder borrarlo con la "X" o al actualizar).
  final _buscador = TextEditingController();

  @override
  void initState() {
    super.initState();
    _futuro = _cargarLugares();
    _mostrarDondeEstoy(automatico: true);
  }

  /// Lugares ya descargados (el chat de la guía los usa sin volver a pedirlos).
  List<Lugar>? _cargados;

  Future<List<Lugar>> _cargarLugares() async {
    final lugares = await _servicio.obtenerLugares();
    if (mounted) setState(() => _cargados = lugares);
    return lugares;
  }

  void _abrirGuia(List<Lugar> lugares) => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => ChatGuiaScreen(lugares: lugares)),
      );

  @override
  void dispose() {
    _buscador.dispose();
    super.dispose();
  }

  /// Borra la búsqueda, el filtro y la selección, y cierra el teclado.
  void _limpiarBusqueda() {
    _buscador.clear();
    FocusScope.of(context).unfocus();
    setState(() {
      _busqueda = '';
      _categoria = null;
      _seleccionado = null;
      _delMapa = const [];
      _delMapaSeleccionado = null;
    });
  }

  // setState con llaves { }: con "=>" devolvería el Future y Flutter lo rechaza.
  // ..ignore(): el error (si no hay internet) ya lo muestra el FutureBuilder;
  // así no se reporta como "error no atendido" si llega antes de dibujar.
  /// "Actualizar": vuelve a pedir los lugares y empieza de cero
  /// (antes se quedaba la última búsqueda escrita).
  void _recargar() {
    _limpiarBusqueda();
    setState(() {
      _futuro = _cargarLugares()..ignore();
    });
  }

  /// Quita acentos y mayúsculas para que "cafe" encuentre "Café".
  String _normalizar(String texto) {
    const conAcento = 'áéíóúüñ';
    const sinAcento = 'aeiouun';
    var r = texto.toLowerCase();
    for (var i = 0; i < conAcento.length; i++) {
      r = r.replaceAll(conAcento[i], sinAcento[i]);
    }
    return r;
  }

  List<Lugar> _filtrar(List<Lugar> lugares) {
    final q = _normalizar(_busqueda.trim());
    final resultado = lugares.where((l) {
      final coincideCategoria = _categoria == null || l.categoriaClave == _categoria;
      final coincideTexto = q.isEmpty ||
          _normalizar(l.nombre).contains(q) ||
          _normalizar(l.descripcion ?? '').contains(q);
      return coincideCategoria && coincideTexto;
    }).toList();
    // Los más cercanos primero.
    resultado.sort((a, b) => Distancia.metros(_origen, a.punto)
        .compareTo(Distancia.metros(_origen, b.punto)));
    return resultado;
  }

  void _abrirFicha(Lugar lugar, List<Lugar> todos) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => LugarScreen(lugar: lugar, todos: todos)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cargados = _cargados;
    // Se esconde si hay una tarjeta abierta en el mapa (para no taparla).
    final mostrarGuia = cargados != null && _seleccionado == null && _delMapaSeleccionado == null;
    return Scaffold(
      floatingActionButton: mostrarGuia
          ? FloatingActionButton.extended(
              heroTag: 'guia-ia',
              onPressed: () => _abrirGuia(cargados),
              icon: const Icon(Icons.auto_awesome),
              label: const Text('Pregúntale a VeraGo'),
            )
          : null,
      appBar: AppBar(
        title: const Text('Explorar'),
        actions: [
          BotonEmergencia.icono(context),
          // La pestaña queda abierta en memoria; con esto se ven los
          // negocios recién aprobados sin cerrar la app.
          IconButton(tooltip: 'Actualizar', icon: const Icon(Icons.refresh), onPressed: _recargar),
        ],
      ),
      body: FutureBuilder<List<Lugar>>(
        future: _futuro,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return EstadoVacio(
              icono: Icons.wifi_off,
              titulo: 'Algo salió mal',
              mensaje: snapshot.error.toString(),
              textoBoton: 'Reintentar',
              alPresionar: _recargar,
            );
          }
          final todos = snapshot.data!;
          if (todos.isEmpty) {
            return const EstadoVacio(
              icono: Icons.map_outlined,
              titulo: 'Aún no hay lugares',
              mensaje: 'Cuando se carguen lugares en la base de datos, aparecerán aquí.',
            );
          }
          return _contenido(todos);
        },
      ),
    );
  }

  Widget _contenido(List<Lugar> todos) {
    final filtrados = _filtrar(todos);

    // Categorías que existen en los datos, sin repetir, para los filtros.
    final categorias = <String, String>{};
    for (final l in todos) {
      categorias[l.categoriaClave] = l.categoriaNombre;
    }

    return Column(
      children: [
        // Zona y punto de partida
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Row(
            children: [
              const Icon(Icons.place_outlined, size: 18, color: VgColores.azulGolfo),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  _textoZona,
                  style: TextStyle(color: Colors.black.withValues(alpha: 0.65)),
                ),
              ),
            ],
          ),
        ),
        // Buscador
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            controller: _buscador,
            textInputAction: TextInputAction.search,
            inputFormatters: [LengthLimitingTextInputFormatter(80)],
            // "Buscar" en el teclado: si no hay nada en VeraGo, busca en el mapa.
            onSubmitted: (_) {
              FocusScope.of(context).unfocus(); // cierra el teclado
              if (filtrados.isEmpty) _buscarEnMapa();
            },
            onTapOutside: (_) => FocusScope.of(context).unfocus(),
            decoration: InputDecoration(
              hintText: 'Busca un lugar, café, museo…',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _busqueda.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Borrar búsqueda',
                      icon: const Icon(Icons.close),
                      onPressed: _limpiarBusqueda,
                    ),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (texto) => setState(() {
              _busqueda = texto;
              // Lo encontrado antes en el mapa era de otra búsqueda.
              _delMapa = const [];
              _delMapaSeleccionado = null;
            }),
          ),
        ),
        // Buscar cualquier lugar de Veracruz, aunque no esté en VeraGo.
        if (_busqueda.trim().length >= 3)
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(left: 8),
              child: TextButton.icon(
                onPressed: _buscandoEnMapa ? null : _buscarEnMapa,
                icon: _buscandoEnMapa
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.travel_explore),
                label: Text(_delMapa.isEmpty
                    ? 'Buscar "${_busqueda.trim()}" en todo el mapa'
                    : '${_delMapa.length} en el mapa de OpenStreetMap'),
              ),
            ),
          ),
        // Filtros por categoría
        SizedBox(
          height: 52,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: const Text('Todos'),
                  selected: _categoria == null,
                  onSelected: (_) => setState(() => _categoria = null),
                ),
              ),
              for (final entrada in categorias.entries)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    avatar: Icon(CategoriaEstilo.de(entrada.key).icono, size: 18),
                    label: Text(entrada.value),
                    selected: _categoria == entrada.key,
                    onSelected: (_) => setState(() {
                      _categoria = _categoria == entrada.key ? null : entrada.key;
                    }),
                  ),
                ),
            ],
          ),
        ),
        // Cambiar entre mapa y lista
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: true, icon: Icon(Icons.map_outlined), label: Text('Mapa')),
              ButtonSegment(value: false, icon: Icon(Icons.list), label: Text('Lista')),
            ],
            selected: {_verMapa},
            onSelectionChanged: (s) => setState(() => _verMapa = s.first),
          ),
        ),
        Expanded(
          child: filtrados.isEmpty && _delMapa.isEmpty
              ? EstadoVacio(
                  icono: Icons.search_off,
                  titulo: 'Sin resultados en VeraGo',
                  mensaje: _busqueda.trim().length >= 3
                      ? 'Puedes buscarlo en todo el mapa de Veracruz.'
                      : 'Prueba con otra palabra o quita el filtro.',
                  textoBoton: _busqueda.trim().length >= 3 ? 'Buscar en el mapa' : null,
                  alPresionar: _busqueda.trim().length >= 3 ? _buscarEnMapa : null,
                )
              : _verMapa
                  ? _mapa(filtrados, todos)
                  : _lista(filtrados, todos),
        ),
      ],
    );
  }

  Widget _lista(List<Lugar> filtrados, List<Lugar> todos) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 88), // espacio para el botón de la guía
      children: [
        for (final l in filtrados)
          TarjetaLugar(lugar: l, desde: _origen, alTocar: () => _abrirFicha(l, todos)),
        if (_delMapa.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text('En el mapa (OpenStreetMap, no son parte de VeraGo)',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
          for (final o in _delMapa)
            ListTile(
              leading: const Icon(Icons.location_on, color: Color(0xFF6A1B9A)),
              title: Text(o.nombre),
              subtitle: Text('${Distancia.texto(_origen, o.punto)}${o.direccion != null ? ' · ${o.direccion}' : ''}'),
              onTap: () => setState(() {
                _delMapaSeleccionado = o;
                _seleccionado = null;
                _verMapa = true;
              }),
            ),
        ],
      ],
    );
  }

  Widget _mapa(List<Lugar> filtrados, List<Lugar> todos) {
    final seleccionado = _seleccionado;
    return Stack(
      children: [
        MapaLugares(
          // Los comerciantes informales están en la misma coordenada que su
          // Punto VeraGo: en el mapa se ve solo el punto (y en su ficha, ellos).
          lugares: filtrados.where((l) => !l.esInformal).toList(),
          centro: Distancia.zocalo,
          seleccionadoId: seleccionado?.id,
          alTocarLugar: (l) => setState(() {
            _seleccionado = l;
            _delMapaSeleccionado = null;
          }),
          delMapa: _delMapa,
          enfocar: _delMapaSeleccionado?.punto,
          alTocarDelMapa: (o) => setState(() {
            _delMapaSeleccionado = o;
            _seleccionado = null;
          }),
          miUbicacion: _miUbicacion,
          alPedirUbicacion: _mostrarDondeEstoy,
          buscandoUbicacion: _buscandoUbicacion,
        ),
        // Ficha resumida del marcador tocado
        // Tarjeta de un lugar del mapa (OpenStreetMap).
        if (_delMapaSeleccionado case final o?)
          Positioned(
            left: 12,
            right: 12,
            bottom: 12,
            child: Card(
              child: ListTile(
                leading: const Icon(Icons.location_on, color: Color(0xFF6A1B9A)),
                title: Text(o.nombre, style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text('${Distancia.texto(_origen, o.punto)}'
                    '${o.direccion != null ? '\n${o.direccion}' : ''}'
                    '\nLugar de OpenStreetMap: no es parte de VeraGo.'),
                isThreeLine: true,
                trailing: IconButton(
                  tooltip: 'Cerrar',
                  icon: const Icon(Icons.close),
                  onPressed: () => setState(() => _delMapaSeleccionado = null),
                ),
              ),
            ),
          ),
        if (seleccionado != null && filtrados.contains(seleccionado))
          Positioned(
            left: 12,
            right: 12,
            bottom: 12,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            seleccionado.nombre,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                        IconButton(
                          tooltip: 'Cerrar',
                          icon: const Icon(Icons.close),
                          onPressed: () => setState(() => _seleccionado = null),
                        ),
                      ],
                    ),
                    Text(
                      '${seleccionado.categoriaNombre} · '
                      '${Distancia.texto(_origen, seleccionado.punto)}',
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        Etiqueta.apertura(seleccionado.estadoEn(DateTime.now())),
                        if (seleccionado.esDemo) const Etiqueta.demo(),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () => _abrirFicha(seleccionado, todos),
                        child: const Text('Ver ficha'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
