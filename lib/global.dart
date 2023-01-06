import 'dart:io';
import 'dart:math';

import 'package:file_picker/file_picker.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speed/utils/load.dart';
import 'package:speed/utils/path_file.dart';
import 'package:speed/utils/path_planning.dart';
import 'package:speed/utils/point.dart';
import 'dart:ui' as ui;

import 'package:speed/widgets/chart.dart';
import 'package:speed/widgets/curve.dart';
import 'package:speed/widgets/info.dart';

// 规划模式
enum CType {
  path('path'),
  speed('speed');

  final String name;
  const CType(this.name);

  static CType parse(String name) {
    return values.firstWhere(
      (v) => v.name == name,
      orElse: () => CType.path,
    );
  }
}

class Global extends ChangeNotifier {
  Global() {
    addPoints(Point(x: 100, y: 100));
    addPoints(Point(x: 200, y: 200));
    initPath();
    initMode();
  }

  initPath() async {
    if (Platform.isWindows || Platform.isLinux) {
      _appDocDirPath = Directory.current.path;
    } else {
      Directory appDocDir = await getApplicationDocumentsDirectory();
      _appDocDirPath = appDocDir.path;
    }
    if (kDebugMode) {
      print(appDocDirPath);
    }
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
      robotWidthController.text = setList[4];
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
          await save('Settings', saveString);
        }
      }
    }
    final firstString = await get('First');
    if (firstString == null) {
      await save('First', '1');
      while (context == null) {}
      Info info = Info(appDocDirPath: appDocDirPath);
      info.showInfo(context!);
    }
    notifyListeners();
  }

  String? _appDocDirPath;
  String get appDocDirPath => _appDocDirPath ?? '.';

  String get saveString =>
      '${mode == ThemeMode.dark}@$imagePath@${canvasSize.height}@$resolution@$robotWidth';

  BuildContext? context;

  ThemeMode _mode = ThemeMode.light;
  ThemeMode get mode => _mode;
  set mode(ThemeMode mode) {
    _mode = mode;
    notifyListeners();
  }

  CType _cType = CType.path;
  CType get cType => _cType;
  set cType(CType cType) {
    _cType = cType;
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

  double get slideValue {
    tTController.text =
        (selectedSIndex == -1 ? 0 : sPoints[selectedSIndex].t).toString();
    return selectedSIndex == -1 ? 0 : sPoints[selectedSIndex].t;
  }

  set slideValue(double value) {
    if (selectedSIndex == -1) {
      return;
    }
    sPoints[selectedSIndex].t = value;
    updateSController();
    notifyListeners();
  }

  updateSController() {
    if (selectedSIndex == -1) {
      return;
    }
    var p = _getPoint(
        sPoints[selectedSIndex].pointIndex, sPoints[selectedSIndex].t);
    xSController.text = posTransFrom(x: p.position.dx).dx.toString();
    ySController.text = posTransFrom(y: p.position.dy).dy.toString();
    tSController.text = (p.angle / pi * 180).toString();
    sController.text = (sPoints[selectedSIndex].speed * resolution).toString();
    lController.text = sPoints[selectedSIndex].lead.toString();
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
  final TextEditingController wController = TextEditingController();
  final TextEditingController aController = TextEditingController();

  final TextEditingController xSController = TextEditingController();
  final TextEditingController ySController = TextEditingController();
  final TextEditingController tSController = TextEditingController();
  final TextEditingController sController = TextEditingController();
  final TextEditingController tTController = TextEditingController();
  final TextEditingController lController = TextEditingController();

  // 差速轮驱动轮轮距
  final robotWidthController = TextEditingController(text: '60');
  double get robotWidth => double.tryParse(robotWidthController.text) ?? 60;

  final List<Point> points = [];
  final List<Rect> rects = [];
  clearPoints() {
    points.clear();
    rects.clear();
  }

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
        points[selectedIndex].x = posTransTo(x: value).dx;
        final point = points[selectedIndex];
        rects[2 * selectedIndex] =
            Rect.fromCircle(center: Offset(point.x, point.y), radius: 10);
        rects[2 * selectedIndex + 1] = Rect.fromCircle(
            center:
                Offset(point.x + point.control.dx, point.y + point.control.dy),
            radius: 6);
        break;
      case 1:
        points[selectedIndex].y = posTransTo(y: value).dy;
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
            -value / 180 * pi, points[selectedIndex].control.distance);
        final point = points[selectedIndex];
        rects[2 * selectedIndex + 1] = Rect.fromCircle(
            center:
                Offset(point.x + point.control.dx, point.y + point.control.dy),
            radius: 6);
        break;
      case 4:
        points[selectedIndex].w = value;
        break;
      case 5:
        points[selectedIndex].a = value;
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
      wController.text = '';
      aController.text = '';
    } else {
      xController.text = posTransFrom(x: points[index].x).dx.toString();
      yController.text = posTransFrom(y: points[index].y).dy.toString();
      dController.text =
          (points[index].control.distance * resolution).toString();
      tController.text =
          (-points[index].control.direction / pi * 180).toString();
      wController.text = points[index].w.toString();
      aController.text = points[index].a.toString();
    }
  }

  List<SpeedPoint> sPoints = [];

  addSPoint() {
    if (selectedIndex == -1) {
      showError('请先选择路径点');
      return;
    }
    SpeedPoint sPoint = SpeedPoint(pointIndex: selectedIndex);
    if (selectedIndex == points.length - 1) {
      sPoint.pointIndex = selectedIndex - 1;
      sPoint.t = 1;
    }
    sPoints.add(sPoint);
    selectedSIndex = sPoints.length - 1;
    updateSController();
    notifyListeners();
  }

  setSPoint(double speed) {
    if (selectedSIndex < 0) {
      return;
    }
    sPoints[selectedSIndex].speed = speed;
    notifyListeners();
  }

  setSPointLead(int lead) {
    if (selectedSIndex < 0) {
      return;
    }
    sPoints[selectedSIndex].lead = lead;
    notifyListeners();
  }

  deleteSPoints(int index) {
    sPoints.removeAt(index);
    if (selectedSIndex > sPoints.length - 1) {
      selectedSIndex = sPoints.length - 1;
    }
    notifyListeners();
  }

  reOrderSPoint() {
    sPoints.sort((a, b) {
      if (a.pointIndex < b.pointIndex) {
        return -1;
      } else if (a.pointIndex == b.pointIndex) {
        return a.t.compareTo(b.t);
      } else {
        return 1;
      }
    });
  }

  completeSPoint() {
    if (cType != CType.speed) {
      showError('请切换为速度模式');
      return;
    }
    if (sPoints.isEmpty) {
      showError('至少需设置一个速度点');
      return;
    }
    reOrderSPoint();
    // 起点没有速度点则增加
    if (!(sPoints[0].pointIndex == 0 && sPoints[0].t == 0)) {
      sPoints.insert(0, SpeedPoint(pointIndex: 0));
    }
    //终点没有速度点则增加
    int end = sPoints.length - 1;
    if (!(sPoints[end].pointIndex == points.length - 2 &&
        sPoints[end].t == 1)) {
      sPoints.add(SpeedPoint(pointIndex: points.length - 2, t: 1));
    }
    notifyListeners();
  }

  int _selectedSIndex = -1;
  int get selectedSIndex => _selectedSIndex;
  set selectedSIndex(int index) {
    _selectedSIndex = index;
    notifyListeners();
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

  Offset _cursorPosition = Offset.zero;
  Offset get cursorPosition => _cursorPosition;
  set cursorPosition(Offset offset) {
    _cursorPosition = posTransFrom(p: offset - canvasOffset);
    notifyListeners();
  }

  ChartType _chartType = ChartType.v;
  ChartType get chartType => _chartType;
  set chartType(ChartType type) {
    _chartType = type;
    notifyListeners();
  }

  PathPlanFunc? func;

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
      cType = CType.path;
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

  Offset posTransTo({double? x, double? y, Offset? p}) {
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

  Offset fromSPoint(SpeedPoint p) {
    return _getPoint(p.pointIndex, p.t).position;
  }

  ui.Tangent _getPoint(int i, double t) {
    var path = Path();

    path.moveTo(points[i].x, points[i].y);
    var x1 = points[i].x + points[i].control.dx;
    var y1 = points[i].y + points[i].control.dy;
    var x2 = points[i + 1].x - points[i + 1].control.dx;
    var y2 = points[i + 1].y - points[i + 1].control.dy;
    var x3 = points[i + 1].x;
    var y3 = points[i + 1].y;
    path.cubicTo(x1, y1, x2, y2, x3, y3);

    ui.PathMetric p = path.computeMetrics().elementAt(0);
    return p.getTangentForOffset(t * p.length)!;
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

  bool checkSPoints() {
    for (var i = 1; i < sPoints.length - 1; i++) {
      if (sPoints[i].speed == 0) {
        return false;
      }
    }
    return true;
  }

  createPath() async {
    if (cType != CType.speed) {
      showError('请切换为速度模式');
      return;
    }
    if (points.length < 2) {
      showError('路径点过少');
      return;
    }
    if (sPoints.length < 3) {
      showError('速度点过少');
      return;
    }
    reOrderSPoint();
    notifyListeners();
    if (!(sPoints.first.pointIndex == 0 && sPoints.first.t == 0)) {
      showError('起始点未设置速度, 请补全');
      return;
    }
    if (!(sPoints.last.pointIndex == points.length - 2 &&
        sPoints.last.t == 1)) {
      showError('终止点未设置速度, 请补全');
      return;
    }
    if (!checkSPoints()) {
      showError('中间速度点速度不能为0');
      return;
    }
    func = PathPlanFunc(
        points: points,
        sPoints: sPoints,
        robotWidth: robotWidth,
        canvasSize: canvasSize,
        resolution: resolution,
        appDocDirPath: appDocDirPath);
    showDialog(
      context: context!,
      builder: (context) => const ContentDialog(
        title: Text('导出中'),
        content: ProgressBar(),
      ),
    );
    await Future.delayed(const Duration(milliseconds: 200));
    func!.outSpeedPlan().then((value) {
      Navigator.pop(context!);
      if (value) {
        showInfo('导出成功\n${func!.fileName}');
      } else {
        showError('导出失败');
        func == null;
      }
    });
  }

  exportPath() async {
    String? outputFile = await FilePicker.platform.saveFile(
      dialogTitle: 'Please select an output file:',
      fileName: 'path.json',
    );
    if (outputFile != null) {
      String? outPath = await PathFile.exportPath(
          points: points,
          sPoints: sPoints,
          canvasSize: canvasSize,
          resolution: resolution,
          robotWidth: robotWidth,
          path: outputFile);
      showInfo(outPath ?? "导出失败，请重试");
    }
  }

  importPath() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null && result.files.single.path != null) {
      List tmp = await PathFile.importPath(result.files.single.path!);
      if (tmp.length == 1) {
        showError(tmp.first.toString());
        return;
      }
      _canvasSize = tmp[0];
      _resolution = tmp[1];
      robotWidthController.text = tmp[2].toString();
      List<Point> oPoints = tmp[3];
      clearPoints();
      for (var element in oPoints) {
        addPoints(element);
      }
      sPoints = tmp[4] as List<SpeedPoint>;
      _selectedIndex = -1;
      _selectedSIndex = -1;
      _canvasOffset = Offset.zero;
      cType = CType.path;
      notifyListeners();
    }
  }

  showSpeedCurve() {
    if (context == null) return;
    if (cType != CType.speed) {
      showError('请切换为速度模式');
      return;
    }
    if (func == null) {
      showError('请先生成代码');
      return;
    }
    var rPoints = func!.rPoints;

    showDialog(
        context: context!,
        builder: (BuildContext context) {
          final global = context.watch<Global>();
          return ContentDialog(
            title: Text('${global.chartType.name}曲线'),
            content: ChartWidget(points: rPoints, type: chartType),
            constraints: const BoxConstraints(maxWidth: 600),
            actions: [
              ComboBox(
                value: global.chartType.name,
                items: ChartType.values
                    .map((e) => ComboBoxItem(
                          value: e.name,
                          child: Text(e.name),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    global.chartType = ChartType.parse(value);
                  }
                },
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          );
        });
  }

  showEmulate() {
    if (context == null) return;
    if (cType != CType.speed) {
      showError('请切换为速度模式');
      return;
    }
    if (func == null) {
      showError('请先生成代码');
      return;
    }

    showDialog(
        context: context!,
        builder: (BuildContext context) {
          return ContentDialog(
            content: ECurveWidget(
                pointList: points,
                image: image!,
                rPointList: func!.rPoints,
                canvasSize: canvasSize,
                posTransTo: posTransTo),
            constraints: const BoxConstraints(maxWidth: 600),
            actions: [
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          );
        });
  }

  showError(String e) {
    showBase('Error', e);
  }

  showInfo(String info) {
    showBase('Info', info);
  }

  showBase(String title, String content) {
    if (context == null) return;
    showDialog(
      context: context!,
      builder: (context) => ContentDialog(
        title: Text(title),
        content: Text(content),
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
    wController.dispose();
    aController.dispose();
    xSController.dispose();
    ySController.dispose();
    tSController.dispose();
    sController.dispose();
    tTController.dispose();
    lController.dispose();
    robotWidthController.dispose();
    image?.dispose();
    super.dispose();
  }
}
