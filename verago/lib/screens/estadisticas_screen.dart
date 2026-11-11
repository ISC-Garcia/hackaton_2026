import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// ESTADÍSTICAS (solo administrador) — DATOS SIMULADOS.
///
/// Por qué simulados: en el hackatón no hay uso real todavía. Mostramos
/// cómo se vería el panel, con un aviso claro en pantalla.
///
/// Límite importante: aun con datos reales, esto mide el uso de la app,
/// NO cuántas personas caminan por el centro.
class EstadisticasScreen extends StatelessWidget {
  const EstadisticasScreen({super.key});

  // Números inventados para la demostración.
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Estadísticas')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: VgColores.terracota.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Icon(Icons.warning_amber, color: VgColores.terracota),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'DATOS SIMULADOS. Miden uso de la app, no la cantidad real de personas en el centro.',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const _Resumen(),
          _Grafica(titulo: 'Lugares más consultados (vistas de ficha)', datos: _lugaresVistos),
          _Grafica(titulo: 'Sellos registrados por día', datos: _sellosPorDia),
        ],
      ),
    );
  }
}

class _Resumen extends StatelessWidget {
  const _Resumen();

  @override
  Widget build(BuildContext context) {
    Widget dato(String numero, String texto) => Expanded(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Text(numero,
                      style: const TextStyle(
                          fontSize: 24, fontWeight: FontWeight.w800, color: VgColores.azulGolfo)),
                  Text(texto, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12)),
                ],
              ),
            ),
          ),
        );
    return Row(
      children: [
        dato('214', 'rutas generadas'),
        dato('132', 'sellos'),
        dato('3.1', 'lugares por visitante'),
      ],
    );
  }
}

/// Barras horizontales hechas con widgets simples (sin librerías extra):
/// el ancho de cada barra es proporcional a su valor.
class _Grafica extends StatelessWidget {
  const _Grafica({required this.titulo, required this.datos});

  final String titulo;
  final Map<String, int> datos;

  @override
  Widget build(BuildContext context) {
    final maximo = datos.values.reduce((a, b) => a > b ? a : b);
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titulo, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          for (final e in datos.entries)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  SizedBox(width: 140, child: Text(e.key, overflow: TextOverflow.ellipsis)),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (_, c) => Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          height: 18,
                          width: c.maxWidth * e.value / maximo,
                          decoration: BoxDecoration(
                            color: VgColores.azulGolfo,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 40,
                    child: Text('${e.value}', textAlign: TextAlign.right),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
