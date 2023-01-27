import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:async';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
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
}

Future<ui.Image> loadImage(
    {String? path, Uint8List? imageList, int? height, int? width}) async {
  var list = await File(path!).readAsBytes();
  ui.Codec codec = await ui.instantiateImageCodec(list,
      targetHeight: height, targetWidth: width);
  ui.FrameInfo frame = await codec.getNextFrame();
  return frame.image;
}

class PathFile {
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

class Info {
  String info = '加载中...';
  int? version;
  Dio dio = Dio();
  String appDocDirPath;

  Info({required this.appDocDirPath});

  Future<Response<dynamic>> downloadInfo() async {
    Response response;

    try {
      response = await dio.download(
        'https://github.com/yi226/speed/releases/download/info/info.json',
        '$appDocDirPath${Platform.pathSeparator}doc${Platform.pathSeparator}info.json',
      );
    } catch (e) {
      response = Response(
          requestOptions: RequestOptions(path: ''), statusMessage: '连接超时');
    }
    return response;
  }

  Future deleteInfo() async {
    File file = File(
        '$appDocDirPath${Platform.pathSeparator}doc${Platform.pathSeparator}info.json');
    if (file.existsSync()) {
      await file.delete();
    }
  }

  Future<String> getInfo() async {
    File file = File(
        '$appDocDirPath${Platform.pathSeparator}doc${Platform.pathSeparator}info.json');
    Response? response;
    if (!file.existsSync()) {
      response = await downloadInfo();
      file = File(
          '$appDocDirPath${Platform.pathSeparator}doc${Platform.pathSeparator}info.json');
    }

    if (file.existsSync()) {
      try {
        String jsonString = await file.readAsString();
        var infoJson = json.decode(jsonString);
        info = infoJson['info'];
        version = infoJson['version'];
      } catch (e) {
        info = '$e\n\n文档有误, 请更新文档';
      }
    } else {
      info = '${response?.statusMessage}';
    }

    return info;
  }

  Future<bool?> showInfo(BuildContext context) async {
    return await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Info'),
        content: FutureBuilder(
          future: getInfo(),
          builder: ((context, snapshot) {
            return SizedBox(
              width: 400,
              child: Column(
                children: [
                  Expanded(
                      child: ListView(children: [Text(snapshot.data ?? info)])),
                  const SizedBox(height: 10),
                  Text('Version: $version'),
                  const SizedBox(height: 10),
                  const Text('开发者: 易鹏飞, 李思宇'),
                ],
              ),
            );
          }),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await deleteInfo();
              // ignore: use_build_context_synchronously
              Navigator.pop(context, true);
            },
            child: const Text('更新文档'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
