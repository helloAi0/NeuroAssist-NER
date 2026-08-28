import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/api_service.dart'; // Imports TrendData class

class CognitiveTrendsChart extends StatelessWidget {
  final List<TrendData> trends;

  const CognitiveTrendsChart({Key? key, required this.trends}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (trends.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text("No trend data available yet."),
        ),
      );
    }

    return Container(
      height: 250,
      padding: const EdgeInsets.all(16),
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: true),
          titlesData: const FlTitlesData(
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          lineBarsData: [
            // Score Line (Blue)
            LineChartBarData(
              spots: trends.asMap().entries.map((e) {
                return FlSpot(e.key.toDouble(), e.value.avgScore);
              }).toList(),
              isCurved: true,
              color: Colors.blueAccent,
              barWidth: 3,
              dotData: const FlDotData(show: true),
            ),
            // Errors Line (Red)
            LineChartBarData(
              spots: trends.asMap().entries.map((e) {
                return FlSpot(e.key.toDouble(), e.value.avgErrors);
              }).toList(),
              isCurved: true,
              color: Colors.redAccent,
              barWidth: 3,
              dotData: const FlDotData(show: true),
            ),
          ],
        ),
      ),
    );
  }
}