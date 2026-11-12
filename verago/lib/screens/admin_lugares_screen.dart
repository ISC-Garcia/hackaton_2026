import 'package:flutter/material.dart';

import '../models/lugar.dart';
import '../services/admin_service.dart';
import '../widgets/categoria_estilo.dart';
import '../widgets/estado_vacio.dart';
import '../widgets/etiqueta.dart';
import 'admin_lugar_form_screen.dart';

/// LUGARES Y PUNTOS VERAGO (admin): lista para crear y editar.
class AdminLugaresScreen extends StatefulWidget {
  const AdminLugaresScreen({super.key});

  @override
  State<AdminLugaresScreen> createState() => _AdminLugaresScreenState();
}

class _AdminLugaresScreenState extends State<AdminLugaresScreen> {
  final _servicio = AdminService();
  late Future<List<Lugar>> _futuro;
  bool _soloPuntos = false;

  @override
  void initState() {
    super.initState();
    _futuro = _servicio.lugares();
  }

  void _recargar() => setState(() {
        _futuro = _servicio.lugares()..ignore();
      });

  Future<void> _abrir([Lugar? lugar]) async {
    final guardo = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => AdminLugarFormScreen(lugar: lugar)),
    );
    if (guardo == true) _recargar();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lugares y Puntos')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _abrir(),
        icon: const Icon(Icons.add_location_alt_outlined),
        label: const Text('Nuevo lugar'),
      ),
      body: FutureBuilder<List<Lugar>>(
        future: _futuro,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return EstadoVacio(
              icono: Icons.wifi_off,
              titulo: 'Algo salió mal',
              mensaje: snapshot.error.toString(),
              textoBoton: 'Reintentar',
              alPresionar: _recargar,
            );
          }
          final visibles = snapshot.data!.where((l) => !_soloPuntos || l.esPunto).toList();
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(value: false, label: Text('Todos')),
                    ButtonSegment(value: true, label: Text('Puntos VeraGo')),
                  ],
                  selected: {_soloPuntos},
                  onSelectionChanged: (s) => setState(() => _soloPuntos = s.first),
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.only(bottom: 90),
                  children: [
                    for (final l in visibles)
                      Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        child: ListTile(
                          leading: Icon(CategoriaEstilo.de(l.categoriaClave).icono,
                              color: CategoriaEstilo.de(l.categoriaClave).color),
                          title: Text(l.nombre),
                          subtitle: Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: [
                              Text(l.categoriaNombre),
                              if (!l.publicado) const Etiqueta('Oculto', color: Color(0xFF6B6B6B)),
                            ],
                          ),
                          trailing: const Icon(Icons.edit_outlined),
                          onTap: () => _abrir(l),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
