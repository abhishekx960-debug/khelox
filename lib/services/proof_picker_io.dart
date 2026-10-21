import 'dart:convert';

import 'package:image_picker/image_picker.dart';

const bool kProofPickerSupported = true;
const int _maxBytes = 3145728;

class PickedProofImage {
  final String dataUrl;
  final String name;

  const PickedProofImage(this.dataUrl, this.name);
}

Future<PickedProofImage?> pickProofImage() async {
  final picked = await ImagePicker().pickImage(
    source: ImageSource.gallery,
    maxWidth: 2000,
    imageQuality: 85,
  );
  if (picked == null) return null;

  final bytes = await picked.readAsBytes();
  if (bytes.length > _maxBytes) {
    throw 'Image must be smaller than 3MB';
  }

  final dataUrl =
      'data:${_mimeType(picked.name)};base64,${base64Encode(bytes)}';
  return PickedProofImage(dataUrl, picked.name);
}

String _mimeType(String name) {
  final lower = name.toLowerCase();
  if (lower.endsWith('.png')) return 'image/png';
  if (lower.endsWith('.webp')) return 'image/webp';
  if (lower.endsWith('.gif')) return 'image/gif';
  return 'image/jpeg';
}
