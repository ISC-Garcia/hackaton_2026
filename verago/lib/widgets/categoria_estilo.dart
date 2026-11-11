import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Ícono y color de cada categoría.
///
/// Por qué: no usamos fotos, así que cada categoría tiene su propio ícono
/// y color. Se usa en el mapa, en las tarjetas y en la ficha.
/// La "clave" coincide con la columna `categorias.clave` de la base de datos.
class CategoriaEstilo {
  const CategoriaEstilo(this.icono, this.color);

  final IconData icono;
  final Color color;

  /// Las 7 categorías (clave → nombre), iguales a las de la base de datos.
  /// Las usa la pantalla de bienvenida, que se muestra antes de tener
  /// conexión con Supabase.
  static const nombres = {
    'historia': 'Historia y monumentos',
    'museo': 'Museos',
    'cafeteria': 'Cafeterías',
    'restaurante': 'Restaurantes',
    'tienda': 'Tiendas y artesanías',
    'plaza': 'Plazas y paseos',
    'cultura': 'Cultura',
  };

  static CategoriaEstilo de(String clave) {
    switch (clave) {
      case 'historia':
        return const CategoriaEstilo(Icons.account_balance, Color(0xFF7A4E2D));
      case 'museo':
        return const CategoriaEstilo(Icons.museum, Color(0xFF5B3F8C));
      case 'cafeteria':
        return const CategoriaEstilo(Icons.local_cafe, Color(0xFF8C5A2B));
      case 'restaurante':
        return const CategoriaEstilo(Icons.restaurant, VgColores.terracota);
      case 'tienda':
        return const CategoriaEstilo(Icons.storefront, Color(0xFF9A6A00));
      case 'plaza':
        return const CategoriaEstilo(Icons.park, VgColores.verdePalma);
      case 'cultura':
        return const CategoriaEstilo(Icons.theater_comedy, Color(0xFFA23B5C));
      default:
        return const CategoriaEstilo(Icons.place, VgColores.azulGolfo);
    }
  }
}
