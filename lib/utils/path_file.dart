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
      double x = points[i].x;
      double y = points[i].y;
      double a = points[i].a;
      double w = points[i].w;
      Offset control = points[i].control;
      (out["points"] as List).add(
          {"x": x, "y": y, "a": a, "w": w, "dx": control.dx, "dy": control.dy});
    }
    for (var i = 0; i < sPoints.length; i++) {
      int pointIndex = sPoints[i].pointIndex;
      double t = sPoints[i].t;
      double speed = sPoints[i].speed;
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
      double resolution = sets["resolution"];
      double robotWidth = sets["robotWidth"];
      List pointsMap = sets["points"];
      List sPointsMap = sets["sPoints"];
      List<Point> points = [];
      List<SpeedPoint> sPoints = [];
      for (var i = 0; i < pointsMap.length; i++) {
        double x = pointsMap[i]["x"];
        double y = pointsMap[i]["y"];
        double a = pointsMap[i]["a"];
        double w = pointsMap[i]["w"];
        double dx = pointsMap[i]["dx"];
        double dy = pointsMap[i]["dy"];
        points.add(Point(x: x, y: y, a: a, w: w, control: Offset(dx, dy)));
      }
      for (var i = 0; i < sPointsMap.length; i++) {
        int pointIndex = sPointsMap[i]["index"];
        double t = sPointsMap[i]["t"];
        double speed = sPointsMap[i]["speed"];
        int lead = sPointsMap[i]["lead"];
        sPoints.add(
            SpeedPoint(pointIndex: pointIndex, t: t, speed: speed, lead: lead));
      }
      return [Size(width, height), resolution, robotWidth, points, sPoints];
    } catch (e) {
      return [e.toString()];
    }
  }
}
