// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:async';
import 'dart:html' as html;

const bool kProofPickerSupported = true;
const int _maxBytes = 3145728;

class PickedProofImage {
  final String dataUrl;
  final String name;

  const PickedProofImage(this.dataUrl, this.name);
}

Future<PickedProofImage?> pickProofImage() {
  final completer = Completer<PickedProofImage?>();
  final input = html.FileUploadInputElement()
    ..accept = 'image/png,image/jpeg,image/webp,image/gif';

  input.onChange.listen((_) {
    final files = input.files;
    if (files == null || files.isEmpty) {
      if (!completer.isCompleted) completer.complete(null);
      return;
    }
    final file = files.first;
    if (file.size > _maxBytes) {
      if (!completer.isCompleted) {
        completer.completeError('Image 3MB se choti honi chahiye');
      }
      return;
    }
    final reader = html.FileReader();
    reader.onLoadEnd.listen((_) {
      final result = reader.result;
      if (result is String && !completer.isCompleted) {
        completer.complete(PickedProofImage(result, file.name));
      } else if (!completer.isCompleted) {
        completer.complete(null);
      }
    });
    reader.onError.listen((_) {
      if (!completer.isCompleted) {
        completer.completeError('Image padhi nahi ja saki');
      }
    });
    reader.readAsDataUrl(file);
  });

  input.click();
  return completer.future;
}
