import 'package:flutter/material.dart';

import '../models/lugar.dart';
import '../services/distancia.dart';
import '../theme/app_theme.dart';
import '../widgets/etiqueta.dart';
import '../widgets/foto_lugar.dart';
import '../widgets/mapa_lugares.dart';
import '../widgets/reportar_problema.dart';
import '../widgets/tarjeta_lugar.dart';

/// FICHA DEL LUGAR: toda la información de un lugar o comercio.
///
/// Incluye "Cerca de aquí": comercios a pocos minutos caminando.
/// Es el descubrimiento comercial del documento: después de ver un lugar,
/// VeraGo sugiere otro cercano de forma natural, no como publicidad.
class LugarScreen extends StatelessWidget {
  const LugarScreen({super.key, required this.lugar, required this.todos});

  final Lugar lugar;

  /// Todos los lugares (para calcular cuáles están cerca de este).
  final List<Lugar> todos;

  /// Distancia máxima para "Cerca de aquí": 10 minutos caminando.
  static const _minutosCerca = 10;

  static const _dias = ['Domingo', 'Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado'];

  List<Lugar> _comerciosCercanos() {
    final cercanos = todos
        .where((l) =>
            l.id != lugar.id &&
            l.esComercio &&
            l.puntoId != lugar.id && // los del punto ya salen en su propia sección

            Distancia.minutosCaminando(lugar.punto, l.punto) <= _minutosCerca)
        .toList()
      ..sort((a, b) => Distancia.metros(lugar.punto, a.punto)
          .compareTo(Distancia.metros(lugar.punto, b.punto)));
    return cercanos.take(4).toList();
  }

  /// Si este lugar es un Punto VeraGo: los comerciantes que venden aquí.
  List<Lugar> _comerciantesDelPunto() =>
      todos.where((l) => l.puntoId == lugar.id).toList();

  /// Si este lugar es un comerciante informal: su Punto VeraGo.
  Lugar? get _miPunto {
    for (final l in todos) {
      if (l.id == lugar.puntoId) return l;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final cercanos = _comerciosCercanos();
    final delPunto = lugar.esPunto ? _comerciantesDelPunto() : <Lugar>[];
    final miPunto = lugar.esInformal ? _miPunto : null;
    final hoy = DateTime.now().weekday % 7;

    return Scaffold(
      appBar: AppBar(),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          // Encabezado: la foto del lugar (SQL 018); sin foto, bloque de color
          // con el ícono de la categoría.
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: FotoLugar(lugar: lugar, ancho: double.infinity, alto: lugar.fotoUrl == null ? 140 : 200, radio: 20),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(lugar.nombre, style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 4),
                Text(
                  '${lugar.categoriaNombre} · ${Distancia.texto(Distancia.zocalo, lugar.punto)} del Zócalo',
                  style: TextStyle(color: Colors.black.withValues(alpha: 0.65)),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    Etiqueta.apertura(lugar.estadoEn(DateTime.now())),
                    ?Etiqueta.tipoNegocio(lugar),
                    if (lugar.participaPasaporte)
                      const Etiqueta('Da sello en tu pasaporte', color: VgColores.azulGolfo, icono: Icons.approval),
                    if (lugar.esDemo) const Etiqueta.demo(),
                  ],
                ),
                if (lugar.descripcion != null) ...[
                  const SizedBox(height: 16),
                  Text(lugar.descripcion!, style: const TextStyle(fontSize: 16, height: 1.4)),
                ],
                if (lugar.textoEntrada case final entrada?) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.confirmation_number_outlined, size: 20, color: VgColores.azulGolfo),
                      const SizedBox(width: 8),
                      Expanded(child: Text(entrada, style: const TextStyle(fontWeight: FontWeight.w600))),
                    ],
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  'Visita sugerida: ${lugar.duracionVisitaMin} min',
                  style: TextStyle(color: Colors.black.withValues(alpha: 0.65)),
                ),
                // VITRINA DIGITAL: promoción y productos o servicios (SQL 015).
                if (lugar.tieneVitrina) ...[
                  _Seccion('Vitrina'),
                  if (lugar.promocion case final promo?)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: VgColores.terracota.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: VgColores.terracota.withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.local_offer_outlined, color: VgColores.terracota),
                          const SizedBox(width: 10),
                          Expanded(child: Text(promo, style: const TextStyle(fontWeight: FontWeight.w600))),
                        ],
                      ),
                    ),
                  for (final p in lugar.productos)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Expanded(child: Text(p.nombre)),
                          Text(p.precioMxn == null ? '—' : '≈ \$${p.precioMxn}',
                              style: const TextStyle(fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  if (lugar.productos.isNotEmpty)
                    Text('Precios aproximados que da el negocio.',
                        style: TextStyle(fontSize: 12, color: Colors.black.withValues(alpha: 0.55))),
                ],
                // Comerciante informal: en qué Punto VeraGo vende y su giro.
                if (miPunto != null) ...[
                  const SizedBox(height: 16),
                  _Aviso(
                    icono: Icons.storefront_outlined,
                    texto: '${lugar.giroNombre ?? 'Emprendedor local'} · Lo encuentras en '
                        '${miPunto.nombre}, en el horario del punto.',
                  ),
                ],
                // Punto VeraGo: explicación y lista de comerciantes.
                if (lugar.esPunto) ...[
                  const SizedBox(height: 16),
                  const _Aviso(
                    icono: Icons.storefront_outlined,
                    texto: 'Punto VeraGo: mesas de emprendedores locales en un lugar especial '
                        'del centro, con un negocio de cada giro.',
                  ),
                ],
                if (lugar.participaPasaporte) ...[
                  const SizedBox(height: 16),
                  _Aviso(
                    icono: Icons.qr_code_2,
                    texto: 'Pide en el comercio su código QR y escanéalo desde la pestaña '
                        'Pasaporte para ganar su sello.',
                  ),
                ],
                _Seccion('Horario'),
                if (lugar.horarios.isEmpty)
                  const Text('Horario no disponible. Consulta directamente en el lugar.')
                else
                  for (var d = 0; d < 7; d++)
                    _FilaHorario(
                      dia: _dias[d],
                      horario: lugar.horarioDel(d),
                      esHoy: d == hoy,
                    ),
                if (lugar.esDemo && lugar.horarios.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      'Horario ficticio de demostración.',
                      style: TextStyle(fontSize: 12, color: Colors.black.withValues(alpha: 0.55)),
                    ),
                  ),
                if (lugar.direccion != null || lugar.telefono != null) ...[
                  _Seccion('Contacto'),
                  if (lugar.direccion != null)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.place_outlined),
                      title: Text(lugar.direccion!),
                    ),
                  if (lugar.telefono != null)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.phone_outlined),
                      title: Text(lugar.telefono!),
                    ),
                ],
                _Seccion('Ubicación'),
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: SizedBox(
                    height: 180,
                    child: MapaLugares(
                      lugares: [lugar],
                      centro: lugar.punto,
                      zoom: 17,
                      interactivo: false,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Ubicación aproximada.',
                  style: TextStyle(fontSize: 12, color: Colors.black.withValues(alpha: 0.55)),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => ReportarProblema.abrir(context, lugar),
                    icon: const Icon(Icons.flag_outlined),
                    label: const Text('Reportar un problema'),
                  ),
                ),
              ],
            ),
          ),
          if (delPunto.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _Seccion('Comerciantes en este punto'),
            ),
            for (final c in delPunto)
              TarjetaLugar(
                lugar: c,
                desde: lugar.punto,
                alTocar: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => LugarScreen(lugar: c, todos: todos)),
                ),
              ),
          ],
          if (cercanos.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _Seccion('Cerca de aquí'),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
              child: Text(
                'Comercios locales a menos de $_minutosCerca minutos caminando.',
                style: TextStyle(color: Colors.black.withValues(alpha: 0.65)),
              ),
            ),
            for (final c in cercanos)
              TarjetaLugar(
                lugar: c,
                desde: lugar.punto,
                alTocar: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => LugarScreen(lugar: c, todos: todos)),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _Seccion extends StatelessWidget {
  const _Seccion(this.titulo);
  final String titulo;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 24, bottom: 8),
        child: Text(titulo, style: Theme.of(context).textTheme.titleLarge),
      );
}

class _FilaHorario extends StatelessWidget {
  const _FilaHorario({required this.dia, required this.horario, required this.esHoy});

  final String dia;
  final Horario? horario;
  final bool esHoy;

  @override
  Widget build(BuildContext context) {
    final estilo = TextStyle(fontWeight: esHoy ? FontWeight.w700 : FontWeight.w400);
    final h = horario;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(child: Text(esHoy ? '$dia (hoy)' : dia, style: estilo)),
          Text(
            h == null ? 'Cerrado' : '${Horario.formato(h.abre)} – ${Horario.formato(h.cierra)}',
            style: estilo,
          ),
        ],
      ),
    );
  }
}

class _Aviso extends StatelessWidget {
  const _Aviso({required this.icono, required this.texto});
  final IconData icono;
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
            Icon(icono, color: VgColores.azulGolfo),
            const SizedBox(width: 10),
            Expanded(child: Text(texto)),
          ],
        ),
      );
}
