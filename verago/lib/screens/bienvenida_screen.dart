import 'package:flutter/material.dart';

import '../services/preferencias_service.dart';
import '../theme/app_theme.dart';
import '../widgets/categoria_estilo.dart';
import '../widgets/vg_logo.dart';
import 'negocio_screen.dart';
import 'principal_screen.dart';

/// BIENVENIDA Y GUÍA: se muestra solo la primera vez que se abre la app.
///
/// 7 páginas que se deslizan (`PageView`):
/// 1. Qué es VeraGo.
/// 2. ¿Qué te interesa? (los intereses se guardan y Rutas los usa).
/// 3 a 6. Una página por pestaña (Explorar, Rutas, Agenda, Pasaporte), con un
///    dibujo de la barra de abajo y la pestaña resaltada, para que la persona
///    nueva sepa dónde está cada cosa.
/// 7. Seguridad y más: botón 911, Ajustes y "Soy un negocio".
/// Se puede volver a ver desde Ajustes.
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

  static const _totalPaginas = 7;

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
                    logo: true, // primera página: logo de VeraGo
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
                    icono: Icons.explore,
                    color: VgColores.azulGolfo,
                    titulo: 'Explorar',
                    texto: 'Mapa y lista de lugares del centro. Busca cualquier sitio de Veracruz, '
                        'toca el botón de ubicación para ver dónde estás y abre la ficha de cada lugar.',
                    extra: _MiniBarra(resaltada: 0),
                  ),
                  const _Pagina(
                    icono: Icons.route,
                    color: VgColores.terracota,
                    titulo: 'Rutas',
                    texto: 'Dinos cuánto tiempo tienes y qué te interesa: armamos tu recorrido a pie, '
                        'con el camino por las calles y la hora de llegada a cada parada.',
                    extra: _MiniBarra(resaltada: 1),
                  ),
                  const _Pagina(
                    icono: Icons.event,
                    color: VgColores.terracota,
                    titulo: 'Agenda',
                    texto: 'Eventos de hoy y de los próximos días en el centro, con su horario '
                        'y si son gratis o su costo aproximado.',
                    extra: _MiniBarra(resaltada: 2),
                  ),
                  const _Pagina(
                    icono: Icons.approval,
                    color: VgColores.verdePalma,
                    titulo: 'Colecciona sellos',
                    texto: 'En Pasaporte, escanea el QR de los negocios locales y junta sellos. '
                        'Con cada grupo de sellos subes de insignia, hasta "Embajador VeraGo".',
                    extra: _MiniBarra(resaltada: 3),
                  ),
                  const _Pagina(
                    icono: Icons.health_and_safety_outlined,
                    color: Color(0xFFC62828),
                    titulo: 'Tu seguridad y más',
                    texto: '',
                    extra: _Consejos(),
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
            // Acceso para comerciantes: abre directo el registro del negocio.
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: TextButton.icon(
                onPressed: () => Navigator.of(context)
                    .push(MaterialPageRoute(builder: (_) => const NegocioScreen())),
                icon: const Icon(Icons.storefront_outlined),
                label: const Text('Soy un negocio'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Dibujo de la barra de abajo de la app con una pestaña resaltada,
/// para que la persona sepa dónde tocar.
class _MiniBarra extends StatelessWidget {
  const _MiniBarra({required this.resaltada});

  /// 0 Explorar, 1 Rutas, 2 Agenda, 3 Pasaporte.
  final int resaltada;

  static const _pestanas = [
    (Icons.explore, 'Explorar'),
    (Icons.route, 'Rutas'),
    (Icons.event, 'Agenda'),
    (Icons.approval, 'Pasaporte'),
  ];

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Pestaña ${_pestanas[resaltada].$2} en la barra de abajo',
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            for (var i = 0; i < _pestanas.length; i++)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: i == resaltada ? VgColores.azulGolfo.withValues(alpha: 0.14) : null,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_pestanas[i].$1,
                        color: i == resaltada ? VgColores.azulGolfo : Colors.black38),
                    Text(_pestanas[i].$2,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: i == resaltada ? FontWeight.w700 : FontWeight.w400,
                          color: i == resaltada ? VgColores.azulGolfo : Colors.black45,
                        )),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Última página: botón 911, Ajustes y "Soy un negocio".
class _Consejos extends StatelessWidget {
  const _Consejos();

  @override
  Widget build(BuildContext context) {
    Widget fila(IconData icono, Color color, String titulo, String texto) => Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icono, color: color, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(titulo, style: const TextStyle(fontWeight: FontWeight.w700)),
                    Text(texto, style: const TextStyle(height: 1.3)),
                  ],
                ),
              ),
            ],
          ),
        );
    return Column(
      children: [
        fila(Icons.emergency_outlined, const Color(0xFFC62828), 'Botón 911',
            'En Explorar y en tu ruta hay un botón rojo que abre la app de llamadas con el 911.'),
        fila(Icons.settings_outlined, VgColores.azulGolfo, 'Ajustes',
            'En Pasaporte, el engrane: tu cuenta, tus intereses, esta guía y los términos.'),
        fila(Icons.storefront_outlined, VgColores.terracota, '¿Tienes un negocio?',
            'Regístralo con "Soy un negocio" (abajo) y aparece en el mapa y en las rutas.'),
      ],
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
    this.logo = false,
  });

  /// true = muestra el logo de VeraGo en lugar del círculo con ícono.
  final bool logo;
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
          if (logo)
            // Image.asset carga una imagen incluida en la app (pubspec.yaml → assets).
            const VgLogo(altura: 170)
          else
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(color: color.withValues(alpha: 0.14), shape: BoxShape.circle),
              child: Icon(icono, size: 72, color: color),
            ),
          const SizedBox(height: 28),
          Text(titulo, textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineMedium),
          if (texto.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(texto, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, height: 1.4)),
          ],
          if (extra != null) ...[const SizedBox(height: 24), extra!],
        ],
      ),
    );
  }
}
