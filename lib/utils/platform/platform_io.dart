import 'dart:io';
import 'dart:convert';
import 'dart:ui' as ui;
import 'dart:async';

import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:speed/utils/point.dart';
import 'package:flutter/material.dart';

class IntegratePlatform {
  static bool get isDesktop =>
      Platform.isLinux || Platform.isWindows || Platform.isMacOS;
  static bool get isMobile => Platform.isAndroid || Platform.isIOS;
  static bool get isWeb => false;
  static String get pathSeparator => Platform.pathSeparator;

  static Future<String> getDirectory() async {
    String path;
    if (isDesktop) {
      path = Directory.current.path;
    } else {
      Directory appDocDir = await getApplicationDocumentsDirectory();
      path = appDocDir.path;
    }
    return path;
  }
}

Future<ui.Image> loadImage({String? path, Uint8List? imageList}) async {
  var list = await File(path!).readAsBytes();
  ui.Codec codec = await ui.instantiateImageCodec(list);
  ui.FrameInfo frame = await codec.getNextFrame();
  return frame.image;
}

class PathFile {
  static Future<List> writeToHFile(
      {required String notes, required String path}) async {
    // export to .h file
    int i = 0;
    String fileName = '$path${Platform.pathSeparator}Path$i.h';
    File file = File(fileName);
    while (file.existsSync()) {
      i++;
      fileName = '$path${Platform.pathSeparator}Path$i.h';
      file = File(fileName);
    }
    await file.create(recursive: true);
    File file1 = await file.writeAsString(notes);
    if (file1.existsSync()) {
      fileName = file1.path;
      return [true, fileName];
    }
    return [false, fileName];
  }

  static Future<String?> writeToJSONFile(String notes, String path) async {
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
    return writeToJSONFile(outString, path);
  }

  static Future<List?> importPath() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (result != null && result.files.single.path != null) {
      try {
        File file = File(result.files.single.path!);
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
          double x =
              posTransTo(canvasSize, resolution, x: pointsMap[i]["x"]).dx;
          double y =
              posTransTo(canvasSize, resolution, y: pointsMap[i]["y"]).dy;
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
          sPoints.add(SpeedPoint(
              pointIndex: pointIndex, t: t, speed: speed, lead: lead));
        }
        return [canvasSize, resolution, robotWidth, points, sPoints];
      } catch (e) {
        return [e.toString()];
      }
    }
    return null;
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

class Version {
  final Dio _dio = Dio();

  String get now => "1.0";
  String? newer;
  String? info;
  String? url;
  String? name;

  static Version? _instance;
  static Version get instance => _getInstance();
  static Version _getInstance() {
    _instance ??= Version._internal();
    return _instance!;
  }

  Version._internal();

  bool get update => newer != null && newer != now;

  Future<bool> shouldUpdate() async {
    if (newer != null) {
      return now != newer;
    }
    try {
      await Future.delayed(const Duration(seconds: 1));
      var response = await _dio.get(
        "https://github.com/yi226/Config/releases/download/speed/update.json",
      );
      var data = json.decode(response.data);
      newer = data["version"];
      info = data["info"];
      if (Platform.isAndroid) {
        url = data["android"];
      } else if (Platform.isWindows) {
        url = data["windows"];
      } else if (Platform.isLinux) {
        url = data["linux"];
      }
      if (url != null) {
        name = url!.split('/').last;
      }
      return now != newer;
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
    }
    newer = now;
    return false;
  }

  Future<void> _showError(BuildContext context, {String? info}) async {
    await showDialog(
        context: context,
        builder: (context) => AlertDialog(
              title: Text(info ?? "更新失败"),
              actions: [
                ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text("确定"))
              ],
            ));
  }

  Future<void> _updateProcess(BuildContext context) async {
    if (url == null || name == null) {
      await _showError(context, info: "该系统暂不支持在线更新");
      return;
    }
    var percent = ValueNotifier<double>(0);
    BuildContext contextSaved = context;
    String path = "";
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          contextSaved = context;
          return AlertDialog(
            title: const Text("下载中"),
            content: SizedBox(
              height: 60,
              child: ValueListenableBuilder(
                  valueListenable: percent,
                  builder: (context, value, child) {
                    if (value == 1) {
                      OpenFilex.open(path);
                      percent.dispose();
                      if (IntegratePlatform.isDesktop) {
                        appWindow.close();
                      }
                    }
                    return Column(
                      children: [
                        Text("进度: ${(value * 100).toStringAsFixed(1)}%"),
                        LinearProgressIndicator(value: value),
                      ],
                    );
                  }),
            ),
          );
        });

    Directory dir = await getApplicationDocumentsDirectory();
    path = dir.path + Platform.pathSeparator + name!;
    if (kDebugMode) {
      print(path);
    }
    try {
      await _dio.download(url!, path, onReceiveProgress: (count, total) {
        if (total != -1) {
          percent.value = count / total;
        }
      }, options: Options(contentType: "stream"));
    } catch (e) {
      // ignore: use_build_context_synchronously
      Navigator.of(contextSaved).pop();
      // ignore: use_build_context_synchronously
      _showError(contextSaved, info: e.toString());
    }
  }

  Future<void> showUpdate(BuildContext context) async {
    if (newer == null || newer == now) return;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("新版本"),
          content: SizedBox(
            height: 150,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("版本号: $newer"),
                Text("更新内容:\n$info"),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: const Text("取消"),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: const Text("更新"),
              onPressed: () {
                Navigator.of(context).pop();
                _updateProcess(context);
              },
            ),
          ],
        );
      },
    );
  }
}
