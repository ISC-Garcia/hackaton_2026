import 'package:flutter/material.dart';

import '../models/lugar.dart';
import '../services/distancia.dart';
import '../services/lugares_service.dart';
import '../theme/app_theme.dart';
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
/// 4. Las distancias se miden desde el Zócalo, así no pedimos permiso de
///    ubicación solo para explorar.
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

  @override
  void initState() {
    super.initState();
    _futuro = _servicio.obtenerLugares();
  }

  // setState con llaves { }: con "=>" devolvería el Future y Flutter lo rechaza.
  // ..ignore(): el error (si no hay internet) ya lo muestra el FutureBuilder;
  // así no se reporta como "error no atendido" si llega antes de dibujar.
  void _recargar() => setState(() {
        _futuro = _servicio.obtenerLugares()..ignore();
      });

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
    resultado.sort((a, b) => Distancia.metros(Distancia.zocalo, a.punto)
        .compareTo(Distancia.metros(Distancia.zocalo, b.punto)));
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
      appBar: AppBar(title: const Text('Explorar')),
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
                  'Centro Histórico · distancias desde el Zócalo',
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
            decoration: InputDecoration(
              hintText: 'Busca un lugar, café, museo…',
              prefixIcon: const Icon(Icons.search),
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
        desde: Distancia.zocalo,
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
                      '${Distancia.texto(Distancia.zocalo, seleccionado.punto)}',
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
