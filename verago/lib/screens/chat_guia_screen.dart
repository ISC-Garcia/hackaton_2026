import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show LengthLimitingTextInputFormatter;

import '../config.dart';
import '../models/lugar.dart';
import '../services/distancia.dart';
import '../services/error_verago.dart';
import '../models/sello.dart';
import '../services/auth_service.dart';
import '../services/guia_ia_service.dart';
import '../services/pasaporte_service.dart';
import '../services/preferencias_service.dart';
import '../theme/app_theme.dart';
import '../widgets/estado_vacio.dart';
import '../widgets/tarjeta_lugar.dart';
import 'lugar_screen.dart';

/// CHAT "PREGÚNTALE A VERAGO": guía con IA (Google Gemini).
///
/// - La persona escribe en lenguaje natural ("algo con sombra para ir con
///   niños") y la guía responde con texto y TARJETAS de lugares reales de la
///   app, buscadas en memoria por su id.
/// - La conversación se recuerda solo mientras esta pantalla está abierta
///   (decisión del equipo). Al cerrarla se borra; no se guarda en ningún lado.
class ChatGuiaScreen extends StatefulWidget {
  const ChatGuiaScreen({super.key, required this.lugares, this.servicio, this.cargarPerfil});

  /// Lugares ya descargados en Explorar (no se vuelven a pedir).
  final List<Lugar> lugares;

  /// Solo para pruebas automáticas (simula Gemini).
  final GuiaIaService? servicio;

  /// Solo para pruebas: entrega sellos e intereses falsos.
  final Future<({List<Sello> sellos, Set<String> intereses})> Function()? cargarPerfil;

  @override
  State<ChatGuiaScreen> createState() => _ChatGuiaScreenState();
}

class _ChatGuiaScreenState extends State<ChatGuiaScreen> {
  late final _servicio = widget.servicio ?? GuiaIaService();
  final _texto = TextEditingController();
  final _desplazar = ScrollController();

  /// Lo que se ve en pantalla.
  final _mensajes = <MensajeChat>[];

  /// Lo que se le manda a Gemini: solo preguntas con respuesta (así los
  /// turnos siempre se alternan persona → guía).
  final _conversacion = <MensajeChat>[];

  late final String _contexto = GuiaIaService.contextoLugares(widget.lugares, DateTime.now());
  late final Map<String, Lugar> _porId = {for (final l in widget.lugares) l.id: l};
  bool _esperando = false;

  /// Perfil anónimo (intereses + sellos) para personalizar. Se carga una vez
  /// al abrir; si falla, la guía funciona igual sin personalizar.
  late final Future<String?> _perfil = _cargarPerfil();

  Future<String?> _cargarPerfil() async {
    try {
      // Máximo 4 s: si tarda (red lenta), la guía responde sin personalizar.
      final datos = await (widget.cargarPerfil ?? _perfilReal)().timeout(const Duration(seconds: 4));
      return GuiaIaService.perfilVisitante(sellos: datos.sellos, intereses: datos.intereses, lugares: widget.lugares);
    } catch (_) {
      return null;
    }
  }

  static Future<({List<Sello> sellos, Set<String> intereses})> _perfilReal() async {
    final intereses = await PreferenciasService().leerIntereses();
    // Sellos solo si hay sesión (un invitado no tiene).
    final sellos = AuthService().usuario == null ? const <Sello>[] : await PasaporteService().misSellos();
    return (sellos: sellos, intereses: intereses);
  }

  static const _sugerencias = [
    'Algo con sombra para ir con niños',
    '¿Dónde como mariscos cerca del Zócalo?',
    'Un museo o lugar gratis',
    '¿Qué café está abierto ahora?',
  ];

  @override
  void dispose() {
    _texto.dispose();
    _desplazar.dispose();
    super.dispose();
  }

  Future<void> _enviar(String pregunta) async {
    final t = pregunta.trim();
    if (t.isEmpty || _esperando) return;
    _texto.clear();
    final mio = MensajeChat(deUsuario: true, texto: t);
    setState(() {
      _mensajes.add(mio);
      _esperando = true;
    });
    _bajar();
    try {
      final r = await _servicio.preguntar(
        contexto: _contexto,
        historial: [..._conversacion, mio],
        idsValidos: _porId.keys.toSet(),
        perfil: await _perfil,
      );
      if (!mounted) return;
      final guia = MensajeChat(deUsuario: false, texto: r.respuesta, lugaresIds: r.lugaresIds);
      setState(() {
        _mensajes.add(guia);
        _conversacion
          ..add(mio)
          ..add(guia);
      });
    } on ErrorVeraGo catch (e) {
      if (!mounted) return;
      // El error se muestra como mensaje de la guía, pero no se manda a Gemini.
      setState(() => _mensajes.add(MensajeChat(deUsuario: false, texto: '⚠️ ${e.mensaje}')));
    } finally {
      if (mounted) setState(() => _esperando = false);
      _bajar();
    }
  }

  /// Baja la lista al último mensaje.
  void _bajar() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_desplazar.hasClients) {
        _desplazar.animateTo(_desplazar.position.maxScrollExtent,
            duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pregúntale a VeraGo')),
      body: !Config.chatConfigurado && widget.servicio == null
          ? const EstadoVacio(
              icono: Icons.support_agent,
              titulo: 'Falta configurar la guía',
              mensaje: 'Los desarrolladores deben agregar GEMINI_API_KEY en env.json y volver a correr la app.',
            )
          : Column(
              children: [
                Expanded(
                  child: ListView(
                    controller: _desplazar,
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                    children: [
                      const _Burbuja(
                        deUsuario: false,
                        texto: '¡Hola! Soy la guía de VeraGo. Cuéntame qué se te antoja hacer en el Centro '
                            'Histórico y te recomiendo lugares.',
                      ),
                      if (_mensajes.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final s in _sugerencias)
                                ActionChip(label: Text(s), onPressed: () => _enviar(s)),
                            ],
                          ),
                        ),
                      for (final m in _mensajes) ...[
                        _Burbuja(deUsuario: m.deUsuario, texto: m.texto),
                        for (final id in m.lugaresIds)
                          if (_porId[id] case final lugar?)
                            TarjetaLugar(
                              lugar: lugar,
                              desde: Distancia.zocalo,
                              alTocar: () => Navigator.of(context).push(MaterialPageRoute(
                                builder: (_) => LugarScreen(lugar: lugar, todos: widget.lugares),
                              )),
                            ),
                      ],
                      if (_esperando)
                        const Padding(
                          padding: EdgeInsets.all(12),
                          child: Row(
                            children: [
                              SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                              SizedBox(width: 10),
                              Text('VeraGo está pensando…'),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    // Texto pedido por el equipo. Los detalles de privacidad (qué se
                    // envía a Gemini) están en el Aviso de privacidad.
                    'Estás hablando con una IA. Puede cometer errores.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Colors.black.withValues(alpha: 0.6)),
                  ),
                ),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _texto,
                            minLines: 1,
                            maxLines: 3,
                            textInputAction: TextInputAction.send,
                            inputFormatters: [LengthLimitingTextInputFormatter(300)],
                            onSubmitted: _enviar,
                            decoration: InputDecoration(
                              hintText: 'Escribe lo que buscas…',
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filled(
                          tooltip: 'Enviar',
                          onPressed: _esperando ? null : () => _enviar(_texto.text),
                          icon: const Icon(Icons.send),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _Burbuja extends StatelessWidget {
  const _Burbuja({required this.deUsuario, required this.texto});
  final bool deUsuario;
  final String texto;

  @override
  Widget build(BuildContext context) => Align(
        alignment: deUsuario ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.8),
          decoration: BoxDecoration(
            color: deUsuario ? VgColores.azulGolfo : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
          ),
          child: Text(texto, style: TextStyle(color: deUsuario ? Colors.white : VgColores.tinta, height: 1.35)),
        ),
      );
}
