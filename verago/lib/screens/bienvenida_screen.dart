import 'package:flutter/material.dart';

import '../services/preferencias_service.dart';
import '../theme/app_theme.dart';
import '../widgets/categoria_estilo.dart';
import 'principal_screen.dart';

/// BIENVENIDA: se muestra solo la primera vez que se abre la app.
///
/// 3 páginas que se deslizan (`PageView`):
/// 1. Qué es VeraGo.
/// 2. ¿Qué te interesa? (los intereses se guardan y Rutas los usa).
/// 3. El pasaporte de sellos.
///
/// Se puede saltar. Al terminar se guarda "bienvenida vista" en el celular
/// (shared_preferences) para no mostrarla otra vez.
class BienvenidaScreen extends StatefulWidget {
  const BienvenidaScreen({super.key});

  @override
  State<BienvenidaScreen> createState() => _BienvenidaScreenState();
}

class _BienvenidaScreenState extends State<BienvenidaScreen> {
  final _paginas = PageController();
  final _prefs = PreferenciasService();
  final Set<String> _intereses = {};
  int _pagina = 0;

  static const _totalPaginas = 3;

  @override
  void dispose() {
    _paginas.dispose();
    super.dispose();
  }

  Future<void> _terminar() async {
    if (_intereses.isNotEmpty) await _prefs.guardarIntereses(_intereses);
    await _prefs.marcarBienvenidaVista();
    if (!mounted) return;
    // pushReplacement: reemplaza la bienvenida; el botón atrás no regresa a ella.
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const PrincipalScreen()),
    );
  }

  void _siguiente() {
    if (_pagina == _totalPaginas - 1) {
      _terminar();
    } else {
      _paginas.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(onPressed: _terminar, child: const Text('Saltar')),
            ),
            Expanded(
              child: PageView(
                controller: _paginas,
                onPageChanged: (i) => setState(() => _pagina = i),
                children: [
                  const _Pagina(
                    icono: Icons.explore,
                    color: VgColores.azulGolfo,
                    titulo: 'Descubre el Centro Histórico',
                    texto: 'Lugares, cafés, museos y comercios locales de Veracruz, '
                        'a pocos minutos caminando.',
                  ),
                  _Pagina(
                    icono: Icons.route,
                    color: VgColores.terracota,
                    titulo: '¿Qué te interesa?',
                    texto: 'Elige lo que te gusta y armaremos rutas a tu medida.',
                    extra: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: [
                        for (final c in CategoriaEstilo.nombres.entries)
                          FilterChip(
                            avatar: Icon(CategoriaEstilo.de(c.key).icono, size: 18),
                            label: Text(c.value),
                            selected: _intereses.contains(c.key),
                            onSelected: (sel) => setState(() {
                              sel ? _intereses.add(c.key) : _intereses.remove(c.key);
                            }),
                          ),
                      ],
                    ),
                  ),
                  const _Pagina(
                    icono: Icons.approval,
                    color: VgColores.verdePalma,
                    titulo: 'Colecciona sellos',
                    texto: 'Escanea el QR de los comercios participantes y llena tu '
                        'pasaporte con los lugares que visitas.',
                  ),
                ],
              ),
            ),
            // Indicador de página (puntos)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < _totalPaginas; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: i == _pagina ? 22 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: i == _pagina ? VgColores.azulGolfo : Colors.black26,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _siguiente,
                  child: Text(_pagina == _totalPaginas - 1 ? 'Empezar' : 'Siguiente'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Pagina extends StatelessWidget {
  const _Pagina({
    required this.icono,
    required this.color,
    required this.titulo,
    required this.texto,
    this.extra,
  });

  final IconData icono;
  final Color color;
  final String titulo;
  final String texto;
  final Widget? extra;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
      child: Column(
        children: [
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.14), shape: BoxShape.circle),
            child: Icon(icono, size: 72, color: color),
          ),
          const SizedBox(height: 28),
          Text(titulo, textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 12),
          Text(texto, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, height: 1.4)),
          if (extra != null) ...[const SizedBox(height: 24), extra!],
        ],
      ),
    );
  }
}
