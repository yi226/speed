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
