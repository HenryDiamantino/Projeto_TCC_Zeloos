import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

Future<Uint8List> prepareProfilePhoto(Uint8List bytes, {int size = 256}) async {
  final codec = await ui.instantiateImageCodecWithSize(
    await ui.ImmutableBuffer.fromUint8List(bytes),
    getTargetSize: (width, height) => math.min(width, height) <= size
        ? const ui.TargetImageSize()
        : width <= height
        ? ui.TargetImageSize(width: size)
        : ui.TargetImageSize(height: size),
  );
  final image = (await codec.getNextFrame()).image;
  codec.dispose();

  final side = math.min(image.width, image.height);
  final recorder = ui.PictureRecorder();
  ui.Canvas(recorder)
    ..drawColor(const ui.Color(0xFFFFFFFF), ui.BlendMode.src)
    ..drawImage(
      image,
      ui.Offset(
        -((image.width - side) ~/ 2).toDouble(),
        -((image.height - side) ~/ 2).toDouble(),
      ),
      ui.Paint(),
    );
  final picture = recorder.endRecording();
  final square = await picture.toImage(side, side);
  final png = await square.toByteData(format: ui.ImageByteFormat.png);
  picture.dispose();
  square.dispose();
  image.dispose();
  return png!.buffer.asUint8List();
}
