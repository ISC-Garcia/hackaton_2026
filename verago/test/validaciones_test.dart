// Pruebas de las restricciones de los campos: qué NO deja escribir cada
// tipo de campo y qué rechaza al guardar.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verago/screens/login_screen.dart';
import 'package:verago/services/validaciones.dart';

/// Aplica los formateadores como si la persona tecleara `texto`.
String teclear(List<TextInputFormatter> formatos, String texto) {
  var valor = TextEditingValue.empty;
  for (final f in formatos) {
    valor = f.formatEditUpdate(valor, TextEditingValue(text: texto));
    texto = valor.text;
  }
  return texto;
}

void main() {
  group('Nombre de persona (sin números)', () {
    test('no deja escribir números ni signos raros', () {
      expect(teclear(Validaciones.nombrePersonaFormato, 'Ana123 López!'), 'Ana López');
      expect(teclear(Validaciones.nombrePersonaFormato, "María José O'Neil-Peña"), "María José O'Neil-Peña");
    });
    test('valida', () {
      expect(Validaciones.nombrePersona()('Ana'), isNull);
      expect(Validaciones.nombrePersona()('Ana 2'), 'El nombre no lleva números');
      expect(Validaciones.nombrePersona()('A'), isNotNull);
      expect(Validaciones.nombrePersona()('-Ana'), isNotNull);
      expect(Validaciones.nombrePersona(completo: true)('Ana'), 'Escribe nombre y apellido');
      expect(Validaciones.nombrePersona(completo: true)('Ana Pérez'), isNull);
    });
  });

  group('Nombre de negocio (sí permite números)', () {
    test('deja números y signos comunes', () {
      expect(teclear(Validaciones.nombreNegocioFormato(), 'Café 2 Hermanos #3 & Co.'), 'Café 2 Hermanos #3 & Co.');
      expect(teclear(Validaciones.nombreNegocioFormato(), 'Tacos<script>'), 'Tacosscript');
    });
    test('debe llevar letras', () {
      expect(Validaciones.nombreNegocio('el nombre')('Café 2 Hermanos'), isNull);
      expect(Validaciones.nombreNegocio('el nombre')('123'), isNotNull);
    });
  });

  group('Números (precios, costos)', () {
    test('no deja escribir letras', () {
      expect(teclear(Validaciones.soloNumeros(6), '12a5b'), '125');
      expect(teclear(Validaciones.soloNumeros(6), '12345678'), '123456');
    });
    test('precio de 0 a 100 000', () {
      expect(Validaciones.precio()(''), isNull);
      expect(Validaciones.precio()('45'), isNull);
      expect(Validaciones.precio()('200000'), isNotNull);
      expect(Validaciones.precio(opcional: false)(''), isNotNull);
    });
  });

  group('Teléfono, correo, dirección y textos', () {
    test('teléfono: solo 10 números', () {
      expect(teclear(Validaciones.soloDiezDigitos, '229-123 45678'), '2291234567');
      expect(Validaciones.telefono('2291234567'), isNull);
      expect(Validaciones.telefono('229123'), isNotNull);
    });
    test('correo: sin espacios', () {
      expect(teclear(Validaciones.correoFormato, 'ana @correo .com'), 'ana@correo.com');
      expect(Validaciones.correo('ana@correo.com'), isNull);
      expect(Validaciones.correo('ana@correo'), isNotNull);
    });
    test('dirección: con letras', () {
      expect(Validaciones.direccion()('Av. Independencia 1080, Centro'), isNull);
      expect(Validaciones.direccion()('12345'), isNotNull);
      expect(Validaciones.direccion(opcional: true)(''), isNull);
    });
    test('descripción: con palabras, no solo números', () {
      expect(Validaciones.textoConLetras('una descripción')('Café de altura y pan dulce'), isNull);
      expect(Validaciones.textoConLetras('una descripción')('1234567890'), isNotNull);
    });
  });

  test('código del QR escrito a mano', () {
    const codigo = 'VG-0123456789abcdef0123456789abcdef';
    expect(Validaciones.codigoQr(codigo), isNull);
    expect(Validaciones.codigoQr('vg-0123456789ABCDEF0123456789ABCDEF'), isNull); // se normaliza
    expect(Validaciones.normalizarCodigo(' vg-ABC '), 'VG-abc');
    expect(Validaciones.codigoQr('hola'), isNotNull);
    expect(teclear(Validaciones.codigoQrFormato, 'VG-12 34!'), 'VG-1234');
  });

  testWidgets('en "Crear cuenta", el nombre no acepta números al teclear', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));
    await tester.tap(find.text('No tengo cuenta: crear una'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'Ana123');
    expect(find.text('Ana'), findsOneWidget);
  });
}
