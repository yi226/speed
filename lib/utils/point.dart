import 'package:flutter/material.dart';

class Point {
  double x;
  double y;
  double a;
  double w;
  Offset control;

  Point({
    this.x = 0,
    this.y = 0,
    this.a = 0, // 位姿
    this.w = 0, // 角速度
    this.control = Offset.zero, // 控制点相对向量
  });

  bool equalTo(Point point) {
    if (x != point.x) return false;
    if (y != point.y) return false;
    if (a != point.a) return false;
    if (w != point.w) return false;
    if (control != point.control) return false;
    return true;
  }
}

class SpeedPoint {
  int pointIndex;
  double t; // 0~1
  double speed;
  int lead; // 超前滞后
  SpeedPoint(
      {required this.pointIndex, this.t = 0, this.speed = 0, this.lead = 0});

  bool equalTo(SpeedPoint point) {
    if (pointIndex != point.pointIndex) return false;
    if (t != point.t) return false;
    if (speed != point.speed) return false;
    if (lead != point.lead) return false;
    return true;
  }
}
