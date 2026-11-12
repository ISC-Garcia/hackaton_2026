import 'package:flutter/material.dart';

import '../models/lugar.dart';
import 'package:latlong2/latlong.dart';

import '../services/distancia.dart';
import '../services/error_verago.dart';
import '../services/lugares_service.dart';
import '../services/ubicacion_service.dart';
import '../theme/app_theme.dart';
import '../widgets/boton_emergencia.dart';
import '../widgets/categoria_estilo.dart';
import '../widgets/estado_vacio.dart';
import '../widgets/etiqueta.dart';
import '../widgets/mapa_lugares.dart';
import '../widgets/tarjeta_lugar.dart';
import 'lugar_screen.dart';

/// EXPLORAR: descubre los lugares del centro en un mapa o en una lista.
///
/// Cómo funciona:
/// 1. Al abrir, pide los lugares a `LugaresService` (una sola vez).
/// 2. `FutureBuilder` muestra "cargando", luego los datos o un error.
/// 3. Búsqueda y filtros se aplican en el celular sobre la lista ya cargada
///    (son pocos lugares, no hace falta volver a pedirlos).
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
    _futuro = _servicio.obtenerLugares();
    _mostrarDondeEstoy(automatico: true);
  }

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
      _futuro = _servicio.obtenerLugares()..ignore();
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
    return Scaffold(
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
            onSubmitted: (_) => FocusScope.of(context).unfocus(), // cierra el teclado
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
            onChanged: (texto) => setState(() => _busqueda = texto),
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
          child: filtrados.isEmpty
              ? const EstadoVacio(
                  icono: Icons.search_off,
                  titulo: 'Sin resultados',
                  mensaje: 'Prueba con otra palabra o quita el filtro.',
                )
              : _verMapa
                  ? _mapa(filtrados, todos)
                  : _lista(filtrados, todos),
        ),
      ],
    );
  }

  Widget _lista(List<Lugar> filtrados, List<Lugar> todos) {
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: filtrados.length,
      itemBuilder: (_, i) => TarjetaLugar(
        lugar: filtrados[i],
        desde: _origen,
        alTocar: () => _abrirFicha(filtrados[i], todos),
      ),
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
          alTocarLugar: (l) => setState(() => _seleccionado = l),
          miUbicacion: _miUbicacion,
          alPedirUbicacion: _mostrarDondeEstoy,
          buscandoUbicacion: _buscandoUbicacion,
        ),
        // Ficha resumida del marcador tocado
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
