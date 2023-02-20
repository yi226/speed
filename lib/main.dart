import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:speed/utils/platform/platform.dart';
import 'package:speed/widgets/control.dart';
import 'package:speed/widgets/curve.dart';

import 'global.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Global.init();
  if (IntegratePlatform.isMobile) {
    // 设置横屏
    await SystemChrome.setPreferredOrientations(
        [DeviceOrientation.landscapeRight, DeviceOrientation.landscapeLeft]);
    // 全面屏
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
        overlays: []);
  }
  runApp(const MyApp());

  if (IntegratePlatform.isDesktop) {
    doWhenWindowReady(() {
      const initialSize = Size(1000, 600);
      appWindow.minSize = initialSize;
      appWindow.size = initialSize;
      appWindow.alignment = Alignment.center;
      appWindow.show();
    });
  }
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
          theme: ThemeData(
            useMaterial3: true,
            colorSchemeSeed: Colors.blue,
            fontFamily: IntegratePlatform.isDesktop ? "MiSans" : null,
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            useMaterial3: true,
            fontFamily: IntegratePlatform.isDesktop ? "MiSans" : null,
          ),
          themeMode: mode,
          title: 'speed',
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
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(46.0),
        child: Row(children: [
          IntegratePlatform.isDesktop
              ? WindowTitleBarBox(
                  child: MoveWindow(
                    child: const Padding(
                      padding: EdgeInsets.only(left: 9, right: 9),
                      child: FlutterLogo(),
                    ),
                  ),
                )
              : const Padding(
                  padding: EdgeInsets.only(left: 9, right: 9),
                  child: FlutterLogo(),
                ),
          TextButton(
              child: const Text("导出(O)"), onPressed: () => global.exportPath()),
          TextButton(
              child: const Text("导入(I)"), onPressed: () => global.importPath()),
          TextButton(
              child: const Text("设置(S)"),
              onPressed: () => global.showSetting()),
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
          const SizedBox(width: 20),
          DropdownButtonHideUnderline(
            child: DropdownButton(
              focusColor: Theme.of(context).colorScheme.surface,
              isDense: true,
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
          ),
          Expanded(
            child: Column(
              children: [
                if (IntegratePlatform.isDesktop)
                  WindowTitleBarBox(
                    child: Row(
                      children: [
                        Expanded(child: MoveWindow()),
                        const WindowButtons(),
                      ],
                    ),
                  ),
              ],
            ),
          )
        ]),
      ),
      body: Row(
        children: [
          Drawer(
            elevation: 0,
            width: 50,
            child: Column(
              children: [
                const Spacer(),
                RotatedBox(
                  quarterTurns: 3,
                  child: Slider(
                    overlayColor: const MaterialStatePropertyAll(
                        Color.fromARGB(0, 0, 0, 0)),
                    value: global.canvasScale,
                    onChanged: (v) => global.canvasScale = v,
                    min: 0.5,
                    max: 2.0,
                  ),
                ),
                Text("倍数\n${global.canvasScale.toStringAsFixed(2)}"),
                InkWell(
                    onTap: () => global.canvasScale = 1,
                    child: const Card(
                      child: Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Icon(Icons.crop_free, size: 20),
                      ),
                    )),
                const Spacer(),
                IconButton(
                  icon: Icon(
                    Icons.info,
                    color: Theme.of(context).colorScheme.primary,
                  ),
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

class WindowButtons extends StatelessWidget {
  const WindowButtons({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final buttonColors = WindowButtonColors(
        iconNormal: Theme.of(context).iconTheme.color,
        mouseOver: Colors.grey.shade300,
        mouseDown: Colors.grey.shade400,
        iconMouseOver: Colors.black,
        iconMouseDown: Colors.black);

    final closeButtonColors = WindowButtonColors(
      mouseOver: const Color(0xFFD32F2F),
      mouseDown: const Color(0xFFB71C1C),
      iconNormal: Theme.of(context).iconTheme.color,
      iconMouseOver: Colors.white,
    );
    return Row(
      children: [
        MinimizeWindowButton(colors: buttonColors),
        MaximizeWindowButton(colors: buttonColors),
        CloseWindowButton(colors: closeButtonColors),
      ],
    );
  }
}
