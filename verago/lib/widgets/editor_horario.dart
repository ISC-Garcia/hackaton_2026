import 'package:flutter/material.dart';

import '../models/lugar.dart';

/// Editor de horario semanal: una fila por día con un interruptor
/// (abierto / cerrado) y las horas de apertura y cierre.
///
/// Lo usan el comerciante (Editar mis datos) y el admin (lugares).
/// `horario` es una lista de 7 elementos (0 = domingo); null = cerrado.
/// El widget cambia esa lista y avisa con `alCambiar` para redibujar.
class EditorHorario extends StatelessWidget {
  const EditorHorario({super.key, required this.horario, required this.alCambiar});

  final List<Horario?> horario;
  final VoidCallback alCambiar;

  static const dias = ['Domingo', 'Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado'];

  /// Convierte el horario de un lugar en la lista de 7 días que usa el editor.
  static List<Horario?> desde(Lugar? lugar) => [for (var d = 0; d < 7; d++) lugar?.horarioDel(d)];

  /// Revisa que en cada día abierto la hora de cierre sea después de la de apertura.
  static String? validar(List<Horario?> horario) =>
      horario.whereType<Horario>().any((h) => h.cierra <= h.abre)
          ? 'En cada día, la hora de cierre debe ser después de la de apertura.'
          : null;

  Future<void> _elegirHora(BuildContext context, int dia, {required bool apertura}) async {
    final actual = horario[dia] ?? Horario(diaSemana: dia, abre: 9 * 60, cierra: 18 * 60);
    final minutos = apertura ? actual.abre : actual.cierra;
    final elegida = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: minutos ~/ 60, minute: minutos % 60),
    );
    if (elegida == null) return;
    final m = elegida.hour * 60 + elegida.minute;
    horario[dia] = Horario(
      diaSemana: dia,
      abre: apertura ? m : actual.abre,
      cierra: apertura ? actual.cierra : m,
    );
    alCambiar();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var d = 0; d < 7; d++)
          Row(
            children: [
              SizedBox(width: 92, child: Text(dias[d])),
              Switch(
                value: horario[d] != null,
                onChanged: (abierto) {
                  horario[d] = abierto ? Horario(diaSemana: d, abre: 9 * 60, cierra: 18 * 60) : null;
                  alCambiar();
                },
              ),
              if (horario[d] == null)
                const Text('Cerrado')
              else ...[
                TextButton(
                  onPressed: () => _elegirHora(context, d, apertura: true),
                  child: Text(Horario.formato(horario[d]!.abre)),
                ),
                const Text('a'),
                TextButton(
                  onPressed: () => _elegirHora(context, d, apertura: false),
                  child: Text(Horario.formato(horario[d]!.cierra)),
                ),
              ],
            ],
          ),
      ],
    );
  }
}
