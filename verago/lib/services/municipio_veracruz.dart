import 'package:flutter_map/flutter_map.dart' show LatLngBounds;
import 'package:latlong2/latlong.dart';

/// LÍMITE DEL MUNICIPIO DE VERACRUZ (Veracruz, México).
///
/// Qué es: el contorno oficial del municipio, tomado de OpenStreetMap
/// (relación 6037860, simplificado a ~50 m). Son 3 polígonos: el municipio
/// y dos islas pequeñas.
/// Para qué: los lugares, Puntos VeraGo y negocios solo se pueden marcar
/// DENTRO del municipio (antes se podía poner uno en otro país).
/// La base de datos revisa lo mismo (SQL 021), por si la app se equivoca.
class MunicipioVeracruz {
  static const nombre = 'municipio de Veracruz';

  /// Rectángulo que encierra el municipio (para limitar el mapa).
  static final limites = LatLngBounds(const LatLng(19.10218, -96.33967), const LatLng(19.26525, -96.06613));

  static const poligonos = <List<LatLng>>[
    [LatLng(19.23159, -96.33967), LatLng(19.22608, -96.33279), LatLng(19.22196, -96.33046), LatLng(19.21814, -96.32703), LatLng(19.21587, -96.32781), LatLng(19.20846, -96.33391), LatLng(19.20558, -96.33482), LatLng(19.20367, -96.33463), LatLng(19.19961, -96.33211), LatLng(19.19783, -96.32926), LatLng(19.19872, -96.31969), LatLng(19.19131, -96.3147), LatLng(19.19196, -96.30877), LatLng(19.18899, -96.30657), LatLng(19.18942, -96.30545), LatLng(19.18779, -96.30453), LatLng(19.18827, -96.30334), LatLng(19.18701, -96.30195), LatLng(19.18627, -96.30206), LatLng(19.18687, -96.30353), LatLng(19.1848, -96.30423), LatLng(19.18574, -96.30605), LatLng(19.18351, -96.30633), LatLng(19.18316, -96.30823), LatLng(19.18385, -96.30901), LatLng(19.18138, -96.30823), LatLng(19.17903, -96.31002), LatLng(19.17516, -96.30958), LatLng(19.16946, -96.3127), LatLng(19.16058, -96.31383), LatLng(19.15007, -96.31391), LatLng(19.15416, -96.31085), LatLng(19.15531, -96.31156), LatLng(19.15877, -96.31056), LatLng(19.1587, -96.30777), LatLng(19.15653, -96.30771), LatLng(19.15645, -96.30645), LatLng(19.15894, -96.30652), LatLng(19.15951, -96.30512), LatLng(19.15742, -96.3041), LatLng(19.15903, -96.29922), LatLng(19.15842, -96.2986), LatLng(19.1591, -96.29742), LatLng(19.15736, -96.29544), LatLng(19.15873, -96.29515), LatLng(19.15854, -96.29416), LatLng(19.1555, -96.29279), LatLng(19.15548, -96.29048), LatLng(19.15417, -96.29292), LatLng(19.13736, -96.26657), LatLng(19.13327, -96.26356), LatLng(19.13441, -96.26075), LatLng(19.1356, -96.26123), LatLng(19.13615, -96.2579), LatLng(19.13467, -96.25791), LatLng(19.14045, -96.25708), LatLng(19.14498, -96.24402), LatLng(19.14007, -96.24191), LatLng(19.14067, -96.24097), LatLng(19.13992, -96.23684), LatLng(19.13582, -96.23765), LatLng(19.13563, -96.23602), LatLng(19.1192, -96.22213), LatLng(19.1244, -96.21496), LatLng(19.12424, -96.21076), LatLng(19.11911, -96.20962), LatLng(19.1162, -96.20984), LatLng(19.1162, -96.20762), LatLng(19.11273, -96.20761), LatLng(19.11272, -96.2087), LatLng(19.10953, -96.2087), LatLng(19.10718, -96.20505), LatLng(19.1095, -96.2019), LatLng(19.10267, -96.19035), LatLng(19.10359, -96.18988), LatLng(19.10409, -96.18807), LatLng(19.1051, -96.17887), LatLng(19.10451, -96.17681), LatLng(19.10236, -96.1752), LatLng(19.10218, -96.17395), LatLng(19.10477, -96.17217), LatLng(19.10816, -96.17242), LatLng(19.10687, -96.16926), LatLng(19.1095, -96.16702), LatLng(19.10861, -96.16558), LatLng(19.10959, -96.16444), LatLng(19.10899, -96.16126), LatLng(19.11087, -96.15809), LatLng(19.11075, -96.15701), LatLng(19.10915, -96.1563), LatLng(19.11028, -96.1551), LatLng(19.10849, -96.15214), LatLng(19.10951, -96.14966), LatLng(19.12155, -96.14694), LatLng(19.1376, -96.14164), LatLng(19.13987, -96.13996), LatLng(19.14109, -96.1401), LatLng(19.14151, -96.13817), LatLng(19.14438, -96.13535), LatLng(19.14557, -96.12983), LatLng(19.14641, -96.12914), LatLng(19.16004, -96.13136), LatLng(19.16512, -96.13144), LatLng(19.16872, -96.11851), LatLng(19.17099, -96.11908), LatLng(19.17293, -96.11818), LatLng(19.17447, -96.11983), LatLng(19.17653, -96.12061), LatLng(19.17727, -96.12005), LatLng(19.17745, -96.1214), LatLng(19.17964, -96.12366), LatLng(19.18182, -96.12393), LatLng(19.18218, -96.12296), LatLng(19.1831, -96.12418), LatLng(19.18588, -96.12327), LatLng(19.18539, -96.12192), LatLng(19.18801, -96.12204), LatLng(19.18969, -96.12373), LatLng(19.19062, -96.12233), LatLng(19.18755, -96.12049), LatLng(19.19013, -96.1216), LatLng(19.19074, -96.12224), LatLng(19.19051, -96.12286), LatLng(19.19232, -96.12402), LatLng(19.20388, -96.12015), LatLng(19.20832, -96.12357), LatLng(19.2129, -96.12295), LatLng(19.21611, -96.12573), LatLng(19.2175, -96.1283), LatLng(19.21706, -96.12944), LatLng(19.21798, -96.13317), LatLng(19.21636, -96.14119), LatLng(19.21648, -96.15445), LatLng(19.21566, -96.15543), LatLng(19.21652, -96.15584), LatLng(19.2176, -96.15427), LatLng(19.21769, -96.1418), LatLng(19.21952, -96.13191), LatLng(19.21984, -96.13198), LatLng(19.21787, -96.14188), LatLng(19.21782, -96.15437), LatLng(19.21606, -96.15686), LatLng(19.21515, -96.15732), LatLng(19.21725, -96.16026), LatLng(19.21796, -96.16321), LatLng(19.21977, -96.16569), LatLng(19.2225, -96.16737), LatLng(19.22437, -96.16714), LatLng(19.24698, -96.17154), LatLng(19.24674, -96.16624), LatLng(19.24573, -96.16455), LatLng(19.23068, -96.15496), LatLng(19.22621, -96.15796), LatLng(19.22939, -96.15379), LatLng(19.24656, -96.16475), LatLng(19.24715, -96.1664), LatLng(19.24747, -96.17753), LatLng(19.25049, -96.1818), LatLng(19.25019, -96.18665), LatLng(19.25125, -96.19115), LatLng(19.25686, -96.1962), LatLng(19.25896, -96.20673), LatLng(19.26525, -96.22205), LatLng(19.26458, -96.22403), LatLng(19.26141, -96.22501), LatLng(19.26057, -96.22765), LatLng(19.25908, -96.22684), LatLng(19.25926, -96.22427), LatLng(19.25828, -96.22378), LatLng(19.25739, -96.22458), LatLng(19.25657, -96.22371), LatLng(19.25536, -96.22421), LatLng(19.2558, -96.22615), LatLng(19.25522, -96.22627), LatLng(19.24888, -96.22416), LatLng(19.24725, -96.22496), LatLng(19.24353, -96.22425), LatLng(19.2354, -96.22703), LatLng(19.23074, -96.2258), LatLng(19.22604, -96.22715), LatLng(19.22082, -96.22643), LatLng(19.22328, -96.2321), LatLng(19.2244, -96.23924), LatLng(19.2255, -96.24142), LatLng(19.2417, -96.25695), LatLng(19.24294, -96.25373), LatLng(19.24661, -96.25725), LatLng(19.24702, -96.25686), LatLng(19.24884, -96.25799), LatLng(19.25032, -96.2603), LatLng(19.25607, -96.26459), LatLng(19.25644, -96.2657), LatLng(19.25804, -96.26619), LatLng(19.2648, -96.27299), LatLng(19.2592, -96.2801), LatLng(19.2599, -96.28683), LatLng(19.2435, -96.29111), LatLng(19.2438, -96.2924), LatLng(19.24167, -96.2958), LatLng(19.2388, -96.29778), LatLng(19.23875, -96.30101), LatLng(19.23747, -96.30229), LatLng(19.23506, -96.30929), LatLng(19.23268, -96.30959), LatLng(19.23233, -96.31542), LatLng(19.2324, -96.31665), LatLng(19.23305, -96.3167), LatLng(19.23168, -96.31689), LatLng(19.23104, -96.31877), LatLng(19.23294, -96.31977), LatLng(19.23303, -96.3225), LatLng(19.23448, -96.32452), LatLng(19.23557, -96.32365), LatLng(19.23732, -96.32368), LatLng(19.24185, -96.33939), LatLng(19.23491, -96.33871), LatLng(19.23159, -96.33967)],
    [LatLng(19.1741, -96.09296), LatLng(19.17366, -96.09224), LatLng(19.17509, -96.09106), LatLng(19.17712, -96.09207), LatLng(19.17606, -96.09294), LatLng(19.1741, -96.09296)],
    [LatLng(19.19862, -96.06796), LatLng(19.19923, -96.06613), LatLng(19.20084, -96.06685), LatLng(19.20069, -96.06752), LatLng(19.19862, -96.06796)],
  ];

  /// ¿El punto está dentro del municipio?
  /// Método del "rayo": se traza una línea horizontal desde el punto y se
  /// cuentan los bordes que cruza; si son impares, está adentro.
  static bool contiene(LatLng p) => poligonos.any((poly) => _dentro(p, poly));

  static bool _dentro(LatLng p, List<LatLng> poly) {
    var dentro = false;
    for (var i = 0, j = poly.length - 1; i < poly.length; j = i++) {
      final a = poly[i], b = poly[j];
      if ((a.latitude > p.latitude) != (b.latitude > p.latitude) &&
          p.longitude <
              (b.longitude - a.longitude) * (p.latitude - a.latitude) / (b.latitude - a.latitude) + a.longitude) {
        dentro = !dentro;
      }
    }
    return dentro;
  }
}
