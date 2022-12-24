import 'package:fluent_ui/fluent_ui.dart';

class Point {
  double x;
  double y;
  double a;
  double w;
  Offset control;

  Point({
    this.x = 0,
    this.y = 0,
    this.a = 0,
    this.w = 0,
    this.control = const Offset(0, 0),
  });
}

class SpeedPoint {
  int pointIndex;
  double t; // 0~1
  double speed;
  SpeedPoint({required this.pointIndex, this.t = 0, this.speed = 0});
}
