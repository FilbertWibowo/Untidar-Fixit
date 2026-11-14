import 'dart:typed_data';

class PickedPhoto {
  final String name;
  final Uint8List bytes;

  PickedPhoto({
    required this.name,
    required this.bytes,
  });
}
