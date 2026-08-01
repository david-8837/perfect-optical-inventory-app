// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

void pickImageFromDevice(void Function(String dataUri) onPicked) {
  final uploadInput = html.FileUploadInputElement()..accept = 'image/*';
  uploadInput.click();
  uploadInput.onChange.listen((e) {
    final files = uploadInput.files;
    if (files != null && files.isNotEmpty) {
      final file = files[0];
      final reader = html.FileReader();
      reader.readAsDataUrl(file);
      reader.onLoadEnd.listen((_) {
        final result = reader.result as String?;
        if (result != null && result.isNotEmpty) {
          onPicked(result);
        }
      });
    }
  });
}
