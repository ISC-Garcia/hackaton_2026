// Prueba: al guardar intereses (ej. desde Ajustes) se avisa a Rutas.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:verago/services/preferencias_service.dart';

void main() {
  test('guardar intereses avisa a las pantallas que escuchan', () async {
    SharedPreferences.setMockInitialValues({});
    var avisos = 0;
    void escuchar() => avisos++;
    PreferenciasService.interesesCambiaron.addListener(escuchar);
    await PreferenciasService().guardarIntereses({'museo'});
    PreferenciasService.interesesCambiaron.removeListener(escuchar);
    expect(avisos, 1);
    expect(await PreferenciasService().leerIntereses(), {'museo'});
  });
}
