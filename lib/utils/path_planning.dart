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

  double parse(String name) {
    switch (name) {
      case '速度':
        return v;
      case '位姿':
        return a;
      case '角速度':
        return w;
      case '超前滞后':
        return leadlag.toDouble();
      default:
        return v;
    }
  }
}

class PathPlanFunc {
  double robotWidth;
  Size canvasSize;
  final List<Point> _points = [];
  final List<SpeedPoint> _sPoints = [];
  String fileName = '';
  double resolution;
  List<CAPPoint> rPoints = [];
  String appDocDirPath;

  List<Point> get points => _points;
  List<SpeedPoint> get sPoints => _sPoints;

  PathPlanFunc({
    required List<Point> points,
    required List<SpeedPoint> sPoints,
    required this.robotWidth,
    required this.canvasSize,
    required this.resolution,
    required this.appDocDirPath,
  }) {
    for (var e in points) {
      _points.add(Point(
        x: posTransFrom(x: e.x).dx,
        y: posTransFrom(y: e.y).dy,
        a: e.a,
        w: e.w,
        control: e.control.scale(resolution, -resolution),
      ));
    }
    for (var e in sPoints) {
      _sPoints.add(SpeedPoint(
        pointIndex: e.pointIndex,
        t: e.t,
        speed: e.speed * resolution,
        lead: e.lead,
      ));
    }
  }

  bool equalTo(PathPlanFunc func) {
    if (_points.length != func.points.length) return false;
    if (_sPoints.length != func.sPoints.length) return false;
    if (robotWidth != func.robotWidth) return false;
    if (canvasSize != func.canvasSize) return false;
    if (resolution != func.resolution) return false;
    for (var i = 0; i < _points.length; i++) {
      if (!_points[i].equalTo(func.points[i])) return false;
    }
    for (var i = 0; i < _sPoints.length; i++) {
      if (!_sPoints[i].equalTo(func.sPoints[i])) return false;
    }
    return true;
  }

  ui.Tangent _getPointFromS(int i, double s) {
    int a = _sPoints[i].pointIndex;
    int b = _sPoints[i + 1].pointIndex;
    var path = Path();
    path.moveTo(_points[a].x, _points[a].y);
    for (var j = a; j <= b; j++) {
      var x1 = _points[j].x + _points[j].control.dx;
      var y1 = _points[j].y + _points[j].control.dy;
      var x2 = _points[j + 1].x - _points[j + 1].control.dx;
      var y2 = _points[j + 1].y - _points[j + 1].control.dy;
      var x3 = _points[j + 1].x;
      var y3 = _points[j + 1].y;
      path.cubicTo(x1, y1, x2, y2, x3, y3);
    }

    ui.PathMetric p = path.computeMetrics().elementAt(0);
    return p.getTangentForOffset(_getBezierS(a) * _sPoints[i].t + s)!;
  }

  double _getBezierS(int i) {
    var path = ui.Path();
    path.moveTo(_points[i].x, _points[i].y);
    var x1 = _points[i].x + _points[i].control.dx;
    var y1 = _points[i].y + _points[i].control.dy;
    var x2 = _points[i + 1].x - _points[i + 1].control.dx;
    var y2 = _points[i + 1].y - _points[i + 1].control.dy;
    var x3 = _points[i + 1].x;
    var y3 = _points[i + 1].y;
    path.cubicTo(x1, y1, x2, y2, x3, y3);

    ui.PathMetric p = path.computeMetrics().elementAt(0);
    return p.length;
  }

  double _getS(int a, int b) {
    double s = 0;
    int i = _sPoints[a].pointIndex;
    int j = _sPoints[b].pointIndex;
    if (i == j) {
      s = _getBezierS(i) * (_sPoints[b].t - _sPoints[a].t);
    } else {
      s += _getBezierS(i) * (1 - _sPoints[a].t);
      for (i = i + 1; i < j; i++) {
        s += _getBezierS(i);
      }
      s += _getBezierS(j) * _sPoints[b].t;
    }
    return s;
  }

  Future<void> speedPlan() async {
    double dt = 0.01 / 20;
    double S, v1, v2, v, tFac;
    double t = 0, s = 0, T = 0;
    rPoints.clear();
    for (var i = 0; i < _sPoints.length - 1; i++) {
      bool done = true;
      S = _getS(i, i + 1);
      v1 = _sPoints[i].speed.abs();
      v2 = _sPoints[i + 1].speed.abs();
      tFac = pi * (v1 + v2) / 2.0 / S;
      t = 0;
      s = 0;
      v = v1;
      var p = _getPointFromS(i, s);
      CAPPoint capTmp = CAPPoint(vec: p.position);
      capTmp.c = -p.angle;
      capTmp.v = v1;
      capTmp.leadlag = _sPoints[i].lead;
      capTmp.t = T;
      rPoints.add(capTmp);
      while (done) {
        for (var i = 0; i < 20; i++) {
          t += dt;
          T += dt;
          s += v * dt;
          if (s + v * dt > S) {
            done = false;
            break;
          }
          v = v1 + 0.5 * (v2 - v1) * (1 - cos(tFac * t));
        }
        if (done) {
          var p = _getPointFromS(i, s);
          CAPPoint capTmp = CAPPoint(vec: p.position);
          capTmp.c = -p.angle;
          capTmp.v = v;
          capTmp.leadlag = _sPoints[i + 1].lead;
          capTmp.t = T;
          rPoints.add(capTmp);
        }
      }
    }
    rPoints.add(CAPPoint(
        vec: Offset(_points.last.x, _points.last.y),
        c: _points.last.control.direction,
        v: _sPoints.last.speed,
        leadlag: _sPoints.last.lead,
        t: T));
    // 位姿规划
    // 找到路径规划点对应速度规划点
    List<int> pathPointIndexs = [0];
    for (var i = 1; i < _points.length - 1; i++) {
      int index = rPoints.indexWhere(
          (e) =>
              (e.vec.dx - _points[i].x).abs() < 1e-6 &&
              (e.vec.dy - _points[i].y).abs() < 1e-6,
          pathPointIndexs.last);
      for (var j = 1; index == -1; j += 10) {
        index = rPoints.indexWhere(
            (e) =>
                (e.vec.dx - _points[i].x).abs() < 1e-5 * j &&
                (e.vec.dy - _points[i].y).abs() < 1e-5 * j,
            pathPointIndexs.last);
      }
      pathPointIndexs.add(index);
    }
    // 最后一个规划点 => 最后一个路径点
    pathPointIndexs.add(rPoints.length - 1);
    if (kDebugMode) {
      print(pathPointIndexs);
    }
    for (var i = 0; i < _points.length - 1; i++) {
      double sita1 = _points[i].a;
      double sita2 = _points[i + 1].a;
      double w1 = _points[i].w;
      double w2 = _points[i + 1].w;
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
    String notes =
        '/* ref_x,    ref_y,    ref_theta,   ref_pose,    ref_delta,    ref_v,    ref_preivew*/\n';
    notes += 'const NavigationPoints path_red0[PATHLENGTH0] = {\n';
    for (var i = 0; i < rPoints.length; i++) {
      var x = rPoints[i].vec.dx.toStringAsFixed(6);
      var y = rPoints[i].vec.dy.toStringAsFixed(6);
      var theta = rPoints[i].c.toStringAsFixed(6);
      var pose = (rPoints[i].a * pi / 180).toStringAsFixed(6);
      var delta = atan(robotWidth).abs().toStringAsFixed(6);
      var v = rPoints[i].v.toStringAsFixed(6);
      var pre = rPoints[i].leadlag.toStringAsFixed(6);
      notes += '{$x,$y,$theta,$pose,$delta,$v,$pre},   //${i + 1}\n';
    }
    notes += '};\n';
    notes += 'const NavigationPoints path_blue0[PATHLENGTH0] = {\n';
    for (var i = 0; i < rPoints.length; i++) {
      var x = (-rPoints[i].vec.dx).toStringAsFixed(6);
      var y = rPoints[i].vec.dy.toStringAsFixed(6);
      var theta = (pi - rPoints[i].c).toStringAsFixed(6);
      var pose = (pi - rPoints[i].a * pi / 180).toStringAsFixed(6);
      var delta = (-atan(robotWidth).abs()).toStringAsFixed(6);
      var v = rPoints[i].v.toStringAsFixed(6);
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
        '$appDocDirPath${Platform.pathSeparator}Path$i.h';
    File file = File(fileName);
    while (file.existsSync()) {
      i++;
      fileName =
          '$appDocDirPath${Platform.pathSeparator}Path$i.h';
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
