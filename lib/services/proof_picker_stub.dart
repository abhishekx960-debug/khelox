/// Fallback used on platforms without an HTML file input.
/// Mobile/desktop builds can paste a proof image URL instead.
const bool kProofPickerSupported = false;

class PickedProofImage {
  final String dataUrl;
  final String name;

  const PickedProofImage(this.dataUrl, this.name);
}

Future<PickedProofImage?> pickProofImage() async => null;
