import 'package:fl_chart/fl_chart.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:speed/utils/path_planning.dart';

// 曲线类型
enum ChartType {
  v('速度'),
  sita('位姿'),
  w('角速度'),
  lead('超前滞后');

  final String name;
  const ChartType(this.name);

  static ChartType parse(String name) {
    return values.firstWhere(
      (v) => v.name == name,
      orElse: () => ChartType.v,
    );
  }
}

class ChartWidget extends StatelessWidget {
  final List<FlSpot> spots = [];
  ChartWidget(
      {super.key, required List<CAPPoint> points, required ChartType type}) {
    for (var e in points) {
      spots.add(FlSpot(e.t, e.parse(type.name)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return LineChart(
      LineChartData(
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            barWidth: 2,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: false,
            ),
          ),
        ],
        titlesData: FlTitlesData(
          show: true,
          rightTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
            ),
          ),
        ),
      ),
    );
  }
}
