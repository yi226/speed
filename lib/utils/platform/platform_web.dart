// ignore: avoid_web_libraries_in_flutter
import 'dart:html';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:async';

import 'package:speed/utils/point.dart';
import 'package:fluent_ui/fluent_ui.dart';

class IntegratePlatform {
  static bool get isDesktop => false;
  static bool get isMobile => false;
  static bool get isWeb => true;
  static String get pathSeparator => '/';

  static Future<String> getDirectory() async {
    return '/';
  }

  static Future<List> writeToHFile(
      {required String notes, required String path}) async {
    // export to .h file
    String fileName = "Path.h";
    WebFile.outFile(notes: notes, fileName: fileName);
    return [false, fileName];
  }
}

class WebFile {
  static outFile({required String notes, required String fileName}) {
    var blob = Blob([notes], 'text/plain', 'native');

    AnchorElement(
      href: Url.createObjectUrlFromBlob(blob).toString(),
    )
      ..setAttribute("download", fileName)
      ..click();
  }
}

Future<ui.Image> loadImage(
    {String? path, Uint8List? imageList, int? height, int? width}) async {
  ui.Codec codec = await ui.instantiateImageCodec(imageList!,
      targetHeight: height, targetWidth: width);
  ui.FrameInfo frame = await codec.getNextFrame();
  return frame.image;
}

class PathFile {
  static Future<String?> writeToJSONFile(String notes, String path) async {
    // export to .json file
    String fileName = "path.json";
    WebFile.outFile(notes: notes, fileName: fileName);
    return path;
  }

  static Future<String?> exportPath({
    required List<Point> points,
    required List<SpeedPoint> sPoints,
    required Size canvasSize,
    required double resolution,
    required double robotWidth,
    required String path,
  }) {
    Map out = {
      "width": canvasSize.width,
      "height": canvasSize.height,
      "resolution": resolution,
      "robotWidth": robotWidth,
      "points": [],
      "sPoints": [],
    };
    for (var i = 0; i < points.length; i++) {
      double x = posTransFrom(canvasSize, resolution, x: points[i].x).dx;
      double y = posTransFrom(canvasSize, resolution, y: points[i].y).dy;
      double a = points[i].a;
      double w = points[i].w;
      Offset control = points[i].control.scale(resolution, -resolution);
      (out["points"] as List).add(
          {"x": x, "y": y, "a": a, "w": w, "dx": control.dx, "dy": control.dy});
    }
    for (var i = 0; i < sPoints.length; i++) {
      int pointIndex = sPoints[i].pointIndex;
      double t = sPoints[i].t;
      double speed = sPoints[i].speed * resolution;
      int lead = sPoints[i].lead;
      (out["sPoints"] as List)
          .add({"index": pointIndex, "t": t, "speed": speed, "lead": lead});
    }
    String outString = json.encode(out);
    return writeToJSONFile(outString, path);
  }

  static Future<List?> importPath() async {
    return ['Web 暂不支持'];
  }

  static Offset posTransFrom(Size canvasSize, double resolution,
      {double? x, double? y, Offset? p}) {
    Offset r = Offset.zero;
    Offset o = Offset(canvasSize.width * 0.5, canvasSize.height);
    if (x != null) {
      r = r.translate(x - o.dx, 0);
    }
    if (y != null) {
      r = r.translate(0, o.dy - y);
    }
    if (p != null) {
      r = r.translate(p.dx - o.dx, o.dy - p.dy);
    }
    r = r * resolution;
    return r;
  }
}

class Info {
  String info = 'https://github.com/yi226/speed';
  int version = 1;
  String appDocDirPath;

  Info({required this.appDocDirPath});

  Future<bool?> showInfo(BuildContext context) async {
    return await showDialog(
      context: context,
      builder: (context) => ContentDialog(
        title: const Text('Info'),
        content: Column(
          children: [
            Expanded(child: Text(info)),
            const SizedBox(height: 10),
            Text('Version: $version'),
            const SizedBox(height: 10),
            const Text('开发者: 易鹏飞, 李思宇'),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
