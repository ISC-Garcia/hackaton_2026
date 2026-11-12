import 'package:flutter/material.dart';

import '../services/estadisticas_service.dart';
import '../theme/app_theme.dart';
import '../widgets/estado_vacio.dart';

/// ESTADÍSTICAS.
///
/// Dos modos (selector arriba):
/// - DEMOSTRACIÓN (por defecto, decisión del equipo): números FICTICIOS
///   para la demo del hackatón, porque todavía casi no hay uso real.
///   Siempre con el aviso "DATOS FICTICIOS".
/// - REALES (SQL 016): lo que de verdad hay en la base de datos.
///
/// - Admin (`deMiNegocio = false`): uso de toda la app.
/// - Comerciante (`deMiNegocio = true`): sellos que dio su negocio.
///
/// Solo se muestran TOTALES: nunca nombres ni correos de turistas.
/// Límite importante: esto mide el uso de la app, NO cuántas personas
/// caminan por el centro.
class EstadisticasScreen extends StatefulWidget {
  const EstadisticasScreen({super.key, this.deMiNegocio = false, this.cargadorDePrueba});

  final bool deMiNegocio;

  /// SOLO para pruebas automáticas: datos falsos sin Supabase.
  final Future<Estadisticas> Function()? cargadorDePrueba;

  @override
  State<EstadisticasScreen> createState() => _EstadisticasScreenState();
}

class _EstadisticasScreenState extends State<EstadisticasScreen> {
  /// Datos reales: se piden solo cuando se elige "Reales".
  Future<Estadisticas>? _futuro;

  /// true = números ficticios de demostración (por defecto).
  bool _ficticio = true;

  // ---- Números FICTICIOS para la demo (los mismos de la primera versión) ----
  static const _lugaresVistos = {
    'Zócalo de Veracruz': 120,
    'Malecón de Veracruz': 95,
    'Café Brisa del Golfo': 64,
    'Museo Naval México': 51,
    'Cocina La Marea': 38,
  };
  static const _sellosPorDia = {
    'Lun': 12,
    'Mar': 9,
    'Mié': 15,
    'Jue': 11,
    'Vie': 22,
    'Sáb': 34,
    'Dom': 29,
  };
  static const _sellosMiNegocioPorDia = {
    'Lun': 3,
    'Mar': 2,
    'Mié': 4,
    'Jue': 3,
    'Vie': 6,
    'Sáb': 9,
    'Dom': 7,
  };

  List<Widget> _demostracion() => [
        const _Aviso('DATOS FICTICIOS de demostración. Miden uso de la app, no la cantidad real de personas '
            'en el centro.', ficticio: true),
        const SizedBox(height: 12),
        if (widget.deMiNegocio) ...[
          const Row(children: [
            _Dato('5', 'sellos hoy'),
            _Dato('34', 'en 7 días'),
            _Dato('87', 'en total'),
          ]),
          const Row(children: [_Dato('64', 'turistas distintos')]),
          const _Grafica(titulo: 'Sellos por día', datos: _sellosMiNegocioPorDia),
        ] else ...[
          const Row(children: [
            _Dato('214', 'rutas generadas'),
            _Dato('132', 'sellos'),
            _Dato('3.1', 'lugares por visitante'),
          ]),
          const _Grafica(titulo: 'Lugares más consultados (vistas de ficha)', datos: _lugaresVistos),
          const _Grafica(titulo: 'Sellos registrados por día', datos: _sellosPorDia),
        ],
      ];

  Future<Estadisticas> _cargar() {
    final prueba = widget.cargadorDePrueba;
    if (prueba != null) return prueba();
    final s = EstadisticasService();
    return widget.deMiNegocio ? s.deMiNegocio() : s.deLaApp();
  }

  void _recargar() => setState(() {
        _futuro = _cargar()..ignore();
      });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.deMiNegocio ? 'Mis estadísticas' : 'Estadísticas'),
        actions: [IconButton(tooltip: 'Actualizar', icon: const Icon(Icons.refresh), onPressed: _recargar)],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
            child: SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: true, icon: Icon(Icons.science_outlined), label: Text('Demostración')),
                ButtonSegment(value: false, icon: Icon(Icons.query_stats), label: Text('Reales')),
              ],
              selected: {_ficticio},
              onSelectionChanged: (s) => setState(() => _ficticio = s.first),
            ),
          ),
          Expanded(
            child: _ficticio
                ? ListView(padding: const EdgeInsets.all(16), children: _demostracion())
                : _reales(),
          ),
        ],
      ),
    );
  }

  Widget _reales() {
    return FutureBuilder<Estadisticas>(
        future: _futuro ??= _cargar(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return EstadoVacio(
              icono: Icons.query_stats,
              titulo: 'Algo salió mal',
              mensaje: snapshot.error.toString(),
              textoBoton: 'Reintentar',
              alPresionar: _recargar,
            );
          }
          final e = snapshot.data!;
          return RefreshIndicator(
            onRefresh: () async {
              _recargar();
              await _futuro;
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: widget.deMiNegocio ? _deMiNegocio(e) : _deLaApp(e),
            ),
          );
        },
      );
  }

  List<Widget> _deLaApp(Estadisticas e) => [
        const _Aviso('Datos reales de VeraGo. Miden el uso de la app, no la cantidad de personas en el centro.'),
        const SizedBox(height: 12),
        Row(children: [
          _Dato('${e.dato('usuarios')}', 'cuentas'),
          _Dato('${e.dato('turistas_con_sellos')}', 'turistas con sellos'),
          _Dato('${e.dato('sellos_total')}', 'sellos en total'),
        ]),
        Row(children: [
          _Dato('${e.dato('sellos_7_dias')}', 'sellos en 7 días'),
          _Dato('${e.dato('negocios_aprobados')}', 'negocios aprobados'),
          _Dato('${e.dato('negocios_pendientes')}', 'solicitudes pendientes'),
        ]),
        _Grafica(titulo: 'Sellos por día (últimos 14 días)', datos: _porDia(e)),
        if (e.topNegocios.isNotEmpty)
          _Grafica(titulo: 'Negocios con más sellos', datos: e.topNegocios)
        else
          const Padding(
            padding: EdgeInsets.only(top: 24),
            child: Text('Aún no hay sellos registrados.'),
          ),
      ];

  List<Widget> _deMiNegocio(Estadisticas e) => [
        if (e.dato('da_sellos') == 0 && e.datos.containsKey('da_sellos'))
          const _Aviso('Tu negocio no da sellos (solo los negocios formales aprobados).'),
        Row(children: [
          _Dato('${e.dato('sellos_hoy')}', 'sellos hoy'),
          _Dato('${e.dato('sellos_7_dias')}', 'en 7 días'),
          _Dato('${e.dato('sellos_total')}', 'en total'),
        ]),
        Row(children: [
          _Dato('${e.dato('visitantes')}', 'turistas distintos'),
        ]),
        _Grafica(titulo: 'Sellos por día (últimos 14 días)', datos: _porDia(e)),
        const SizedBox(height: 12),
        Text('Cada sello es un turista que escaneó tu QR. No mostramos quiénes son.',
            style: TextStyle(fontSize: 12, color: Colors.black.withValues(alpha: 0.6))),
      ];

  static const _dias = ['dom', 'lun', 'mar', 'mié', 'jue', 'vie', 'sáb'];

  /// "lun 10" → sellos, en orden.
  Map<String, int> _porDia(Estadisticas e) => {
        for (final d in e.porDia) '${_dias[d.fecha.weekday % 7]} ${d.fecha.day}': d.total,
      };
}

class _Aviso extends StatelessWidget {
  const _Aviso(this.texto, {this.ficticio = false});
  final String texto;

  /// true = aviso naranja de datos ficticios.
  final bool ficticio;

  @override
  Widget build(BuildContext context) {
    final color = ficticio ? VgColores.terracota : VgColores.azulGolfo;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: ficticio ? 0.12 : 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(ficticio ? Icons.warning_amber : Icons.info_outline, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(texto, style: TextStyle(fontWeight: ficticio ? FontWeight.w700 : FontWeight.w400)),
          ),
        ],
      ),
    );
  }
}

class _Dato extends StatelessWidget {
  const _Dato(this.numero, this.texto);
  final String numero;
  final String texto;

  @override
  Widget build(BuildContext context) => Expanded(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Text(numero,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: VgColores.azulGolfo)),
                Text(texto, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12)),
              ],
            ),
          ),
        ),
      );
}

/// Barras horizontales hechas con widgets simples (sin librerías extra):
/// el ancho de cada barra es proporcional a su valor.
class _Grafica extends StatelessWidget {
  const _Grafica({required this.titulo, required this.datos});

  final String titulo;
  final Map<String, int> datos;

  @override
  Widget build(BuildContext context) {
    final maximo = datos.values.fold(0, (a, b) => a > b ? a : b);
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titulo, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          for (final e in datos.entries)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  SizedBox(width: 120, child: Text(e.key, overflow: TextOverflow.ellipsis)),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (_, c) => Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          height: 16,
                          // Sin sellos (máximo 0) no se dibuja barra.
                          width: maximo == 0 ? 0 : c.maxWidth * e.value / maximo,
                          decoration: BoxDecoration(
                            color: VgColores.azulGolfo,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 36, child: Text('${e.value}', textAlign: TextAlign.right)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
