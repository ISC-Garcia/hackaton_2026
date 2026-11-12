import 'package:flutter/material.dart';

import '../services/estadisticas_service.dart';
import '../theme/app_theme.dart';
import '../widgets/estado_vacio.dart';

/// ESTADÍSTICAS REALES (SQL 016): lo que de verdad hay en la base de datos.
/// (Antes había un modo de demostración con números ficticios; el equipo
/// pidió quitarlo y dejar solo los datos reales.)
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
  /// Datos reales de la base de datos.
  late Future<Estadisticas> _futuro = _cargar();

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
      body: _reales(),
    );
  }

  Widget _reales() {
    return FutureBuilder<Estadisticas>(
        future: _futuro,
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
  const _Aviso(this.texto);
  final String texto;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: VgColores.azulGolfo.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.info_outline, color: VgColores.azulGolfo),
            const SizedBox(width: 8),
            Expanded(child: Text(texto)),
          ],
        ),
      );
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
