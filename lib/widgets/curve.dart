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

class SCurveWidget extends StatelessWidget {
  const SCurveWidget({super.key});

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
                    global.canvasOffset += details.delta;
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
                  onSecondaryTapDown: (details) {
                    RenderBox box = context.findRenderObject() as RenderBox;
                    final offset = box.globalToLocal(details.globalPosition);
                    final index = global.sPoints.lastIndexWhere((p) =>
                        (global.fromSPoint(p) + global.canvasOffset - offset)
                            .distance <
                        20);
                    if (index != -1) {
                      global.selectedSIndex = index;
                      global.updateSController();
                    }
                  },
                  child: ClipRect(
                    child: CustomPaint(
                        size: global.canvasSize,
                        painter: _SRectPainter(
                            global.points,
                            global.sPoints,
                            global.image!,
                            global.canvasOffset,
                            global.selectedIndex,
                            global.selectedSIndex,
                            global.resolution)),
                  ),
                );
              }),
      ),
    );
  }
}

class _SRectPainter extends CustomPainter {
  final Paint _red = Paint()..color = Colors.red;
  final Paint _orange = Paint()..color = Colors.orange;
  final Paint _orange2 = Paint()..color = Colors.orange.withOpacity(0.6);
  final Paint _opacityOrange = Paint()..color = Colors.orange.withOpacity(0.2);
  final painter = Paint()
    ..color = Colors.blue
    ..style = PaintingStyle.stroke
    ..isAntiAlias = true
    ..strokeCap = StrokeCap.round
    ..strokeWidth = 2.0;
  final sPainter = Paint()
    ..color = Colors.red
    ..style = PaintingStyle.stroke
    ..isAntiAlias = true
    ..strokeCap = StrokeCap.round
    ..strokeWidth = 3.0;

  final List<Point> pointList;
  final ui.Image image;
  final int selectedIndex;
  final int selectedSIndex;
  final Offset canvasOffset;
  final List<SpeedPoint> sPointList;
  final double resolution;
  SpeedPoint? get nPoint =>
      selectedSIndex < 0 ? null : sPointList[selectedSIndex];

  _SRectPainter(this.pointList, this.sPointList, this.image, this.canvasOffset,
      this.selectedIndex, this.selectedSIndex, this.resolution);

  ui.Tangent _getPoint(int i, double t) {
    var path = Path();

    path.moveTo(pointList[i].x, pointList[i].y);
    var x1 = pointList[i].x + pointList[i].control.dx;
    var y1 = pointList[i].y + pointList[i].control.dy;
    var x2 = pointList[i + 1].x - pointList[i + 1].control.dx;
    var y2 = pointList[i + 1].y - pointList[i + 1].control.dy;
    var x3 = pointList[i + 1].x;
    var y3 = pointList[i + 1].y;
    path.cubicTo(x1, y1, x2, y2, x3, y3);

    ui.PathMetric p = path.computeMetrics().elementAt(0);
    return p.getTangentForOffset(t * p.length)!;
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.translate(canvasOffset.dx, canvasOffset.dy);

    canvas.drawImage(image, Offset.zero, Paint());

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

    ///绘制 Path
    canvas.drawPath(path, painter);

    if (nPoint != null) {
      var index = nPoint!.pointIndex;
      var t = nPoint!.t;
      var p = _getPoint(index, t);
      canvas.drawCircle(p.position, 20, _opacityOrange);
      var dest = p.position + Offset.fromDirection(-p.angle, 20);
      canvas.drawLine(p.position, dest, sPainter);
    }

    for (var i = 0; i < sPointList.length; i++) {
      var index = sPointList[i].pointIndex;
      var t = sPointList[i].t;
      var p = _getPoint(index, t);
      canvas.drawCircle(p.position, 5, _orange2);
      ui.ParagraphBuilder pb = ui.ParagraphBuilder(
          ui.ParagraphStyle(fontWeight: FontWeight.normal, fontSize: 15))
        ..pushStyle(ui.TextStyle(color: Colors.orange))
        ..addText(
            's:${sPointList[i].speed * resolution}\nl:${sPointList[i].lead}');
      ui.ParagraphConstraints pc =
          ui.ParagraphConstraints(width: size.width - 100);
      ui.Paragraph paragraph = pb.build()..layout(pc);
      canvas.drawParagraph(paragraph, p.position);
    }

    for (var i = 0; i < pointList.length; i++) {
      var x = pointList[i].x;
      var y = pointList[i].y;
      canvas.drawCircle(Offset(x, y), 5, selectedIndex == i ? _red : _orange);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}
