import 'dart:io';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:provider/provider.dart';
import 'package:speed/widgets/control.dart';
import 'package:speed/widgets/curve.dart';
import 'package:speed/widgets/info.dart';
import 'package:speed/widgets/setting.dart';
import 'package:window_manager/window_manager.dart';

import 'global.dart';

void main() async {
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    WidgetsFlutterBinding.ensureInitialized();
    await windowManager.ensureInitialized();

    WindowOptions windowOptions = const WindowOptions(
      minimumSize: Size(1000, 650),
    );
    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
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
          title: 'Code',
          initialRoute: '/',
          routes: {'/': ((context) => const MainPage())},
        );
      },
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  @override
  Widget build(BuildContext context) {
    final global = context.watch<Global>();
    global.context = context;
    return NavigationView(
      appBar: NavigationAppBar(
        leading: const Icon(FluentIcons.a_a_d_logo),
        actions: CommandBarCard(
          margin: const EdgeInsets.only(left: 50),
          child: CommandBar(
            primaryItems: [
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
                  label: const Text("生成(C)"),
                  onPressed: () => global.createPath()),
              CommandBarButton(
                  label: const Text("报告(R)"),
                  onPressed: () => global.showSpeedCurve()),
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
                      if (value != null) global.cType = CType.parse(value);
                    },
                  ),
                  onPressed: () {}),
            ],
          ),
        ),
      ),
      pane: NavigationPane(
        selected: 0,
        displayMode: PaneDisplayMode.compact,
        indicator: const StickyNavigationIndicator(
          duration: Duration(milliseconds: 200),
        ),
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
            onTap: () {
              Info info = Info();
              info.showInfo(context);
            },
          ),
        ],
      ),
    );
  }
}
