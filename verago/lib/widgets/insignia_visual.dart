import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/insignia.dart';
import '../theme/app_theme.dart';

/// Dibujo de una insignia. Cada nivel se ve "más importante" que el anterior:
///
/// 1 Visitante        → círculo arena, borde simple.
/// 2 Explorador       → azul golfo, borde doble.
/// 3 Viajero          → verde palma, degradado y sombra.
/// 4 Jarocho          → terracota, degradado, sombra y estrella.
/// 5 Embajador VeraGo → DORADA: degradado, resplandor, estrellas y un brillo
///                      que gira (animación). La más vistosa.
///
/// Sin colores por imagen: todo se dibuja con widgets (no usamos fotos).
class InsigniaVisual extends StatelessWidget {
  const InsigniaVisual({super.key, required this.nivel, this.tamano = 96, this.bloqueada = false});

  /// 1 a 5.
  final int nivel;
  final double tamano;

  /// true = todavía no se gana: se ve gris con candado.
  final bool bloqueada;

  static const _iconos = [
    Icons.directions_walk,
    Icons.explore,
    Icons.map,
    Icons.sailing,
    Icons.workspace_premium,
  ];

  static const _colores = [
    Color(0xFFC9A66B), // arena
    VgColores.azulGolfo,
    VgColores.verdePalma,
    VgColores.terracota,
    Color(0xFFD4A017), // oro
  ];

  @override
  Widget build(BuildContext context) {
    final i = (nivel - 1).clamp(0, 4);
    final nombre = Insignia.niveles[i].nombre;
    if (bloqueada) {
      // Mismo tamaño total que una insignia ganada (tamano × 1.25), para que
      // la fila de los 5 niveles quede alineada.
      return Semantics(
        label: 'Insignia $nombre: bloqueada',
        child: SizedBox.square(
          dimension: tamano * 1.25,
          child: Center(
            child: Container(
              width: tamano,
              height: tamano,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.black26, width: 2),
              ),
              child: Icon(Icons.lock_outline, color: Colors.black26, size: tamano * 0.4),
            ),
          ),
        ),
      );
    }
    final color = _colores[i];
    final base = Container(
      width: tamano,
      height: tamano,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: nivel <= 2 ? color.withValues(alpha: 0.15) : null,
        gradient: nivel >= 3
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: nivel == 5
                    ? const [Color(0xFFFFF1A8), Color(0xFFD4A017), Color(0xFF9C6B00)]
                    : [color.withValues(alpha: 0.55), color],
              )
            : null,
        border: Border.all(color: color, width: nivel >= 2 ? 4 : 2.5),
        boxShadow: [
          if (nivel >= 3) BoxShadow(color: color.withValues(alpha: 0.45), blurRadius: 10, offset: const Offset(0, 4)),
          if (nivel == 5) BoxShadow(color: const Color(0xFFFFD54F).withValues(alpha: 0.9), blurRadius: 22, spreadRadius: 4),
        ],
      ),
      child: Container(
        // Borde doble desde el nivel 2.
        margin: EdgeInsets.all(nivel >= 2 ? tamano * 0.06 : 0),
        decoration: nivel >= 2
            ? BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white.withValues(alpha: 0.8), width: 1.5))
            : null,
        child: Icon(_iconos[i], size: tamano * 0.45, color: nivel >= 3 ? Colors.white : color),
      ),
    );

    return Semantics(
      label: 'Insignia $nombre',
      child: SizedBox(
        width: tamano * 1.25,
        height: tamano * 1.25,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (nivel == 5) _BrilloGiratorio(tamano: tamano * 1.25),
            base,
            if (nivel >= 4) ..._estrellas(nivel == 5 ? 3 : 1),
          ],
        ),
      ),
    );
  }

  /// Estrellitas alrededor (1 en Jarocho, 3 en Embajador).
  List<Widget> _estrellas(int cuantas) {
    const posiciones = [Alignment.topRight, Alignment.topLeft, Alignment.bottomRight];
    return [
      for (var k = 0; k < cuantas; k++)
        Align(
          alignment: posiciones[k],
          child: Icon(Icons.star, size: tamano * 0.24, color: const Color(0xFFFFC107)),
        ),
    ];
  }
}

/// Rayos dorados que giran despacio detrás de la insignia final.
/// `AnimationController` cuenta de 0 a 1 una y otra vez; `RotationTransition`
/// gira el dibujo según ese número.
class _BrilloGiratorio extends StatefulWidget {
  const _BrilloGiratorio({required this.tamano});
  final double tamano;

  @override
  State<_BrilloGiratorio> createState() => _BrilloGiratorioState();
}

class _BrilloGiratorioState extends State<_BrilloGiratorio> with SingleTickerProviderStateMixin {
  late final _giro = AnimationController(vsync: this, duration: const Duration(seconds: 8))..repeat();

  @override
  void dispose() {
    _giro.dispose(); // detener la animación al salir
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RotationTransition(
        turns: _giro,
        child: CustomPaint(size: Size.square(widget.tamano), painter: _Rayos()),
      );
}

class _Rayos extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final centro = size.center(Offset.zero);
    final radio = size.width / 2;
    final pintura = Paint()..color = const Color(0x55FFC107);
    for (var k = 0; k < 12; k++) {
      final a = k * math.pi / 6;
      final camino = Path()
        ..moveTo(centro.dx, centro.dy)
        ..lineTo(centro.dx + radio * math.cos(a - 0.12), centro.dy + radio * math.sin(a - 0.12))
        ..lineTo(centro.dx + radio * math.cos(a + 0.12), centro.dy + radio * math.sin(a + 0.12))
        ..close();
      canvas.drawPath(camino, pintura);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
