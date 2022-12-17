import 'dart:io';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:provider/provider.dart';
import 'package:speed/widgets/control.dart';
import 'package:speed/widgets/curve.dart';
import 'package:speed/widgets/setting.dart';
import 'package:window_manager/window_manager.dart';

import 'global.dart';

void main() async {
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    WidgetsFlutterBinding.ensureInitialized();
    await windowManager.ensureInitialized();

    WindowOptions windowOptions = const WindowOptions(
      minimumSize: Size(1000, 600),
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

  // This widget is the root of your application.
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
  void showContentDialog(BuildContext context) async {
    await showDialog<String>(
      context: context,
      builder: (context) => ContentDialog(
        title: const Text('Info'),
        content: const Text('Info'),
        actions: [
          FilledButton(
            child: const Text('确定'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

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
                              await global.save('Settings',
                                  '${global.mode == ThemeMode.dark}@${global.imagePath}@${global.canvasSize.height}@${global.resolution}');
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
                  label: const Text("测试(T)"),
                  onPressed: () => global.showError('Test')),
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
              icon: const Icon(FluentIcons.file_image),
              title: const Text('Speed Plan'),
              body: Row(
                children: const [
                  CurveWidget(),
                  Expanded(child: ControlWidget())
                ],
              )),
        ],
        footerItems: [
          PaneItemSeparator(),
          PaneItem(
            icon: const Icon(FluentIcons.info),
            title: const Text('Info'),
            body: Container(),
            onTap: () => showContentDialog(context),
          ),
        ],
      ),
    );
  }
}