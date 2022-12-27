import 'package:fluent_ui/fluent_ui.dart';
import 'package:provider/provider.dart';
import 'package:speed/global.dart';
import 'package:speed/utils/input_format.dart';
import 'package:speed/utils/point.dart';

class ControlWidget extends StatelessWidget {
  const ControlWidget({super.key});

  Future<bool?> showAlert(BuildContext context) async {
    return showDialog<bool>(
      context: context,
      builder: (context) => ContentDialog(
        title: const Text('温馨提示'),
        content: const Text('您确定要删除吗?'),
        actions: [
          Button(
            child: const Text('Delete'),
            onPressed: () {
              Navigator.pop(context, true);
              // Delete file here
            },
          ),
          FilledButton(
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
            child: TextBox(
              header: 'X(mm)',
              placeholder: 'mm',
              enabled: enabled,
              controller: x,
              onSubmitted: (value) => onUpdate(0, value),
              inputFormatters: [XNumberTextInputFormatter()],
            ),
          ),
          Expanded(
            child: TextBox(
              header: 'Y(mm)',
              placeholder: 'mm',
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
            child: TextBox(
              header: 'Lambda(mm)',
              placeholder: 'mm',
              enabled: enabled,
              controller: d,
              onSubmitted: (value) => onUpdate(2, value),
              inputFormatters: [XNumberTextInputFormatter()],
            ),
          ),
          Expanded(
            child: TextBox(
              header: 'Theta',
              placeholder: 'o',
              enabled: enabled,
              controller: t,
              onSubmitted: (value) => onUpdate(3, value),
              inputFormatters: [XNumberTextInputFormatter()],
            ),
          ),
        ],
      ),
      const SizedBox(height: 20),
      const Text('其他数值'),
      const SizedBox(height: 20),
      Row(
        children: [
          Expanded(
            child: TextBox(
              header: 'w',
              placeholder: '角速度',
              enabled: enabled,
              controller: w,
              onSubmitted: (value) => onUpdate(4, value),
              inputFormatters: [XNumberTextInputFormatter()],
            ),
          ),
          Expanded(
            child: TextBox(
              header: 'a',
              placeholder: '加速度',
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
    if (global.imagePath == null) {
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              leading: const Icon(FluentIcons.location),
              title: Text(global.cType.name),
              subtitle: Text('第${global.selectedIndex + 1}个点'),
              trailing: Row(
                children: [
                  FilledButton(
                    style: ButtonStyle(
                        backgroundColor: ButtonState.all(
                            global.selectedIndex != -1
                                ? Colors.red
                                : Colors.grey)),
                    onPressed: () async {
                      if (global.selectedIndex == -1) {
                        return;
                      }
                      final result = await showAlert(context);
                      if (result == true) {
                        global.deletePoints(global.selectedIndex);
                      }
                    },
                    child: const Text('删除'),
                  ),
                  const SizedBox(width: 30),
                  FilledButton(
                    onPressed: (() => addPoint(global)),
                    child: const Text('在此后加点'),
                  ),
                  const SizedBox(width: 30),
                  FilledButton(
                    onPressed: () {
                      global.canvasOffset = Offset.zero;
                    },
                    child: const Text('图片归位'),
                  ),
                ],
              ),
            ),
            ...inputWidget(global.selectedIndex != -1,
                (int type, String value) {
              if (value.isEmpty) {
                return;
              }
              global.setPoints(type, double.parse(value));
            }, global.xController, global.yController, global.dController,
                global.tController, global.wController, global.aController),
          ],
        ),
      ),
    );
  }
}

class SControlWidget extends StatelessWidget {
  const SControlWidget({super.key});

  List<Widget> inputWidget(x, y, theta, s, l, func, funcL) {
    return [
      Row(
        children: [
          Expanded(
            child: TextBox(
              header: 'X(mm)',
              placeholder: 'mm',
              controller: x,
              readOnly: true,
            ),
          ),
          Expanded(
            child: TextBox(
              header: 'Y(mm)',
              placeholder: 'mm',
              controller: y,
              readOnly: true,
            ),
          ),
        ],
      ),
      const SizedBox(height: 20),
      TextBox(
        header: 'Theta',
        placeholder: 'o',
        controller: theta,
        readOnly: true,
      ),
      const SizedBox(height: 20),
      TextBox(
        header: 'Speed',
        placeholder: 'mm/s',
        controller: s,
        onSubmitted: (value) {
          if (value.isNotEmpty) {
            double v = double.parse(value);
            func.call(v);
          }
        },
        inputFormatters: [XNumberTextInputFormatter()],
      ),
      const SizedBox(height: 20),
      TextBox(
        header: '超前滞后',
        placeholder: '个数',
        controller: l,
        onSubmitted: (value) {
          if (value.isNotEmpty) {
            int v = int.parse(value);
            funcL.call(v);
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              leading: const Icon(FluentIcons.location),
              title: Text(global.cType.name),
              subtitle: Text(
                  '第${global.selectedSIndex + 1}/${global.sPoints.length}个点'),
              trailing: Row(
                children: [
                  FilledButton(
                    onPressed: () {
                      global.addSPoint();
                    },
                    child: Text('第${global.selectedIndex + 1}个路径点添加速度点'),
                  ),
                  const SizedBox(width: 20),
                  FilledButton(
                    onPressed: () {
                      global.canvasOffset = Offset.zero;
                    },
                    child: const Text('图片归位'),
                  ),
                ],
              ),
            ),
            ...inputWidget(
                global.xSController,
                global.ySController,
                global.tSController,
                global.sController,
                global.lController,
                global.setSPoint,
                global.setSPointLead),
            TextBox(
              header: 't',
              placeholder: '0~1',
              controller: global.tTController,
              onSubmitted: (value) {
                if (value.isNotEmpty) {
                  double v = double.parse(value);
                  if (v > 1) {
                    v = 1;
                  }
                  global.slideValue = v;
                }
              },
              inputFormatters: [XNumberTextInputFormatter()],
            ),
            Slider(
              value: global.slideValue,
              onChanged: (v) => global.slideValue = v,
              max: 1.0,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                FilledButton(
                  onPressed: () {
                    double speed = double.parse(global.sController.text);
                    int lead = int.parse(global.lController.text);
                    global.setSPoint(speed);
                    global.setSPointLead(lead);
                    global.selectedSIndex = -1;
                  },
                  child: const Text('确认'),
                ),
                const SizedBox(width: 20),
                FilledButton(
                  style: ButtonStyle(
                      backgroundColor: ButtonState.all(
                          global.selectedSIndex != -1
                              ? Colors.red
                              : Colors.grey)),
                  onPressed: () {
                    if (global.selectedSIndex == -1) {
                      return;
                    }
                    global.deleteSPoints(global.selectedSIndex);
                  },
                  child: const Text('删除'),
                ),
                const SizedBox(width: 20),
                Button(
                  onPressed: () {
                    global.selectedSIndex -= 1;
                    if (global.selectedSIndex < 0) {
                      global.selectedSIndex = global.sPoints.length - 1;
                    }
                    global.updateSController();
                  },
                  child: const Text('上一个'),
                ),
                const SizedBox(width: 10),
                Button(
                  onPressed: () {
                    global.selectedSIndex += 1;
                    if (global.selectedSIndex > global.sPoints.length - 1) {
                      global.selectedSIndex = -1;
                    }
                    global.updateSController();
                  },
                  child: const Text('下一个'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
