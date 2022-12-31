import 'dart:io';
import 'dart:math';

import 'dart:ui' as ui;

import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:speed/utils/point.dart';

class CAPPoint {
  Offset vec;
  double c;
  double v;
  double a;
  double w;
  double t;
  int leadlag;

  CAPPoint({
    required this.vec,
    this.c = 0,
    this.v = 0,
    this.a = 0,
    this.w = 0,
    this.t = 0,
    this.leadlag = 0,
  });

  bool equal(CAPPoint p) {
    return vec == p.vec;
  }
}

class PathPlanFunc {
  double robotWidth;
  Size canvasSize;
  List<Point> points;
  List<SpeedPoint> sPoints;
  String fileName = '';
  double resolution;
  List<CAPPoint> rPoints = [];
  String appDocDirPath;

  PathPlanFunc(
      {required this.points,
      required this.sPoints,
      required this.robotWidth,
      required this.canvasSize,
      required this.resolution,
      required this.appDocDirPath});

  ui.Tangent _getPointFromS(int i, double s) {
    int a = sPoints[i].pointIndex;
    int b = sPoints[i + 1].pointIndex;
    var path = Path();
    path.moveTo(points[a].x, points[a].y);
    for (var j = a; j <= b; j++) {
      var x1 = points[j].x + points[j].control.dx;
      var y1 = points[j].y + points[j].control.dy;
      var x2 = points[j + 1].x - points[j + 1].control.dx;
      var y2 = points[j + 1].y - points[j + 1].control.dy;
      var x3 = points[j + 1].x;
      var y3 = points[j + 1].y;
      path.cubicTo(x1, y1, x2, y2, x3, y3);
    }

    ui.PathMetric p = path.computeMetrics().elementAt(0);
    return p.getTangentForOffset(_getBezierS(a) * sPoints[i].t + s)!;
  }

  double _getBezierS(int i) {
    var path = ui.Path();
    path.moveTo(points[i].x, points[i].y);
    var x1 = points[i].x + points[i].control.dx;
    var y1 = points[i].y + points[i].control.dy;
    var x2 = points[i + 1].x - points[i + 1].control.dx;
    var y2 = points[i + 1].y - points[i + 1].control.dy;
    var x3 = points[i + 1].x;
    var y3 = points[i + 1].y;
    path.cubicTo(x1, y1, x2, y2, x3, y3);

    ui.PathMetric p = path.computeMetrics().elementAt(0);
    return p.length;
  }

  double _getS(int a, int b) {
    double s = 0;
    int i = sPoints[a].pointIndex;
    int j = sPoints[b].pointIndex;
    if (i == j) {
      s = _getBezierS(i) * (sPoints[b].t - sPoints[a].t);
    } else {
      s += _getBezierS(i) * (1 - sPoints[a].t);
      for (i = i + 1; i < j; i++) {
        s += _getBezierS(i);
      }
      s += _getBezierS(j) * sPoints[b].t;
    }
    return s;
  }

  void speedPlan() {
    double dt = 0.01;
    double S, v1, v2, v, tFac;
    double t = 0, s = 0, T = 0;
    rPoints.clear();
    for (var i = 0; i < sPoints.length - 1; i++) {
      S = _getS(i, i + 1);
      v1 = sPoints[i].speed.abs();
      v2 = sPoints[i + 1].speed.abs();
      tFac = pi * (v1 + v2) / 2.0 / S;
      t = 0;
      s = 0;
      while (true) {
        v = v1 + 0.5 * (v2 - v1) * (1 - cos(tFac * t));
        if (s >= S) {
          break;
        }
        var p = _getPointFromS(i, s);
        CAPPoint capTmp = CAPPoint(vec: p.position);
        capTmp.c = p.angle;
        capTmp.v = v;
        capTmp.leadlag = sPoints[i].lead;
        capTmp.t = T;
        rPoints.add(capTmp);
        s += v * dt;
        t += dt;
        T += dt;
      }
    }
    rPoints.add(CAPPoint(
        vec: Offset(points.last.x, points.last.y),
        c: -points.last.control.direction,
        v: sPoints.last.speed,
        leadlag: sPoints.last.lead,
        t: T));
    // 去重
    for (var i = rPoints.length - 1; i > 0; i--) {
      if (rPoints[i].equal(rPoints[i - 1])) {
        rPoints.removeAt(i);
      }
    }
    // 位姿规划
    // 找到路径规划点对应速度规划点
    List pathPointIndexs = [];
    for (var i = 0; i < points.length; i++) {
      int index = rPoints.indexWhere((e) =>
          (e.vec.dx - points[i].x).abs() < 1e-6 &&
          (e.vec.dy - points[i].y).abs() < 1e-6);
      for (var j = 1; index == -1; j += 10) {
        index = rPoints.indexWhere((e) =>
            (e.vec.dx - points[i].x).abs() < 1e-3 * j &&
            (e.vec.dy - points[i].y).abs() < 1e-3 * j);
      }
      pathPointIndexs.add(index);
    }
    if (kDebugMode) {
      print(pathPointIndexs);
    }
    for (var i = 0; i < points.length - 1; i++) {
      double sita1 = points[i].a;
      double sita2 = points[i + 1].a;
      double w1 = points[i].w;
      double w2 = points[i + 1].w;
      int i1 = pathPointIndexs[i];
      int i2 = pathPointIndexs[i + 1];
      double T = rPoints[i2].t - rPoints[i1].t;
      for (var j = i1; j <= i2; j++) {
        double t = rPoints[j].t - rPoints[i1].t;
        rPoints[j].a = poseCaculate(sita1, sita2, w1, w2, T, t, true);
        rPoints[j].w = poseCaculate(sita1, sita2, w1, w2, T, t, false);
      }
    }
  }

  double poseCaculate(double sita1, double sita2, double w1, double w2,
      double T, double t, bool selectSW) {
    double A, B, C, E, F;
    double sita;
    double w;

    A = (sita2 - sita1 - (w1 + w2) * T / 2.0) /
        (T / 2.0 - sin(T) + 1 / 12.0 * T * T * sin(T) + 1 / 2.0 * T * cos(T));
    C = (w2 - w1 - A * (1 - cos(T)) + 1 / 3.0 * A * T * sin(T)) * 6 / (T * T);
    B = (-A * sin(T) - C * T) / (T * T);
    E = w1 + A;
    F = sita1;
    sita = -A * sin(t) +
        1 / 12.0 * B * pow(t, 4) +
        1 / 6.0 * C * pow(t, 3) +
        E * t +
        F;
    w = -A * cos(t) + 1 / 3.0 * B * pow(t, 3) + 1 / 2.0 * C * pow(t, 2) + E;

    return selectSW ? sita : w;
  }

  Offset posTransFrom({double? x, double? y, Offset? p}) {
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

  Future<bool> outSpeedPlan() {
    speedPlan();
    String notes =
        '/* ref_x,    ref_y,    ref_theta,   ref_pose,    ref_delta,    ref_v,    ref_preivew*/\n';
    notes += 'const NavigationPoints path_red0[PATHLENGTH0] = {\n';
    for (var i = 0; i < rPoints.length; i++) {
      var x = posTransFrom(x: rPoints[i].vec.dx).dx.toStringAsFixed(6);
      var y = posTransFrom(y: rPoints[i].vec.dy).dy.toStringAsFixed(6);
      var theta = rPoints[i].c.toStringAsFixed(6);
      var pose = rPoints[i].a.toStringAsFixed(6);
      var delta = atan(robotWidth).abs().toStringAsFixed(6);
      var v = (rPoints[i].v * resolution).toStringAsFixed(6);
      var pre = rPoints[i].leadlag.toStringAsFixed(6);
      notes += '{$x,$y,$theta,$pose,$delta,$v,$pre},   //${i + 1}\n';
    }
    notes += '};\n';
    notes += 'const NavigationPoints path_blue0[PATHLENGTH0] = {\n';
    for (var i = 0; i < rPoints.length; i++) {
      var x = (-posTransFrom(x: rPoints[i].vec.dx).dx).toStringAsFixed(6);
      var y = posTransFrom(y: rPoints[i].vec.dy).dy.toStringAsFixed(6);
      var theta = (pi - rPoints[i].c).toStringAsFixed(6);
      var pose = (pi - rPoints[i].a).toStringAsFixed(6);
      var delta = (-atan(robotWidth).abs()).toStringAsFixed(6);
      var v = (rPoints[i].v * resolution).toStringAsFixed(6);
      var pre = rPoints[i].leadlag.toStringAsFixed(6);
      notes += '{$x,$y,$theta,$pose,$delta,$v,$pre},   //${i + 1}\n';
    }
    notes += '};\n';
    return writeToFile(notes);
  }

  Future<bool> writeToFile(String notes) async {
    // export to .h file
    int i = 0;
    fileName =
        '$appDocDirPath${Platform.pathSeparator}path${Platform.pathSeparator}Path$i.h';
    File file = File(fileName);
    while (file.existsSync()) {
      i++;
      fileName =
          '$appDocDirPath${Platform.pathSeparator}path${Platform.pathSeparator}Path$i.h';
      file = File(fileName);
    }
    await file.create(recursive: true);
    File file1 = await file.writeAsString(notes);
    if (file1.existsSync()) {
      fileName = file1.path;
      return true;
    }
    return false;
  }
}
