import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:fluent_ui/fluent_ui.dart';

class Info {
  String info = '加载中...';
  int? version;
  Dio dio = Dio(BaseOptions(connectTimeout: 2000));
  String appDocDirPath;

  Info({required this.appDocDirPath});

  Future<Response<dynamic>> downloadInfo() async {
    Response response;

    try {
      response = await dio.download(
        'https://github.com/yi226/speed/releases/download/info/info.json',
        '$appDocDirPath${Platform.pathSeparator}doc${Platform.pathSeparator}info.json',
      );
    } catch (e) {
      response = Response(
          requestOptions: RequestOptions(path: ''), statusMessage: '连接超时');
    }
    return response;
  }

  Future deleteInfo() async {
    File file = File(
        '$appDocDirPath${Platform.pathSeparator}doc${Platform.pathSeparator}info.json');
    if (file.existsSync()) {
      await file.delete();
    }
  }

  Future<String> getInfo() async {
    File file = File(
        '$appDocDirPath${Platform.pathSeparator}doc${Platform.pathSeparator}info.json');
    Response? response;
    if (!file.existsSync()) {
      response = await downloadInfo();
      file = File(
          '$appDocDirPath${Platform.pathSeparator}doc${Platform.pathSeparator}info.json');
    }

    if (file.existsSync()) {
      try {
        String jsonString = await file.readAsString();
        var infoJson = json.decode(jsonString);
        info = infoJson['info'];
        version = infoJson['version'];
      } catch (e) {
        info = '$e\n\n文档有误, 请更新文档\n\n开发者: 易鹏飞, 李思宇';
      }
    } else {
      info = '${response?.statusMessage}\n\n开发者: 易鹏飞, 李思宇';
    }

    return info;
  }

  showInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => ContentDialog(
        title: const Text('Info'),
        content: FutureBuilder(
          future: getInfo(),
          builder: ((context, snapshot) {
            return Column(
              children: [
                Expanded(
                    child: ListView(children: [Text(snapshot.data ?? info)])),
                Text('Version: $version'),
              ],
            );
          }),
        ),
        actions: [
          Button(
            onPressed: () async {
              await deleteInfo();
              // ignore: use_build_context_synchronously
              Navigator.pop(context);
            },
            child: const Text('更新文档'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
