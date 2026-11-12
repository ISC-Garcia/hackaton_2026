// Pruebas del módulo de comerciantes:
// - Validaciones (correo, contraseña segura, teléfono).
// - "Soy un negocio" abre en REGISTRO y cambia a INICIO DE SESIÓN sin
//   salir de la pantalla (y puede regresar).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verago/screens/negocio_screen.dart';
import 'package:verago/services/validaciones.dart';
import 'package:verago/theme/app_theme.dart';

void main() {
  group('Validaciones', () {
    test('correo', () {
      expect(Validaciones.correo('ana@correo.com'), isNull);
      expect(Validaciones.correo('ana@correo'), isNotNull);
      expect(Validaciones.correo('ana correo.com'), isNotNull);
    });
    test('contraseña segura: 8+ caracteres, letras y números', () {
      expect(Validaciones.contrasenaSegura('veracruz2026'), isNull);
      expect(Validaciones.contrasenaSegura('vera26'), 'Usa al menos 8 caracteres');
      expect(Validaciones.contrasenaSegura('12345678'), 'Incluye al menos una letra');
      expect(Validaciones.contrasenaSegura('veracruzz'), 'Incluye al menos un número');
    });
    test('teléfono: exactamente 10 números', () {
      expect(Validaciones.telefono('2291234567'), isNull);
      expect(Validaciones.telefono('229 123 4567'), 'Escribe solo números');
      expect(Validaciones.telefono('12345'), 'El teléfono debe tener 10 números (llevas 5)');
      expect(Validaciones.telefono('22912345678'), isNotNull); // 11 números
    });
  });

  testWidgets('Abre en registro y cambia a iniciar sesión y de regreso', (tester) async {
    await tester.pumpWidget(MaterialApp(theme: VgTema.claro, home: const NegocioScreen()));
    await tester.pumpAndSettle();

    // Estado predeterminado: registro (sin Supabase el formulario no carga,
    // pero el título y el enlace siguen visibles).
    expect(find.text('¡Forma parte de VeraGo!'), findsOneWidget);
    expect(find.text('¿Tu negocio ya está registrado?'), findsOneWidget);

    // El logo empuja el enlace hacia abajo: nos desplazamos hasta él.
    await tester.ensureVisible(find.text('Iniciar sesión'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Iniciar sesión'));
    await tester.pumpAndSettle();
    expect(find.text('Entra a tu comercio'), findsOneWidget);
    expect(find.text('Entrar a mi comercio'), findsOneWidget);
    expect(find.text('¿Olvidaste tu contraseña?'), findsOneWidget);

    await tester.ensureVisible(find.text('Registrar mi negocio'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Registrar mi negocio'));
    await tester.pumpAndSettle();
    expect(find.text('¡Forma parte de VeraGo!'), findsOneWidget);
  });
}
