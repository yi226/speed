import 'dart:convert';
import 'dart:io';

import 'package:speed/utils/point.dart';
import 'package:fluent_ui/fluent_ui.dart';

class PathFile {
  static Future<String?> writeToFile(String notes, String path) async {
    // export to .json file
    File file = File(path);
    try {
      await file.create(recursive: true);
      await file.writeAsString(notes);
    } catch (e) {
      return e.toString();
    }
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
    return writeToFile(outString, path);
  }

  static Future<List> importPath(String path) async {
    try {
      File file = File(path);
      String setString = await file.readAsString();
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
        double x = posTransTo(canvasSize, resolution, x: pointsMap[i]["x"]).dx;
        double y = posTransTo(canvasSize, resolution, y: pointsMap[i]["y"]).dy;
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
        sPoints.add(
            SpeedPoint(pointIndex: pointIndex, t: t, speed: speed, lead: lead));
      }
      return [canvasSize, resolution, robotWidth, points, sPoints];
    } catch (e) {
      return [e.toString()];
    }
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
