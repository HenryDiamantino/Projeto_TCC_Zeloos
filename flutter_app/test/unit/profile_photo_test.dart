import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_app/utils/profile_photo.dart';
import 'package:flutter_test/flutter_test.dart';

const _red = Color(0xFFFF0000);
const _green = Color(0xFF00FF00);

Future<Uint8List> _redImageWithGreenCenter(int width, int height) async {
  final side = math.min(width, height).toDouble();
  final recorder = ui.PictureRecorder();
  ui.Canvas(recorder)
    ..drawRect(
      Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
      Paint()..color = _red,
    )
    ..drawRect(
      Rect.fromLTWH((width - side) / 2, (height - side) / 2, side, side),
      Paint()..color = _green,
    );
  final image = await recorder.endRecording().toImage(width, height);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  return data!.buffer.asUint8List();
}

Future<ui.Image> _decode(Uint8List png) async {
  final codec = await ui.instantiateImageCodec(png);
  return (await codec.getNextFrame()).image;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('prepareProfilePhoto', () {
    test('reduz fotos grandes para 256 x 256', () async {
      final image = await _decode(
        await prepareProfilePhoto(await _redImageWithGreenCenter(1000, 600)),
      );

      expect([image.width, image.height], [256, 256]);
    });

    test('não aumenta fotos pequenas, apenas deixa quadradas', () async {
      final image = await _decode(
        await prepareProfilePhoto(await _redImageWithGreenCenter(180, 120)),
      );

      expect([image.width, image.height], [120, 120]);
    });

    test('mantém o centro da imagem ao recortar', () async {
      final image = await _decode(
        await prepareProfilePhoto(await _redImageWithGreenCenter(300, 100)),
      );
      final pixels = (await image.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      ))!;

      for (final (x, y) in [(0, 0), (99, 0), (0, 99), (99, 99), (50, 50)]) {
        final offset = (y * image.width + x) * 4;
        expect(
          [
            pixels.getUint8(offset),
            pixels.getUint8(offset + 1),
            pixels.getUint8(offset + 2),
          ],
          [0, 255, 0],
          reason: 'pixel ($x, $y) deveria ser do quadrado verde central',
        );
      }
    });

    test('preenche áreas transparentes com branco', () async {
      final recorder = ui.PictureRecorder();
      ui.Canvas(recorder).drawRect(
        const Rect.fromLTWH(0, 0, 10, 10),
        Paint()..color = const Color(0x00000000),
      );
      final transparent = await (await recorder.endRecording().toImage(
        10,
        10,
      )).toByteData(format: ui.ImageByteFormat.png);

      final image = await _decode(
        await prepareProfilePhoto(transparent!.buffer.asUint8List()),
      );
      final pixels = (await image.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      ))!;

      expect(pixels.getUint32(0), 0xFFFFFFFF);
    });

    test('lança erro quando o arquivo não é uma imagem', () async {
      await expectLater(
        prepareProfilePhoto(Uint8List.fromList([1, 2, 3, 4])),
        throwsException,
      );
    });
  });
}
