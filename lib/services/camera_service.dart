import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class CameraService {
  static final _picker = ImagePicker();

  /// Ouvre la caméra et retourne le chemin du fichier sauvegardé, ou null si annulé.
  static Future<String?> takePhoto({String prefix = 'photo'}) async {
    try {
      final XFile? xfile = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        preferredCameraDevice: CameraDevice.rear,
      );
      if (xfile == null) return null;

      // Copier dans le répertoire documents de l'app (persistant)
      final dir  = await getApplicationDocumentsDirectory();
      final dest = p.join(dir.path, 'photos',
          '${prefix}_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await Directory(p.dirname(dest)).create(recursive: true);
      await File(xfile.path).copy(dest);
      return dest;
    } catch (e) {
      return null;
    }
  }

  /// Ouvre la galerie et retourne le chemin du fichier.
  static Future<String?> pickFromGallery() async {
    try {
      final XFile? xfile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      if (xfile == null) return null;
      final dir  = await getApplicationDocumentsDirectory();
      final dest = p.join(dir.path, 'photos',
          'gallery_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await Directory(p.dirname(dest)).create(recursive: true);
      await File(xfile.path).copy(dest);
      return dest;
    } catch (e) {
      return null;
    }
  }
}
