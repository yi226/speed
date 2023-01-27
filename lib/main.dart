import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:speed/utils/platform/platform.dart';
import 'package:speed/widgets/control.dart';
import 'package:speed/widgets/curve.dart';
import 'package:speed/widgets/setting.dart';
import 'package:window_manager/window_manager.dart';

import 'global.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (IntegratePlatform.isDesktop) {
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
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(useMaterial3: true),
          darkTheme: ThemeData.dark(useMaterial3: true),
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
    return Scaffold(
      appBar: AppBar(
        leading: const Icon(Icons.local_florist),
        actions: [
          const SizedBox(width: 50),
          TextButton(
              child: const Text("导出(O)"), onPressed: () => global.exportPath()),
          TextButton(
              child: const Text("导入(I)"), onPressed: () => global.importPath()),
          TextButton(
              child: const Text("设置(S)"),
              onPressed: () async {
                await showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('设置'),
                    content: const SettingWidget(),
                    actions: [
                      TextButton(
                        child: const Text('保存配置'),
                        onPressed: () async {
                          await global.save('Settings', global.saveString);
                          global.settingSave = true;
                        },
                      ),
                      ElevatedButton(
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
          TextButton(
              child: const Text("补全(A)"),
              onPressed: () => global.completeSPoint()),
          TextButton(
              child: const Text("生成(C)"), onPressed: () => global.createPath()),
          TextButton(
              child: const Text("报告(R)"),
              onPressed: () => global.showSpeedCurve()),
          TextButton(
              child: const Text("模拟(E)"),
              onPressed: () => global.showEmulate()),
          const Spacer(),
          DropdownButton(
            value: global.cType.name,
            items: CType.values
                .map((e) => DropdownMenuItem(
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
        ],
      ),
      body: Row(
        children: [
          Drawer(
            elevation: 0,
            width: 50,
            child: Column(
              children: [
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.info),
                  onPressed: () async {
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
                const SizedBox(height: 10),
              ],
            ),
          ),
          ...global.cType == CType.path
              ? [const CurveWidget(), const Expanded(child: ControlWidget())]
              : [const SCurveWidget(), const Expanded(child: SControlWidget())],
        ],
      ),
    );
  }
}
