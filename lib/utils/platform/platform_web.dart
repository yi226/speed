// ignore: avoid_web_libraries_in_flutter
import 'dart:html';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:speed/utils/point.dart';
import 'package:flutter/material.dart';

class IntegratePlatform {
  static bool get isDesktop => false;
  static bool get isMobile => false;
  static bool get isWeb => true;
  static String get pathSeparator => '/';

  static Future<String> getDirectory() async {
    return '.';
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

Future<ui.Image> loadImage({String? path, Uint8List? imageList}) async {
  ui.Codec codec = await ui.instantiateImageCodec(imageList!);
  ui.FrameInfo frame = await codec.getNextFrame();
  return frame.image;
}

class PathFile {
  static Future<List> writeToHFile(
      {required String notes, required String path}) async {
    // export to .h file
    String fileName = "Path.h";
    WebFile.outFile(notes: notes, fileName: fileName);
    return [true, fileName];
  }

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
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      withData: true,
    );
    if (result != null) {
      try {
        String setString = String.fromCharCodes(result.files.single.bytes!);
        Map sets = json.decode(setString);
        double width = sets["width"];
        double height = sets["height"];
        Size canvasSize = Size(width, height);
        double resolution = sets["resolution"];
        double robotWidth = sets["robotWidth"];
        List pointsMap = sets["points"];
        List sPointsMap = sets["sPoints"];
        List<Point> points = [];
        List<SpeedPoint> sPoints = [];
        for (var i = 0; i < pointsMap.length; i++) {
          double x =
              posTransTo(canvasSize, resolution, x: pointsMap[i]["x"]).dx;
          double y =
              posTransTo(canvasSize, resolution, y: pointsMap[i]["y"]).dy;
          double a = pointsMap[i]["a"];
          double w = pointsMap[i]["w"];
          double dx = pointsMap[i]["dx"] / resolution;
          double dy = pointsMap[i]["dy"] / (-resolution);
          points.add(Point(x: x, y: y, a: a, w: w, control: Offset(dx, dy)));
        }
        for (var i = 0; i < sPointsMap.length; i++) {
          int pointIndex = sPointsMap[i]["index"];
          double t = sPointsMap[i]["t"];
          double speed = sPointsMap[i]["speed"] / resolution;
          int lead = sPointsMap[i]["lead"];
          sPoints.add(SpeedPoint(
              pointIndex: pointIndex, t: t, speed: speed, lead: lead));
        }
        return [canvasSize, resolution, robotWidth, points, sPoints];
      } catch (e) {
        return [e.toString()];
      }
    }
    return null;
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

  static Offset posTransTo(Size canvasSize, double resolution,
      {double? x, double? y, Offset? p}) {
    Offset r = Offset.zero;
    Offset o = Offset(canvasSize.width * 0.5, canvasSize.height);
    if (x != null) {
      x /= resolution;
      r = r.translate(x + o.dx, 0);
    }
    if (y != null) {
      y /= resolution;
      r = r.translate(0, o.dy - y);
    }
    if (p != null) {
      p /= resolution;
      r = r.translate(p.dx + o.dx, o.dy - p.dy);
    }
    return r;
  }
}

class Version {
  String get now => "2.1";
  String newer = "2.1";

  static Version? _instance;
  static Version get instance => _getInstance();
  static Version _getInstance() {
    _instance ??= Version._internal();
    return _instance!;
  }

  Version._internal();

  bool get update => false;

  Future<bool> shouldUpdate() async {
    return false;
  }

  Future<void> showUpdate(BuildContext context) async {}
}
