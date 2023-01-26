import 'dart:math';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:provider/provider.dart';
import 'package:speed/global.dart';
import 'package:speed/utils/path_planning.dart';
import 'dart:ui' as ui;

import '../utils/point.dart';

class IndexFunc {
  static int getIndex(Global global, Offset offset) {
    return global.points.indexWhere(
        (e) => (Offset(e.x, e.y) + global.canvasOffset - offset).distance < 10);
  }

  static int getControlIndex(Global global, Offset offset) {
    return global.points.indexWhere((e) =>
        (Offset(e.x, e.y) + e.control + global.canvasOffset - offset).distance <
        6);
  }

  static int getControl2Index(Global global, Offset offset) {
    return global.points.indexWhere((e) =>
        (Offset(e.x, e.y) - e.control + global.canvasOffset - offset).distance <
        6);
  }

  static int getSpeedIndex(Global global, Offset offset) {
    return global.sPoints.lastIndexWhere((p) =>
        (global.fromSPoint(p) + global.canvasOffset - offset).distance < 20);
  }
}

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
        child: (global.image == null)
            ? SizedBox(
                width: global.canvasSize.width,
                height: global.canvasSize.height,
                child: const FlutterLogo())
            : Builder(
                builder: (context) {
                  return GestureDetector(
                    onPanStart: (details) {
                      var box = context.findRenderObject() as RenderBox;
                      var offset = box.globalToLocal(details.globalPosition);
                      int index = IndexFunc.getControlIndex(global, offset);
                      if (index != -1) {
                        global.panIndex = 3 * index + 1;
                      } else {
                        index = IndexFunc.getControl2Index(global, offset);
                        if (index != -1) {
                          global.panIndex = 3 * index + 2;
                        } else {
                          index = IndexFunc.getIndex(global, offset);
                          if (index != -1) global.panIndex = 3 * index;
                        }
                      }
                      if (index != -1) {
                        global.selectedIndex = index;
                      } else {
                        global.panIndex = -1;
                      }
                    },
                    onPanUpdate: (details) {
                      if (global.panIndex != -1) {
                        global.updatePoints(details.delta);
                      } else {
                        global.canvasOffset += details.delta;
                      }
                    },
                    onTapDown: (details) {
                      var box = context.findRenderObject() as RenderBox;
                      var offset = box.globalToLocal(details.globalPosition);
                      int index = IndexFunc.getControlIndex(global, offset);
                      if (index == -1) {
                        index = IndexFunc.getControl2Index(global, offset);
                      }
                      if (index == -1) {
                        index = IndexFunc.getIndex(global, offset);
                      }
                      if (index != -1) {
                        global.selectedIndex = index;
                      }
                    },
                    child: ClipRect(
                      child: CustomPaint(
                        size: global.canvasSize,
                        painter: _RectPainter(
                          global.points,
                          global.image!,
                          global.canvasOffset,
                          global.selectedIndex,
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}

class _RectPainter extends CustomPainter {
  final Paint _red = Paint()..color = Colors.red;
  final Paint _orange = Paint()..color = Colors.orange;
  final Paint _green = Paint()..color = Colors.green;
  final Paint _teal = Paint()..color = Colors.teal;
  final Paint _greenOpacity = Paint()..color = Colors.green.withOpacity(0.5);
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

  final control2Painter = Paint()
    ..color = Colors.green.withOpacity(0.5)
    ..style = PaintingStyle.stroke
    ..isAntiAlias = true
    ..strokeCap = StrokeCap.round
    ..strokeWidth = 2.0;

  final List<Point> pointList;
  final ui.Image image;
  final int selectedIndex;
  final Offset canvasOffset;

  _RectPainter(
      this.pointList, this.image, this.canvasOffset, this.selectedIndex);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.translate(canvasOffset.dx, canvasOffset.dy);

    canvas.drawImage(image, Offset.zero, Paint());

    for (var i = 0; i < pointList.length; i++) {
      final center = Offset(pointList[i].x, pointList[i].y);
      final control = center + pointList[i].control;
      final control2 = center - pointList[i].control;
      canvas.drawCircle(center, 10, i == selectedIndex ? _red : _orange);
      canvas.drawCircle(control2, 6, _greenOpacity);
      canvas.drawCircle(control, 6, i == selectedIndex ? _green : _teal);
      canvas.drawLine(center, control, controlPainter);
      canvas.drawLine(center, control2, control2Painter);
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
      canvas.drawLine(Offset(x1, y1), Offset(x2, y2), control2Painter);
    }

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
        child: (global.image == null)
            ? SizedBox(
                width: global.canvasSize.width,
                height: global.canvasSize.height,
                child: const FlutterLogo())
            : Builder(builder: (context) {
                return GestureDetector(
                  onPanUpdate: (details) {
                    global.canvasOffset += details.delta;
                  },
                  onTapDown: (details) {
                    var box = context.findRenderObject() as RenderBox;
                    var offset = box.globalToLocal(details.globalPosition);
                    int index = IndexFunc.getIndex(global, offset);
                    if (index != -1) {
                      global.selectedIndex = index;
                    }
                  },
                  onSecondaryTapDown: (details) {
                    var box = context.findRenderObject() as RenderBox;
                    var offset = box.globalToLocal(details.globalPosition);
                    int index = IndexFunc.getSpeedIndex(global, offset);
                    if (index != -1) {
                      global.selectedSIndex = index;
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

class ECurveWidget extends StatefulWidget {
  final List<Point> pointList;
  final ui.Image image;
  final List<CAPPoint> rPointList;
  final Size canvasSize;
  final Function posTransTo;
  const ECurveWidget(
      {super.key,
      required this.pointList,
      required this.image,
      required this.rPointList,
      required this.canvasSize,
      required this.posTransTo});

  @override
  State<ECurveWidget> createState() => _ECurveWidgetState();
}

class _ECurveWidgetState extends State<ECurveWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    int sT = widget.rPointList.last.t.floor();
    int mT = ((widget.rPointList.last.t - sT) * 1000).ceil();
    _controller = AnimationController(
        duration: Duration(seconds: sT, milliseconds: mT), vsync: this);
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  int getIndex(double value) {
    int len = widget.rPointList.length - 1;
    return (value * len).round();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Container(
              decoration: BoxDecoration(
                border: Border.all(width: 2, color: Colors.black),
              ),
              child: ClipRect(
                  child: CustomPaint(
                      size: widget.canvasSize,
                      painter: _ERectPainter(
                          widget.pointList,
                          widget.image,
                          widget.rPointList[getIndex(_controller.value)],
                          widget.posTransTo))),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('时间:'),
                Text(
                    '${widget.rPointList[getIndex(_controller.value)].t.toStringAsFixed(2)}s'),
                const SizedBox(height: 10),
                VerticalProgressBar(
                    width: 20, height: 400, value: _controller.value),
                const SizedBox(height: 20),
                child!,
              ],
            )
          ],
        );
      },
      child: Card(
        padding: EdgeInsets.zero,
        child: IconButton(
            icon: const Icon(FluentIcons.update_restore, size: 20),
            onPressed: () {
              _controller.reset();
              _controller.forward();
            }),
      ),
    );
  }
}

class _ERectPainter extends CustomPainter {
  final Paint _red = Paint()..color = Colors.red;
  final Paint _orange = Paint()..color = Colors.orange;
  final painter = Paint()
    ..color = Colors.blue
    ..style = PaintingStyle.stroke
    ..isAntiAlias = true
    ..strokeCap = StrokeCap.round
    ..strokeWidth = 2.0;
  final dPainter = Paint()
    ..color = Colors.red
    ..style = PaintingStyle.stroke
    ..isAntiAlias = true
    ..strokeCap = StrokeCap.round
    ..strokeWidth = 3.0;
  final cPainter = Paint()
    ..color = Colors.orange.withOpacity(0.5)
    ..style = PaintingStyle.fill;

  final List<Point> pointList;
  final ui.Image image;
  final CAPPoint rPoint;
  Function posTransTo;

  _ERectPainter(this.pointList, this.image, this.rPoint, this.posTransTo);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawImage(image, Offset.zero, Paint());

    if (pointList.length < 2) {
      return;
    }

    // 创建路径
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

    canvas.drawCircle(Offset(pointList.first.x, pointList.first.y), 5, _orange);
    canvas.drawCircle(Offset(pointList.last.x, pointList.last.y), 5, _orange);

    // 创建三角形
    var triPath = Path();
    Offset center = posTransTo(p: rPoint.vec);
    Offset a = center + Offset.fromDirection(-rPoint.c, 20);
    Offset b = center + Offset.fromDirection(-rPoint.c + 120 / 180 * pi, 20);
    Offset c = center + Offset.fromDirection(-rPoint.c - 120 / 180 * pi, 20);
    triPath.moveTo(a.dx, a.dy);
    triPath.lineTo(b.dx, b.dy);
    triPath.lineTo(c.dx, c.dy);
    canvas.drawPath(triPath, cPainter);
    // 绘制方向
    canvas.drawCircle(center, 5, _red);
    canvas.drawLine(center, a, dPainter);
    // 绘制速度
    ui.ParagraphBuilder pb = ui.ParagraphBuilder(
        ui.ParagraphStyle(fontWeight: FontWeight.normal, fontSize: 15))
      ..pushStyle(ui.TextStyle(color: Colors.red))
      ..addText('v:${rPoint.v.round()}');
    ui.ParagraphConstraints pc =
        ui.ParagraphConstraints(width: size.width - 100);
    ui.Paragraph paragraph = pb.build()..layout(pc);
    canvas.drawParagraph(paragraph, center);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}

class VerticalProgressBar extends StatelessWidget {
  final double width;
  final double height;
  final double value;
  const VerticalProgressBar({
    super.key,
    required this.width,
    required this.height,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(4.0)),
        border: Border.all(width: 2, color: Colors.black),
      ),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          height: height * value,
          decoration: BoxDecoration(
            color: Colors.orange,
            borderRadius: const BorderRadius.all(Radius.circular(4.0)),
          ),
        ),
      ),
    );
  }
}
