import 'package:fluent_ui/fluent_ui.dart';
import 'package:provider/provider.dart';
import 'package:speed/global.dart';
import 'dart:ui' as ui;

import '../utils/point.dart';

class CurveWidget extends StatelessWidget {
  const CurveWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final global = context.watch<Global>();
    return Center(
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(width: 2, color: Colors.black),
        ),
        child: (global.imagePath == null || global.image == null)
            ? SizedBox(
                width: global.canvasSize.width,
                height: global.canvasSize.height,
                child: const FlutterLogo())
            : Builder(builder: (context) {
                return GestureDetector(
                  onPanStart: (details) {
                    RenderBox box = context.findRenderObject() as RenderBox;
                    final offset = box.globalToLocal(details.globalPosition);
                    final index = global.rects.lastIndexWhere((rect) =>
                        (rect.center + global.canvasOffset - offset).distance <
                        rect.shortestSide / 2);
                    global.panIndex = index;
                    if (index != -1) {
                      global.selectedIndex = index ~/ 2;
                    }
                  },
                  onPanUpdate: (details) {
                    if (global.panIndex != -1) {
                      global.updatePoints(global.panIndex, details.delta);
                    } else {
                      global.canvasOffset += details.delta;
                    }
                  },
                  onPanEnd: (details) {
                    global.panIndex = -1;
                  },
                  onTapDown: (details) {
                    RenderBox box = context.findRenderObject() as RenderBox;
                    final offset = box.globalToLocal(details.globalPosition);
                    final index = global.rects.lastIndexWhere((rect) =>
                        (rect.center + global.canvasOffset - offset).distance <
                        rect.shortestSide / 2);
                    if (index != -1) {
                      global.selectedIndex = index ~/ 2;
                    }
                  },
                  child: ClipRect(
                    child: CustomPaint(
                      size: global.canvasSize,
                      painter: _RectPainter(
                          global.rects,
                          global.points,
                          global.image!,
                          global.canvasOffset,
                          global.selectedIndex),
                    ),
                  ),
                );
              }),
      ),
    );
  }
}

class _RectPainter extends CustomPainter {
  final Paint _red = Paint()..color = Colors.red;
  final Paint _orange = Paint()..color = Colors.orange;
  final Paint _green = Paint()..color = Colors.green;
  final Paint _teal = Paint()..color = Colors.teal;
  final painter = Paint()
    ..color = Colors.blue
    ..style = PaintingStyle.stroke
    ..isAntiAlias = true
    ..strokeCap = StrokeCap.round
    ..strokeWidth = 2.0;

  final controlPainter = Paint()
    ..color = Colors.green
    ..style = PaintingStyle.stroke
    ..isAntiAlias = true
    ..strokeCap = StrokeCap.round
    ..strokeWidth = 2.0;

  final List<Rect> rects;
  final List<Point> pointList;
  final ui.Image image;
  final int selectedIndex;
  final Offset canvasOffset;

  _RectPainter(this.rects, this.pointList, this.image, this.canvasOffset,
      this.selectedIndex);

  Paint getColor(index) {
    if (index % 2 == 0) {
      return index ~/ 2 == selectedIndex ? _red : _orange;
    } else {
      return index ~/ 2 == selectedIndex ? _green : _teal;
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.translate(canvasOffset.dx, canvasOffset.dy);

    canvas.drawImage(image, Offset.zero, Paint());

    var i = 0;
    for (Rect rect in rects) {
      canvas.drawCircle(rect.center, rect.shortestSide / 2, getColor(i++));
    }

    for (var i = 0; i < pointList.length; i++) {
      var x1 = pointList[i].x + pointList[i].control.dx;
      var y1 = pointList[i].y + pointList[i].control.dy;
      canvas.drawLine(Offset(pointList[i].x, pointList[i].y), Offset(x1, y1),
          controlPainter);
    }

    if (pointList.length < 2) {
      return;
    }

    ///创建路径
    var path = Path();

    path.moveTo(pointList[0].x, pointList[0].y);

    for (var i = 0; i < pointList.length - 1; i++) {
      var x1 = pointList[i].x + pointList[i].control.dx;
      var y1 = pointList[i].y + pointList[i].control.dy;
      var x2 = pointList[i + 1].x - pointList[i + 1].control.dx;
      var y2 = pointList[i + 1].y - pointList[i + 1].control.dy;
      var x3 = pointList[i + 1].x;
      var y3 = pointList[i + 1].y;
      path.cubicTo(x1, y1, x2, y2, x3, y3);
    }

    // ui.PathMetric p = path.computeMetrics().elementAt(0);

    ///绘制 Path
    canvas.drawPath(path, painter);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}
