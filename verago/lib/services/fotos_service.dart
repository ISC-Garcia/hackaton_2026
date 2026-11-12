import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'error_verago.dart';

/// SERVICIO DE FOTOS de los lugares (SQL 018).
///
/// - `image_picker` (paquete oficial de Flutter): abre la galería o la cámara
///   del celular (en la web, el selector de archivos) y entrega la foto.
/// - Supabase Storage: guarda el archivo en el bucket "fotos-lugares", en la
///   carpeta del lugar: `<id del lugar>/foto_<fecha>.jpg`.
/// - Las reglas del bucket deciden quién puede subir: el admin a cualquier
///   lugar; el comerciante solo a la carpeta de su negocio.
///
/// La foto se achica antes de subirla (máx. 1280 px, calidad 75) para que pese
/// poco y cargue rápido con datos móviles.
class FotosService {
  SupabaseClient get _db => Supabase.instance.client;
  static const bucket = 'fotos-lugares';

  /// Abre la galería (o la cámara) y sube la foto. Devuelve la URL pública,
  /// o null si la persona canceló.
  Future<String?> elegirYSubir(String lugarId, {bool camara = false}) async {
    final XFile? archivo;
    try {
      archivo = await ImagePicker().pickImage(
        source: camara ? ImageSource.camera : ImageSource.gallery,
        maxWidth: 1280,
        maxHeight: 1280,
        imageQuality: 75,
      );
    } catch (_) {
      throw const ErrorVeraGo('No pudimos abrir la galería o la cámara. Revisa los permisos del celular.');
    }
    if (archivo == null) return null; // canceló

    final bytes = await archivo.readAsBytes();
    if (bytes.length > 2 * 1024 * 1024) {
      throw const ErrorVeraGo('La foto pesa más de 2 MB. Elige otra o tómala con menos calidad.');
    }
    final tipo = tipoDeImagen(archivo.name, archivo.mimeType);
    if (tipo == null) throw const ErrorVeraGo('Solo se aceptan fotos JPG, PNG o WEBP.');

    final ruta = '$lugarId/foto_${DateTime.now().millisecondsSinceEpoch}.${tipo.extension}';
    try {
      await _db.storage.from(bucket).uploadBinary(
            ruta,
            bytes,
            fileOptions: FileOptions(contentType: tipo.mime, upsert: false),
          );
    } on StorageException catch (e) {
      if (e.statusCode == '403' || e.statusCode == '401' || e.message.contains('row-level security')) {
        throw const ErrorVeraGo('No tienes permiso para cambiar la foto de este lugar.');
      }
      if (e.message.contains('Bucket not found')) {
        throw const ErrorVeraGo('Falta actualizar la base de datos (correr el SQL 018). Avisa a los desarrolladores.');
      }
      throw const ErrorVeraGo('No pudimos subir la foto. Intenta de nuevo.');
    } catch (_) {
      throw const ErrorVeraGo('Revisa tu conexión a internet e intenta de nuevo.');
    }
    return _db.storage.from(bucket).getPublicUrl(ruta);
  }

  /// Borra del bucket la foto anterior (si es nuestra). Si falla no pasa
  /// nada grave: solo queda un archivo sin usar.
  Future<void> borrarArchivo(String? url) async {
    final ruta = rutaEnBucket(url);
    if (ruta == null) return;
    try {
      await _db.storage.from(bucket).remove([ruta]);
    } catch (_) {}
  }

  /// `…/storage/v1/object/public/fotos-lugares/ID/foto.jpg` → `ID/foto.jpg`.
  static String? rutaEnBucket(String? url) {
    if (url == null) return null;
    const marca = '/storage/v1/object/public/$bucket/';
    final i = url.indexOf(marca);
    return i < 0 ? null : Uri.decodeComponent(url.substring(i + marca.length));
  }

  /// Tipo de imagen por su nombre o tipo MIME (público para probarlo).
  static ({String mime, String extension})? tipoDeImagen(String nombre, String? mime) {
    final n = nombre.toLowerCase();
    final m = (mime ?? '').toLowerCase();
    if (m == 'image/png' || n.endsWith('.png')) return (mime: 'image/png', extension: 'png');
    if (m == 'image/webp' || n.endsWith('.webp')) return (mime: 'image/webp', extension: 'webp');
    if (m == 'image/jpeg' || n.endsWith('.jpg') || n.endsWith('.jpeg')) {
      return (mime: 'image/jpeg', extension: 'jpg');
    }
    return null;
  }
}
