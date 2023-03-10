import 'package:flutter/material.dart';
import 'package:speed/utils/platform/platform.dart';

class Info {
  String info = '''使用前请先点击设置 
    =>设置地图有关参数(参数可保存) 

*** 输入框输入后需按回车生效 ***
        
按钮作用:
导入, 导出 => 路径点, 速度点设置
补全 => 添加首尾速度点
生成 => 生成并导出规划点
报告 => 查看规划点变化曲线
模拟 => 模拟机器运动

*底部中心为原点

1.左键点击选择/拖动路径点或控制点
  *被选中路径点将会变红
  *被选中控制点将会变绿
  *偏透明绿色点为辅助点
  
2.右键点击选择速度点
  *添加速度点请先左键点击选中对应路径点
  *默认生成文件目录: .\\path\\''';
  String version = Version.instance.now;

  Future<void> showInfo(BuildContext context) async {
    return await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('使用说明'),
        content: SizedBox(
          width: 300,
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  children: [
                    SelectableText(info),
                  ],
                ),
              ),
              Text('Version: $version'),
              const SizedBox(height: 10),
              const Text('开发者: 易鹏飞, 李思宇'),
            ],
          ),
        ),
        actions: [
          Container(
            constraints: BoxConstraints.tight(const Size(160, 50)),
            child: Version.instance.update
                ? ListTile(
                    title: Text("新版本: ${Version.instance.newer}"),
                    trailing: const Icon(
                      Icons.new_releases,
                      color: Colors.redAccent,
                    ),
                    onTap: () => Version.instance.showUpdate(context),
                  )
                : null,
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: 100,
            child: ListTile(
              title: const Text("更多信息"),
              onTap: () => showAboutDialog(
                  context: context,
                  applicationName: "路径规划",
                  applicationVersion: Version.instance.now,
                  applicationIcon: const FlutterLogo(),
                  applicationLegalese: "开发者: 易鹏飞, 李思宇"),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
