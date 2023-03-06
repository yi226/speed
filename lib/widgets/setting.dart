import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:speed/global.dart';
import 'package:speed/utils/extensions.dart';
import 'package:speed/utils/input_format.dart';
import 'package:speed/utils/platform/platform.dart';

class SettingWidget extends StatelessWidget {
  const SettingWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final global = context.watch<Global>();
    return SizedBox(
      width: 400,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ListView(
              children: [
                SwitchListTile(
                  value: global.mode == ThemeMode.dark,
                  onChanged: (value) {
                    global.mode = value ? ThemeMode.dark : ThemeMode.light;
                  },
                  title: const Text('暗黑模式'),
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: const Icon(Icons.photo_size_select_actual_rounded),
                  title: const Text('图片地址'),
                  subtitle: Text(global.imagePath ?? '未选择'),
                  trailing: ElevatedButton(
                    child: const Text('地图'),
                    onPressed: () => global.setImagePath(),
                  ),
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: const Icon(Icons.file_download),
                  title: const Text('生成地址'),
                  subtitle: Text(global.pathFilePath),
                  trailing: IntegratePlatform.isWeb
                      ? null
                      : ElevatedButton(
                          child: const Text('选择'),
                          onPressed: () => global.setPathFilePath(),
                        ),
                ),
                const SizedBox(height: 20),
                TextField(
                  decoration: InputDecoration(
                    label: const Text('图像比例'),
                    helperText:
                        '高/宽 ${global.canvasSize.height / global.canvasSize.width}',
                    border: const OutlineInputBorder(),
                  ),
                  onSubmitted: (value) {
                    if (value.isEmpty) {
                      return;
                    }
                    double v = value.toDouble();
                    if (v < 0.2) {
                      v = 0.2;
                    } else if (v > 1) {
                      v = 1;
                    }
                    global.canvasSize = Size(500, 500 * v);
                  },
                  inputFormatters: [
                    XNumberTextInputFormatter(isAllowNegative: false)
                  ],
                ),
                const SizedBox(height: 20),
                TextField(
                  decoration: InputDecoration(
                    label: const Text('实际宽长(mm)'),
                    helperText: '${global.resolution * 500} mm',
                    border: const OutlineInputBorder(),
                  ),
                  onSubmitted: (value) {
                    if (value.isEmpty) {
                      return;
                    }
                    final width = value.toDouble();
                    global.resolution = width / 500;
                  },
                  inputFormatters: [
                    XNumberTextInputFormatter(isAllowNegative: false)
                  ],
                ),
                const SizedBox(height: 20),
                TextField(
                  decoration: InputDecoration(
                    label: const Text('轮距'),
                    helperText: '${global.robotWidth}',
                    border: const OutlineInputBorder(),
                  ),
                  controller: global.robotWidthController,
                  inputFormatters: [XNumberTextInputFormatter()],
                ),
              ],
            ),
          ),
          global.settingSave
              ? Card(
                  child: ListTile(
                    leading: const Icon(Icons.check_circle),
                    title: const Text('Success'),
                    subtitle: const SizedBox(
                        width: double.infinity, child: Text('成功保存配置')),
                    trailing: IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        global.settingSave = false;
                      },
                    ),
                  ),
                )
              : Container(),
        ],
      ),
    );
  }
}
