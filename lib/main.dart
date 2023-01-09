import 'dart:io';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:speed/widgets/control.dart';
import 'package:speed/widgets/curve.dart';
import 'package:speed/widgets/info.dart';
import 'package:speed/widgets/setting.dart';
import 'package:window_manager/window_manager.dart';

import 'global.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    await windowManager.ensureInitialized();

    WindowOptions windowOptions = const WindowOptions(
      minimumSize: Size(1000, 650),
    );
    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  } else {
    // 设置横屏
    await SystemChrome.setPreferredOrientations(
        [DeviceOrientation.landscapeRight, DeviceOrientation.landscapeLeft]);
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => Global(),
      builder: (context, child) {
        final mode = context.select<Global, ThemeMode>((value) => value.mode);
        return FluentApp(
          debugShowCheckedModeBanner: false,
          darkTheme: ThemeData.dark(),
          themeMode: mode,
          title: 'Path Planner',
          initialRoute: '/',
          routes: {'/': (context) => const MainPage()},
        );
      },
    );
  }
}

class MainPage extends StatelessWidget {
  const MainPage({super.key});

  @override
  Widget build(BuildContext context) {
    final global = context.watch<Global>();
    global.context = context;
    return NavigationView(
      appBar: const NavigationAppBar(
        leading: Icon(FluentIcons.a_a_d_logo),
        actions: CommandsBar(),
      ),
      pane: NavigationPane(
        selected: 0,
        displayMode: PaneDisplayMode.compact,
        menuButton: Container(),
        items: [
          PaneItem(
              icon: const Icon(FluentIcons.app_icon_default_edit),
              title: const Text('Speed Plan'),
              body: Row(
                children: global.cType == CType.path
                    ? [
                        const CurveWidget(),
                        const Expanded(child: ControlWidget())
                      ]
                    : [
                        const SCurveWidget(),
                        const Expanded(child: SControlWidget())
                      ],
              )),
        ],
        footerItems: [
          PaneItemSeparator(),
          PaneItem(
            icon: const Icon(FluentIcons.info),
            title: const Text('Info'),
            body: Container(),
            onTap: () async {
              Info info = Info(appDocDirPath: global.appDocDirPath);
              bool? result = await info.showInfo(context);
              while (result == true) {
                await Future.delayed(const Duration(seconds: 1));
                info = Info(appDocDirPath: global.appDocDirPath);
                // ignore: use_build_context_synchronously
                result = await info.showInfo(context);
              }
            },
          ),
        ],
      ),
    );
  }
}

class CommandsBar extends StatelessWidget {
  const CommandsBar({super.key});

  @override
  Widget build(BuildContext context) {
    final global = context.watch<Global>();
    return CommandBarCard(
      margin: const EdgeInsets.only(left: 50),
      child: CommandBar(
        primaryItems: [
          CommandBarButton(
              label: const Text("导出(O)"), onPressed: () => global.exportPath()),
          CommandBarButton(
              label: const Text("导入(I)"), onPressed: () => global.importPath()),
          CommandBarButton(
              label: const Text("地图(M)"),
              onPressed: () => global.setImagePath()),
          CommandBarButton(
              label: const Text("设置(S)"),
              onPressed: () async {
                await showDialog(
                  context: context,
                  builder: (context) => ContentDialog(
                    title: const Text('设置'),
                    content: const SettingWidget(),
                    actions: [
                      Button(
                        child: const Text('保存配置'),
                        onPressed: () async {
                          await global.save('Settings', global.saveString);
                          global.settingSave = true;
                        },
                      ),
                      FilledButton(
                        child: const Text('OK'),
                        onPressed: () {
                          global.settingSave = false;
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  ),
                );
              }),
          CommandBarButton(
              label: const Text("补全(A)"),
              onPressed: () => global.completeSPoint()),
          CommandBarButton(
              label: const Text("生成(C)"), onPressed: () => global.createPath()),
          CommandBarButton(
              label: const Text("报告(R)"),
              onPressed: () => global.showSpeedCurve()),
          CommandBarButton(
              label: const Text("模拟(E)"),
              onPressed: () => global.showEmulate()),
          const CommandBarSeparator(),
          CommandBarButton(
              label: ComboBox(
                value: global.cType.name,
                items: CType.values
                    .map((e) => ComboBoxItem(
                          value: e.name,
                          child: Text(e.name),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (global.image == null) {
                    global.showError('请先选择地图');
                    return;
                  }
                  if (!global.checkControl()) {
                    global.showError('控制点长度不能为0');
                    return;
                  }
                  if (value != null) {
                    global.cType = CType.parse(value);
                  }
                },
              ),
              onPressed: () {}),
        ],
      ),
    );
  }
}
