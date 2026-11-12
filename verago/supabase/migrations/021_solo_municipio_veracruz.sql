-- =====================================================================
-- VeraGo · 021 · Los lugares solo pueden estar en el MUNICIPIO DE VERACRUZ
--
-- Problema: se podía crear un Punto VeraGo (o un lugar o negocio) en otro
-- país. Ahora la base de datos solo acepta coordenadas DENTRO del municipio
-- de Veracruz, Veracruz (contorno de OpenStreetMap, relación 6037860,
-- simplificado a ~50 m; 3 polígonos: el municipio y dos islas pequeñas).
-- La app revisa lo mismo (lib/services/municipio_veracruz.dart).
--
-- Cómo, sin PostGIS: función "punto en polígono" con el método del RAYO
-- (se cuentan los bordes que cruza una línea desde el punto; impar = dentro).
-- "immutable" = siempre da lo mismo con los mismos datos; PostgreSQL lo pide
-- para poder usar la función dentro de una regla CHECK.
-- =====================================================================

create function public._punto_en_poligono(
  p_lat double precision, p_lng double precision,
  p_lats double precision[], p_lngs double precision[]
)
returns boolean
language plpgsql
immutable
set search_path = ''
as $$
declare
  v_dentro boolean := false;
  n int := array_length(p_lats, 1);
  i int;
  j int := n;
begin
  for i in 1..n loop
    if ((p_lats[i] > p_lat) <> (p_lats[j] > p_lat)) and
       (p_lng < (p_lngs[j] - p_lngs[i]) * (p_lat - p_lats[i]) / (p_lats[j] - p_lats[i]) + p_lngs[i]) then
      v_dentro := not v_dentro;
    end if;
    j := i;
  end loop;
  return v_dentro;
end;
$$;

create function public.dentro_municipio_veracruz(p_lat double precision, p_lng double precision)
returns boolean
language plpgsql
immutable
set search_path = ''
as $$
begin
  if p_lat is null or p_lng is null then
    return true; -- columnas vacías (ej. sin cambio de ubicación pendiente)
  end if;
    if public._punto_en_poligono(p_lat, p_lng,
      array[19.23159,19.22608,19.22196,19.21814,19.21587,19.20846,19.20558,19.20367,19.19961,19.19783,19.19872,19.19131,19.19196,19.18899,19.18942,19.18779,19.18827,19.18701,19.18627,19.18687,19.1848,19.18574,19.18351,19.18316,19.18385,19.18138,19.17903,19.17516,19.16946,19.16058,19.15007,19.15416,19.15531,19.15877,19.1587,19.15653,19.15645,19.15894,19.15951,19.15742,19.15903,19.15842,19.1591,19.15736,19.15873,19.15854,19.1555,19.15548,19.15417,19.13736,19.13327,19.13441,19.1356,19.13615,19.13467,19.14045,19.14498,19.14007,19.14067,19.13992,19.13582,19.13563,19.1192,19.1244,19.12424,19.11911,19.1162,19.1162,19.11273,19.11272,19.10953,19.10718,19.1095,19.10267,19.10359,19.10409,19.1051,19.10451,19.10236,19.10218,19.10477,19.10816,19.10687,19.1095,19.10861,19.10959,19.10899,19.11087,19.11075,19.10915,19.11028,19.10849,19.10951,19.12155,19.1376,19.13987,19.14109,19.14151,19.14438,19.14557,19.14641,19.16004,19.16512,19.16872,19.17099,19.17293,19.17447,19.17653,19.17727,19.17745,19.17964,19.18182,19.18218,19.1831,19.18588,19.18539,19.18801,19.18969,19.19062,19.18755,19.19013,19.19074,19.19051,19.19232,19.20388,19.20832,19.2129,19.21611,19.2175,19.21706,19.21798,19.21636,19.21648,19.21566,19.21652,19.2176,19.21769,19.21952,19.21984,19.21787,19.21782,19.21606,19.21515,19.21725,19.21796,19.21977,19.2225,19.22437,19.24698,19.24674,19.24573,19.23068,19.22621,19.22939,19.24656,19.24715,19.24747,19.25049,19.25019,19.25125,19.25686,19.25896,19.26525,19.26458,19.26141,19.26057,19.25908,19.25926,19.25828,19.25739,19.25657,19.25536,19.2558,19.25522,19.24888,19.24725,19.24353,19.2354,19.23074,19.22604,19.22082,19.22328,19.2244,19.2255,19.2417,19.24294,19.24661,19.24702,19.24884,19.25032,19.25607,19.25644,19.25804,19.2648,19.2592,19.2599,19.2435,19.2438,19.24167,19.2388,19.23875,19.23747,19.23506,19.23268,19.23233,19.2324,19.23305,19.23168,19.23104,19.23294,19.23303,19.23448,19.23557,19.23732,19.24185,19.23491,19.23159]::double precision[],
      array[-96.33967,-96.33279,-96.33046,-96.32703,-96.32781,-96.33391,-96.33482,-96.33463,-96.33211,-96.32926,-96.31969,-96.3147,-96.30877,-96.30657,-96.30545,-96.30453,-96.30334,-96.30195,-96.30206,-96.30353,-96.30423,-96.30605,-96.30633,-96.30823,-96.30901,-96.30823,-96.31002,-96.30958,-96.3127,-96.31383,-96.31391,-96.31085,-96.31156,-96.31056,-96.30777,-96.30771,-96.30645,-96.30652,-96.30512,-96.3041,-96.29922,-96.2986,-96.29742,-96.29544,-96.29515,-96.29416,-96.29279,-96.29048,-96.29292,-96.26657,-96.26356,-96.26075,-96.26123,-96.2579,-96.25791,-96.25708,-96.24402,-96.24191,-96.24097,-96.23684,-96.23765,-96.23602,-96.22213,-96.21496,-96.21076,-96.20962,-96.20984,-96.20762,-96.20761,-96.2087,-96.2087,-96.20505,-96.2019,-96.19035,-96.18988,-96.18807,-96.17887,-96.17681,-96.1752,-96.17395,-96.17217,-96.17242,-96.16926,-96.16702,-96.16558,-96.16444,-96.16126,-96.15809,-96.15701,-96.1563,-96.1551,-96.15214,-96.14966,-96.14694,-96.14164,-96.13996,-96.1401,-96.13817,-96.13535,-96.12983,-96.12914,-96.13136,-96.13144,-96.11851,-96.11908,-96.11818,-96.11983,-96.12061,-96.12005,-96.1214,-96.12366,-96.12393,-96.12296,-96.12418,-96.12327,-96.12192,-96.12204,-96.12373,-96.12233,-96.12049,-96.1216,-96.12224,-96.12286,-96.12402,-96.12015,-96.12357,-96.12295,-96.12573,-96.1283,-96.12944,-96.13317,-96.14119,-96.15445,-96.15543,-96.15584,-96.15427,-96.1418,-96.13191,-96.13198,-96.14188,-96.15437,-96.15686,-96.15732,-96.16026,-96.16321,-96.16569,-96.16737,-96.16714,-96.17154,-96.16624,-96.16455,-96.15496,-96.15796,-96.15379,-96.16475,-96.1664,-96.17753,-96.1818,-96.18665,-96.19115,-96.1962,-96.20673,-96.22205,-96.22403,-96.22501,-96.22765,-96.22684,-96.22427,-96.22378,-96.22458,-96.22371,-96.22421,-96.22615,-96.22627,-96.22416,-96.22496,-96.22425,-96.22703,-96.2258,-96.22715,-96.22643,-96.2321,-96.23924,-96.24142,-96.25695,-96.25373,-96.25725,-96.25686,-96.25799,-96.2603,-96.26459,-96.2657,-96.26619,-96.27299,-96.2801,-96.28683,-96.29111,-96.2924,-96.2958,-96.29778,-96.30101,-96.30229,-96.30929,-96.30959,-96.31542,-96.31665,-96.3167,-96.31689,-96.31877,-96.31977,-96.3225,-96.32452,-96.32365,-96.32368,-96.33939,-96.33871,-96.33967]::double precision[]) then
      return true;
    end if;
    if public._punto_en_poligono(p_lat, p_lng,
      array[19.1741,19.17366,19.17509,19.17712,19.17606,19.1741]::double precision[],
      array[-96.09296,-96.09224,-96.09106,-96.09207,-96.09294,-96.09296]::double precision[]) then
      return true;
    end if;
    if public._punto_en_poligono(p_lat, p_lng,
      array[19.19862,19.19923,19.20084,19.20069,19.19862]::double precision[],
      array[-96.06796,-96.06613,-96.06685,-96.06752,-96.06796]::double precision[]) then
      return true;
    end if;
  return false;
end;
$$;

-- 1. Lo que YA estaba fuera (ej. un Punto de prueba en otro país) se oculta.
--    Para corregirlo hay que moverlo dentro del municipio o eliminarlo.
update public.lugares
set publicado = false
where not public.dentro_municipio_veracruz(latitud, longitud);

-- 2. Reglas: desde ahora, ningún lugar ni cambio de ubicación fuera.
--    "not valid" = no revisa las filas viejas al crear la regla (las de
--    arriba quedaron ocultas); sí revisa toda fila nueva o modificada.
alter table public.lugares
  add constraint lugar_en_municipio_veracruz
  check (public.dentro_municipio_veracruz(latitud, longitud)) not valid;

alter table public.lugares
  add constraint cambio_en_municipio_veracruz
  check (public.dentro_municipio_veracruz(cambio_latitud, cambio_longitud)) not valid;

-- Para ver qué quedó fuera (solo desarrolladores, en el SQL Editor):
--   select nombre, latitud, longitud from public.lugares
--   where not public.dentro_municipio_veracruz(latitud, longitud);
