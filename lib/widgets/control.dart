import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:speed/global.dart';
import 'package:speed/utils/extensions.dart';
import 'package:speed/utils/input_format.dart';
import 'package:speed/utils/point.dart';

class ControlWidget extends StatelessWidget {
  const ControlWidget({super.key});

  Future<bool?> showAlert(BuildContext context) async {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('温馨提示'),
        content: const Text('您确定要删除吗?'),
        actions: [
          TextButton(
            child: const Text('Delete'),
            onPressed: () {
              Navigator.pop(context, true);
              // Delete file here
            },
          ),
          ElevatedButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context, false),
          ),
        ],
      ),
    );
  }

  List<Widget> inputWidget(
      bool enabled,
      Function(int, String) onUpdate,
      TextEditingController x,
      TextEditingController y,
      TextEditingController d,
      TextEditingController t,
      TextEditingController w,
      TextEditingController a) {
    return [
      const SizedBox(height: 20),
      Row(
        children: [
          Expanded(
            child: TextField(
              decoration: const InputDecoration(
                label: Text('X(mm)'),
                helperText: 'mm',
                border: OutlineInputBorder(),
              ),
              enabled: enabled,
              controller: x,
              onSubmitted: (value) => onUpdate(0, value),
              inputFormatters: [XNumberTextInputFormatter()],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              decoration: const InputDecoration(
                label: Text('Y(mm)'),
                helperText: 'mm',
                border: OutlineInputBorder(),
              ),
              enabled: enabled,
              controller: y,
              onSubmitted: (value) => onUpdate(1, value),
              inputFormatters: [XNumberTextInputFormatter()],
            ),
          ),
        ],
      ),
      const SizedBox(height: 20),
      const Text('控制点'),
      const SizedBox(height: 20),
      Row(
        children: [
          Expanded(
            child: TextField(
              decoration: const InputDecoration(
                label: Text('Lambda(mm)'),
                helperText: 'mm',
                border: OutlineInputBorder(),
              ),
              enabled: enabled,
              controller: d,
              onSubmitted: (value) => onUpdate(2, value),
              inputFormatters: [
                XNumberTextInputFormatter(isAllowNegative: false)
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              decoration: const InputDecoration(
                label: Text('Theta(mm)'),
                helperText: 'o',
                border: OutlineInputBorder(),
              ),
              enabled: enabled,
              controller: t,
              onSubmitted: (value) => onUpdate(3, value),
              inputFormatters: [XNumberTextInputFormatter()],
            ),
          ),
        ],
      ),
      const SizedBox(height: 20),
      const Text('位姿控制'),
      const SizedBox(height: 20),
      Row(
        children: [
          Expanded(
            child: TextField(
              decoration: const InputDecoration(
                label: Text('w(o/s)'),
                helperText: '角速度',
                border: OutlineInputBorder(),
              ),
              enabled: enabled,
              controller: w,
              onSubmitted: (value) => onUpdate(4, value),
              inputFormatters: [XNumberTextInputFormatter()],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              decoration: const InputDecoration(
                label: Text('a(o)'),
                helperText: '位姿',
                border: OutlineInputBorder(),
              ),
              enabled: enabled,
              controller: a,
              onSubmitted: (value) => onUpdate(5, value),
              inputFormatters: [XNumberTextInputFormatter()],
            ),
          ),
        ],
      ),
    ];
  }

  addPoint(Global global) {
    if (global.image == null) {
      return;
    }
    if (global.selectedIndex != -1) {
      final cPoint = global.points[global.selectedIndex];
      double x =
          cPoint.x + cPoint.control.dx / (cPoint.control.distance + 1) * 80;
      double y =
          cPoint.y + cPoint.control.dy / (cPoint.control.distance + 1) * 80;
      if (cPoint.control.distance < 0.1) {
        x += 20;
        y += 20;
      }
      global.addPoints(Point(x: x, y: y), index: global.selectedIndex + 1);
    } else {
      global.addPoints(Point(), index: global.selectedIndex + 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final global = context.watch<Global>();
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                title: Text(global.cType.name),
                subtitle: Text('第${global.selectedIndex + 1}个点'),
                trailing: SizedBox(
                  width: 280,
                  child: Row(
                    children: [
                      FilledButton(
                        onPressed: () async {
                          if (global.selectedIndex == -1) {
                            return;
                          }
                          final result = await showAlert(context);
                          if (result == true) {
                            global.deletePoints();
                          }
                        },
                        child: const Text('删除'),
                      ),
                      const SizedBox(width: 10),
                      FilledButton(
                        onPressed: (() => addPoint(global)),
                        child: const Text('在此后加点'),
                      ),
                      const SizedBox(width: 10),
                      FilledButton(
                        onPressed: () {
                          global.canvasOffset = Offset.zero;
                          global.canvasScale = 1;
                        },
                        child: const Text('图片归位'),
                      ),
                    ],
                  ),
                ),
              ),
              ...inputWidget(global.selectedIndex != -1,
                  (int type, String value) {
                if (value.isEmpty) {
                  return;
                }
                global.setPoints(type, value.toDouble());
              }, global.xController, global.yController, global.dController,
                  global.tController, global.wController, global.aController),
            ],
          ),
        ),
      ),
    );
  }
}

class SControlWidget extends StatelessWidget {
  const SControlWidget({super.key});

  List<Widget> inputWidget(x, y, theta, s, l, func, funcL, resolution) {
    return [
      Row(
        children: [
          Expanded(
            child: TextField(
              decoration: const InputDecoration(
                label: Text('X(mm)'),
                border: OutlineInputBorder(),
              ),
              controller: x,
              readOnly: true,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              decoration: const InputDecoration(
                label: Text('Y(mm)'),
                border: OutlineInputBorder(),
              ),
              controller: y,
              readOnly: true,
            ),
          ),
        ],
      ),
      const SizedBox(height: 20),
      TextField(
        decoration: const InputDecoration(
          label: Text('Theta(o)'),
          border: OutlineInputBorder(),
        ),
        controller: theta,
        readOnly: true,
      ),
      const SizedBox(height: 20),
      TextField(
        decoration: const InputDecoration(
          label: Text('Speed(mm/s)'),
          border: OutlineInputBorder(),
        ),
        controller: s,
        onSubmitted: (value) {
          if (value.isNotEmpty) {
            double v = value.toDouble();
            v = v / resolution;
            func.call(v);
          }
        },
        inputFormatters: [XNumberTextInputFormatter(isAllowNegative: false)],
      ),
      const SizedBox(height: 20),
      TextField(
        decoration: const InputDecoration(
          label: Text('超前滞后'),
          border: OutlineInputBorder(),
        ),
        controller: l,
        onSubmitted: (value) {
          if (value.isNotEmpty) {
            int lead = value.toInt();
            funcL.call(lead);
          }
        },
        inputFormatters: [XNumberTextInputFormatter(isAllowDecimal: false)],
      ),
      const SizedBox(height: 20),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final global = context.watch<Global>();
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                title: Text(global.cType.name),
                subtitle: Text(
                    '第${global.selectedSIndex + 1}/${global.sPoints.length}点'),
                trailing: SizedBox(
                  width: 285,
                  child: Row(
                    children: [
                      FilledButton(
                        onPressed: () {
                          global.addSPoint();
                        },
                        child: Text('第${global.selectedIndex + 1}个路径点添加速度点'),
                      ),
                      const SizedBox(width: 10),
                      FilledButton(
                        onPressed: () {
                          global.canvasOffset = Offset.zero;
                          global.canvasScale = 1;
                        },
                        child: const Text('图片归位'),
                      ),
                    ],
                  ),
                ),
              ),
              ...inputWidget(
                  global.xSController,
                  global.ySController,
                  global.tSController,
                  global.sController,
                  global.lController,
                  global.setSPoint,
                  global.setSPointLead,
                  global.resolution),
              TextField(
                decoration: const InputDecoration(
                  label: Text('t(0~1)'),
                  border: OutlineInputBorder(),
                ),
                controller: global.tTController,
                onSubmitted: (value) {
                  if (value.isNotEmpty) {
                    double v = value.toDouble();
                    if (v > 1) {
                      v = 1;
                    }
                    global.slideValue = v;
                  }
                },
                inputFormatters: [
                  XNumberTextInputFormatter(isAllowNegative: false)
                ],
              ),
              Slider(
                overlayColor:
                    const MaterialStatePropertyAll(Color.fromARGB(0, 0, 0, 0)),
                value: global.slideValue,
                onChanged: (v) => global.slideValue = v,
                max: 1.0,
              ),
              Row(
                children: [
                  ElevatedButton(
                    onPressed: () {
                      double speed = global.sController.text.toDouble();
                      speed = speed / global.resolution;
                      int lead = global.lController.text.toInt();
                      global.setSPoint(speed);
                      global.setSPointLead(lead);
                      global.selectedSIndex = -1;
                    },
                    child: const Text('确认'),
                  ),
                  const SizedBox(width: 20),
                  ElevatedButton(
                    onPressed: () {
                      if (global.selectedSIndex == -1) {
                        return;
                      }
                      global.deleteSPoints(global.selectedSIndex);
                    },
                    child: const Text('删除'),
                  ),
                  const SizedBox(width: 20),
                  TextButton(
                    onPressed: () {
                      int tmp = global.selectedSIndex - 1;
                      if (tmp < 0) {
                        tmp = global.sPoints.length - 1;
                      }
                      global.selectedSIndex = tmp;
                    },
                    child: const Text('上一个'),
                  ),
                  const SizedBox(width: 10),
                  TextButton(
                    onPressed: () {
                      int tmp = global.selectedSIndex + 1;
                      if (tmp > global.sPoints.length - 1) {
                        tmp = -1;
                      }
                      global.selectedSIndex = tmp;
                    },
                    child: const Text('下一个'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
