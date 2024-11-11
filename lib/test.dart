import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class Test extends StatefulWidget {
  const Test({super.key});

  @override
  State<Test> createState() => _TestState();
}

class _TestState extends State<Test> {
  @override
  Widget build(BuildContext context) {
    final List<ChartData> chartData = [
      ChartData(2010, 35),
      ChartData(2011, 28),
      ChartData(2012, 34),
      ChartData(2013, 32),
      ChartData(2014, 40)
    ];

    return Scaffold(
        body: Column(
          children: [
            SizedBox(height: 50,),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: SizedBox(
                height: 400,
                child: Center(
                    child: Container(
                        child: SfCartesianChart(

                            series: <CartesianSeries>[
                              // Renders line chart
                              LineSeries<ChartData, int>(dataLabelSettings: DataLabelSettings(isVisible: true),
                                  dataSource: chartData,
                                  xValueMapper: (ChartData data, _) => data.x,
                                  yValueMapper: (ChartData data, _) => data.y
                              )
                            ]
                        )
                    )
                ),
              ),
            ),
          ],
        )
    );
  }


}

class ChartData {
  ChartData(this.x, this.y);
  final int x;
  final double y;
}
