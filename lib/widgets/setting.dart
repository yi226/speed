import 'package:fluent_ui/fluent_ui.dart';
import 'package:provider/provider.dart';
import 'package:speed/global.dart';
import 'package:speed/utils/input_format.dart';

class SettingWidget extends StatelessWidget {
  const SettingWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final global = context.watch<Global>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: ListView(
            children: [
              ToggleSwitch(
                checked: global.mode == ThemeMode.dark,
                onChanged: (value) {
                  global.mode = value ? ThemeMode.dark : ThemeMode.light;
                },
                content: const Text('暗黑模式'),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(FluentIcons.picture),
                title: const Text('图片地址'),
                subtitle: Text(global.imagePath ?? '未选择'),
              ),
              const SizedBox(height: 20),
              TextBox(
                header: '图像比例',
                placeholder:
                    '高/宽 ${global.canvasSize.height / global.canvasSize.width}',
                onSubmitted: (value) {
                  if (value.isEmpty) {
                    return;
                  }
                  global.canvasSize = Size(500, 500 * double.parse(value));
                },
                inputFormatters: [XNumberTextInputFormatter()],
              ),
              const SizedBox(height: 20),
              TextBox(
                header: '实际宽长',
                placeholder: '${global.resolution * 500} mm',
                onSubmitted: (value) {
                  if (value.isEmpty) {
                    return;
                  }
                  final width = double.parse(value);
                  global.resolution = width / 500;
                },
                inputFormatters: [XNumberTextInputFormatter()],
              ),
            ],
          ),
        ),
        global.settingSave
            ? InfoBar(
                title: const Text('Success'),
                content: const SizedBox(
                    width: double.infinity, child: Text('成功保存配置')),
                severity: InfoBarSeverity.success,
                onClose: () {
                  global.settingSave = false;
                },
              )
            : Container(),
      ],
    );
  }
}
