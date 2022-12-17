import 'dart:ui' as ui;
import 'dart:async';
import 'dart:io';

Future<ui.Image> loadImage(String path, {int? height, int? width}) async {
  var list = await File(path).readAsBytes();
  ui.Codec codec = await ui.instantiateImageCodec(list,
      targetHeight: height, targetWidth: width);
  ui.FrameInfo frame = await codec.getNextFrame();
  return frame.image;
}
