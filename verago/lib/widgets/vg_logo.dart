import 'package:flutter/material.dart';

import '../i18n/idioma.dart';

/// Logo de VeraGo (archivo assets/logo.png, registrado en pubspec.yaml).
///
/// Se usa en la bienvenida y en el registro de negocios. `semanticLabel`
/// es lo que dice el lector de pantalla (accesibilidad).
class VgLogo extends StatelessWidget {
  const VgLogo({super.key, this.altura = 120});

  final double altura;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/logo.png',
      height: altura,
      fit: BoxFit.contain,
      semanticLabel: tr('Logo de VeraGo'),
    );
  }
}
