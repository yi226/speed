import 'dart:math';

import 'package:file_picker/file_picker.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speed/utils/load.dart';
import 'package:speed/utils/point.dart';
import 'dart:ui' as ui;

class Global extends ChangeNotifier {
  Global() {
    addPoints(Point(x: 100, y: 100));
    addPoints(Point(x: 200, y: 200));
    initMode();
  }

  initMode() async {
    final setString = await get('Settings');
    if (setString != null) {
      final setList = setString.split('@');
      if (kDebugMode) {
        print(setList);
      }
      _mode = setList[0] == 'true' ? ThemeMode.dark : ThemeMode.light;
      _imagePath = setList[1] == 'null' ? null : setList[1];
      _canvasSize = Size(500, double.parse(setList[2]));
      _resolution = double.parse(setList[3]);
      if (_imagePath != null) {
        try {
          image = await loadImage(_imagePath!,
              height: _canvasSize.height.toInt(),
              width: _canvasSize.width.toInt());
        } catch (e) {
          while (context == null) {}
          showError(e.toString());
          _imagePath = null;
          image = null;
          await save('Settings',
              '${mode == ThemeMode.dark}@$imagePath@${canvasSize.height}@$resolution');
        }
      }
    }
    notifyListeners();
  }

  BuildContext? context;

  ThemeMode _mode = ThemeMode.light;
  ThemeMode get mode => _mode;
  set mode(ThemeMode mode) {
    _mode = mode;
    notifyListeners();
  }

  String? _imagePath;
  ui.Image? image;
  String? get imagePath {
    return _imagePath;
  }

  int _selectedIndex = -1;
  int get selectedIndex => _selectedIndex;
  set selectedIndex(int index) {
    _selectedIndex = index;
    updateController(index);
    notifyListeners();
  }

  int _panIndex = -1;
  int get panIndex => _panIndex;
  set panIndex(int index) {
    _panIndex = index;
    notifyListeners();
  }

  bool _settingSave = false;
  bool get settingSave => _settingSave;
  set settingSave(bool s) {
    _settingSave = s;
    notifyListeners();
  }

  final TextEditingController xController = TextEditingController();
  final TextEditingController yController = TextEditingController();
  final TextEditingController dController = TextEditingController();
  final TextEditingController tController = TextEditingController();

  final List<Point> points = [];
  final List<Rect> rects = [];
  addPoints(Point point, {int? index}) {
    if (index == null) {
      points.add(point);
      rects.add(Rect.fromCircle(center: Offset(point.x, point.y), radius: 10));
      rects.add(Rect.fromCircle(
          center:
              Offset(point.x + point.control.dx, point.y + point.control.dy),
          radius: 6));
    } else {
      points.insert(index, point);
      rects.insert(
          2 * index,
          Rect.fromCircle(
              center: Offset(
                  point.x + point.control.dx, point.y + point.control.dy),
              radius: 6));
      rects.insert(2 * index,
          Rect.fromCircle(center: Offset(point.x, point.y), radius: 10));
      selectedIndex = index;
    }
    notifyListeners();
  }

  deletePoints(int index) {
    points.removeAt(index);
    rects.removeAt(2 * index);
    rects.removeAt(2 * index);
    if (selectedIndex > points.length - 1) {
      selectedIndex = points.length - 1;
    }
    notifyListeners();
  }

  updatePoints(int index, Offset offset) {
    if (index % 2 == 0) {
      index = index ~/ 2;
      points[index].x = points[index].x + offset.dx;
      points[index].y = points[index].y + offset.dy;
      rects[2 * index] = rects[2 * index].shift(offset);
      rects[2 * index + 1] = rects[2 * index + 1].shift(offset);
    } else {
      index = index ~/ 2;
      points[index].control = points[index].control + offset;
      rects[2 * index + 1] = rects[2 * index + 1].shift(offset);
    }
    updateController(index);
    notifyListeners();
  }

  setPoints(int type, double value) {
    switch (type) {
      case 0:
        points[selectedIndex].x = value / resolution;
        final point = points[selectedIndex];
        rects[2 * selectedIndex] =
            Rect.fromCircle(center: Offset(point.x, point.y), radius: 10);
        rects[2 * selectedIndex + 1] = Rect.fromCircle(
            center:
                Offset(point.x + point.control.dx, point.y + point.control.dy),
            radius: 6);
        break;
      case 1:
        points[selectedIndex].y = value / resolution;
        final point = points[selectedIndex];
        rects[2 * selectedIndex] =
            Rect.fromCircle(center: Offset(point.x, point.y), radius: 10);
        rects[2 * selectedIndex + 1] = Rect.fromCircle(
            center:
                Offset(point.x + point.control.dx, point.y + point.control.dy),
            radius: 6);
        break;
      case 2:
        points[selectedIndex].control = Offset.fromDirection(
            points[selectedIndex].control.direction, value / resolution);
        final point = points[selectedIndex];
        rects[2 * selectedIndex + 1] = Rect.fromCircle(
            center:
                Offset(point.x + point.control.dx, point.y + point.control.dy),
            radius: 6);
        break;
      case 3:
        points[selectedIndex].control = Offset.fromDirection(
            value / 180 * pi, points[selectedIndex].control.distance);
        final point = points[selectedIndex];
        rects[2 * selectedIndex + 1] = Rect.fromCircle(
            center:
                Offset(point.x + point.control.dx, point.y + point.control.dy),
            radius: 6);
        break;
    }

    notifyListeners();
  }

  updateController(int index) {
    if (index == -1) {
      xController.text = '';
      yController.text = '';
      dController.text = '';
      tController.text = '';
    } else {
      xController.text = (points[index].x * resolution).toString();
      yController.text = (points[index].y * resolution).toString();
      dController.text =
          (points[index].control.distance * resolution).toString();
      tController.text =
          (points[index].control.direction / pi * 180).toString();
    }
  }

  Size _canvasSize = const Size(500, 500);
  Size get canvasSize => _canvasSize;
  set canvasSize(Size size) {
    _canvasSize = size;
    notifyListeners();
  }

  double _resolution = 1;
  double get resolution => _resolution;
  set resolution(double r) {
    _resolution = r;
    notifyListeners();
  }

  Offset _canvasOffset = Offset.zero;
  Offset get canvasOffset => _canvasOffset;
  set canvasOffset(Offset offset) {
    _canvasOffset = offset;
    notifyListeners();
  }

  //* Functions
  setImagePath() async {
    _imagePath = await _getFilePath();
    if (_imagePath != null) {
      image = await loadImage(_imagePath!,
          height: _canvasSize.height.toInt(), width: _canvasSize.width.toInt());
    } else {
      image?.dispose();
      image = null;
      selectedIndex = -1;
    }
    notifyListeners();
  }

  Future<String?> _getFilePath() async {
    FilePickerResult? result =
        await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null) {
      return result.files.single.path;
    } else {
      return null;
    }
  }

  ui.PathMetric get getPathMatrix {
    var path = ui.Path();

    path.moveTo(points[0].x, points[0].y);

    for (var i = 0; i < points.length - 1; i++) {
      var x1 = points[i].x + points[i].control.dx;
      var y1 = points[i].y + points[i].control.dy;
      var x2 = points[i + 1].x - points[i + 1].control.dx;
      var y2 = points[i + 1].y - points[i + 1].control.dy;
      var x3 = points[i + 1].x;
      var y3 = points[i + 1].y;
      path.cubicTo(x1, y1, x2, y2, x3, y3);
    }

    ui.PathMetric p = path.computeMetrics().elementAt(0);
    double theta = p.getTangentForOffset(0)!.angle;
    double speed = tan(theta);
    return p;
  }

  Future<String?> get(String key) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var userName = prefs.getString(key);
    return userName;
  }

  Future save(String key, String value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  showError(String e) {
    if (context == null) return;
    showDialog(
      context: context!,
      builder: (context) => ContentDialog(
        title: const Text('Error'),
        content: Text(e),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    xController.dispose();
    yController.dispose();
    dController.dispose();
    tController.dispose();
    image?.dispose();
    super.dispose();
  }
}
