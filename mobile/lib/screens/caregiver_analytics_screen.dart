import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'dart:math';

import '../core/theme/app_theme.dart';

class CaregiverAnalyticsScreen extends StatefulWidget {
  const CaregiverAnalyticsScreen({super.key});

  @override
  State<CaregiverAnalyticsScreen> createState() => _CaregiverAnalyticsScreenState();
}

class _CaregiverAnalyticsScreenState extends State<CaregiverAnalyticsScreen> {
  bool _isLoading = true;
  String _selectedFilter = 'All Modules';

  final List<String> _gameFilters = [
    'All Modules',
    'Memory Match',
    'Reflex Tap',
    'Grid Matrix',
  ];

  @override
  void initState() {
    super.initState();
    // Simulate diagnostic loading
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) setState(() => _isLoading = false);
    });
  }

  void _onFilterSelected(String filter) {
    setState(() {
      _selectedFilter = filter;
    });
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Advanced Cognitive Analytics'),
        elevation: 0,
        backgroundColor: AppTheme.primaryNavy,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? _buildLoadingState(textTheme)
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDeepAnalysisTrigger(),
                  const SizedBox(height: 16),

                  // 1. FILTER BAR (Select All vs Individual Games)
                  Text(
                    'Select Study Target',
                    style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  _buildFilterBar(),
                  const SizedBox(height: 20),

                  // 2. DYNAMIC METRIC CARDS
                  _buildDynamicMetricCards(),
                  const SizedBox(height: 24),

                  // 3. DYNAMIC TREND CHART (Memory & Attention / Accuracy)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '$_selectedFilter Trends',
                        style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Chip(
                        label: Text(_selectedFilter, style: const TextStyle(fontSize: 12, color: Colors.white)),
                        backgroundColor: AppTheme.primaryNavy,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildDynamicTrendChart(),
                  const SizedBox(height: 28),

                  // 4. MOTOR REFLEX & RESPONSE LATENCY CHART
                  Text(
                    'Motor Latency & Reaction Speeds',
                    style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _buildDynamicReactionBarChart(),
                  const SizedBox(height: 28),

                  // 5. AI DIAGNOSTIC INSIGHTS FOR SELECTED GAME
                  Text(
                    'AI Diagnostic Insights',
                    style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _buildDynamicAIInsights(),
                  const SizedBox(height: 28),

                  // 6. RAW OFFLINE SESSION LOGS (Clickable to inspect individual game)
                  Text(
                    'Inspect Stored Offline Game Data',
                    style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Tap any session below to filter deep analytical metrics to that module.',
                    style: textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 12),
                  _buildOfflineSessionLogs(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  // --- FILTER BAR WIDGET ---
  Widget _buildFilterBar() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _gameFilters.map((filter) {
          final isSelected = _selectedFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: FilterChip(
              selected: isSelected,
              label: Text(filter),
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              selectedColor: AppTheme.primaryNavy,
              backgroundColor: Colors.white,
              elevation: isSelected ? 3 : 1,
              checkmarkColor: Colors.white,
              onSelected: (_) => _onFilterSelected(filter),
            ),
          );
        }).toList(),
      ),
    );
  }

  // --- DYNAMIC METRIC CARDS ---
  Widget _buildDynamicMetricCards() {
    String scoreLabel = 'Cognitive Index';
    String scoreVal = '82%';
    String scoreDiff = '+4%';

    String speedLabel = 'Avg Reaction';
    String speedVal = '312ms';
    String speedDiff = '-15ms';

    if (_selectedFilter == 'Memory Match') {
      scoreLabel = 'Memory Recall';
      scoreVal = '88%';
      scoreDiff = '+6%';
      speedLabel = 'Avg Flip Speed';
      speedVal = '1.4s';
      speedDiff = '-0.2s';
    } else if (_selectedFilter == 'Reflex Tap') {
      scoreLabel = 'Tap Accuracy';
      scoreVal = '94%';
      scoreDiff = '+2%';
      speedLabel = 'Stop Reaction';
      speedVal = '245ms';
      speedDiff = '-32ms';
    } else if (_selectedFilter == 'Grid Matrix') {
      scoreLabel = 'Spatial Score';
      scoreVal = '76%';
      scoreDiff = '+8%';
      speedLabel = 'Solve Speed';
      speedVal = '4.8s';
      speedDiff = '-0.5s';
    }

    return Row(
      children: [
        Expanded(child: _buildMetricCard(scoreLabel, scoreVal, scoreDiff, true)),
        const SizedBox(width: 12),
        Expanded(child: _buildMetricCard(speedLabel, speedVal, speedDiff, true)),
      ],
    );
  }

  Widget _buildMetricCard(String title, String value, String change, bool isPositive) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppTheme.primaryNavy)),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                  size: 14,
                  color: isPositive ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 4),
                Text(change, style: TextStyle(color: isPositive ? Colors.green : Colors.red, fontWeight: FontWeight.bold, fontSize: 12)),
                Text(' vs last session', style: TextStyle(color: Colors.grey[500], fontSize: 11)),
              ],
            )
          ],
        ),
      ),
    );
  }

  // --- DYNAMIC LINE CHART ---
  Widget _buildDynamicTrendChart() {
    List<FlSpot> spots;

    if (_selectedFilter == 'Memory Match') {
      spots = const [FlSpot(0, 60), FlSpot(1, 65), FlSpot(2, 70), FlSpot(3, 75), FlSpot(4, 82), FlSpot(5, 88)];
    } else if (_selectedFilter == 'Reflex Tap') {
      spots = const [FlSpot(0, 75), FlSpot(1, 78), FlSpot(2, 85), FlSpot(3, 82), FlSpot(4, 90), FlSpot(5, 94)];
    } else if (_selectedFilter == 'Grid Matrix') {
      spots = const [FlSpot(0, 50), FlSpot(1, 55), FlSpot(2, 62), FlSpot(3, 68), FlSpot(4, 70), FlSpot(5, 76)];
    } else {
      // All Combined
      spots = const [FlSpot(0, 65), FlSpot(1, 68), FlSpot(2, 72), FlSpot(3, 75), FlSpot(4, 80), FlSpot(5, 84)];
    }

    return AspectRatio(
      aspectRatio: 1.7,
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.only(right: 18, left: 12, top: 24, bottom: 12),
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: 20,
                getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey[200], strokeWidth: 1),
              ),
              titlesData: FlTitlesData(
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 1,
                    getTitlesWidget: (value, meta) {
                      final date = DateTime.now().subtract(Duration(days: 5 - value.toInt()));
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(DateFormat('MMM d').format(date), style: TextStyle(color: Colors.grey[600], fontSize: 11)),
                      );
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 20,
                    getTitlesWidget: (value, meta) => Text('${value.toInt()}%', style: TextStyle(color: Colors.grey[600], fontSize: 11)),
                    reservedSize: 36,
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              minX: 0,
              maxX: 5,
              minY: 0,
              maxY: 100,
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  color: AppTheme.primaryNavy,
                  barWidth: 4,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: true),
                  belowBarData: BarAreaData(
                    show: true,
                    color: AppTheme.primaryNavy.withOpacity(0.12),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- DYNAMIC BAR CHART ---
  Widget _buildDynamicReactionBarChart() {
    List<double> barValues;
    if (_selectedFilter == 'Memory Match') {
      barValues = [1600, 1500, 1450, 1400, 1350];
    } else if (_selectedFilter == 'Reflex Tap') {
      barValues = [340, 310, 290, 260, 245];
    } else if (_selectedFilter == 'Grid Matrix') {
      barValues = [5500, 5200, 4900, 4800, 4600];
    } else {
      barValues = [450, 420, 380, 340, 312];
    }

    final maxVal = barValues.reduce(max);

    return AspectRatio(
      aspectRatio: 1.7,
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxVal * 1.25,
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      const days = ['Day 1', 'Day 2', 'Day 3', 'Day 4', 'Day 5'];
                      if (value.toInt() < days.length) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(days[value.toInt()], style: TextStyle(color: Colors.grey[600], fontSize: 11)),
                        );
                      }
                      return const Text('');
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 42,
                    getTitlesWidget: (value, meta) => Text(
                      _selectedFilter == 'Grid Matrix' || _selectedFilter == 'Memory Match'
                          ? '${(value / 1000).toStringAsFixed(1)}s'
                          : '${value.toInt()}ms',
                      style: TextStyle(color: Colors.grey[600], fontSize: 10),
                    ),
                  ),
                ),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              gridData: FlGridData(show: true, drawVerticalLine: false),
              borderData: FlBorderData(show: false),
              barGroups: List.generate(
                barValues.length,
                (index) => BarChartGroupData(
                  x: index,
                  barRods: [
                    BarChartRodData(
                      toY: barValues[index],
                      color: AppTheme.accentAmber,
                      width: 20,
                      borderRadius: const BorderRadius.only(topLeft: Radius.circular(6), topRight: Radius.circular(6)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- DYNAMIC AI INSIGHTS ---
  Widget _buildDynamicAIInsights() {
    if (_selectedFilter == 'Memory Match') {
      return Column(
        children: [
          _buildInsightTile(
            icon: Icons.extension,
            color: Colors.indigo,
            title: 'Visual Memory Retention High',
            description: 'Matching recall pattern improved by 18%. Minimal hesitation detected on pair selection.',
          ),
        ],
      );
    } else if (_selectedFilter == 'Reflex Tap') {
      return Column(
        children: [
          _buildInsightTile(
            icon: Icons.touch_app,
            color: Colors.green,
            title: 'Motor Reflex Latency Optimal',
            description: 'Red-to-Green Quick Tap reaction timing stopped at 245ms average, beating baseline motor response thresholds.',
          ),
        ],
      );
    } else if (_selectedFilter == 'Grid Matrix') {
      return Column(
        children: [
          _buildInsightTile(
            icon: Icons.grid_on,
            color: Colors.deepPurple,
            title: 'Spatial Working Memory Growth',
            description: 'Spatial grid retention reached Level 4 complexity with steady time completion rates.',
          ),
        ],
      );
    }

    return Column(
      children: [
        _buildInsightTile(
          icon: Icons.trending_up,
          color: AppTheme.successGreen,
          title: 'Cross-Module Cognitive Synergy',
          description: 'Overall memory and motor responses demonstrate consistent stabilization across all 3 manual cognitive games.',
        ),
        const SizedBox(height: 10),
        _buildInsightTile(
          icon: Icons.schedule,
          color: AppTheme.accentAmber,
          title: 'Peak Performance Time Window',
          description: 'Reflex Tap & Memory Match scores are highest when completed between 9:00 AM and 11:30 AM.',
        ),
      ],
    );
  }

  Widget _buildInsightTile({required IconData icon, required Color color, required String title, required String description}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withOpacity(0.4), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.15),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 4),
                  Text(description, style: TextStyle(color: Colors.grey[700], fontSize: 13, height: 1.3)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- RAW OFFLINE SESSION LOGS (Tap to Filter) ---
  Widget _buildOfflineSessionLogs() {
    final sessions = [
      {'game': 'Memory Match', 'detail': 'Score: 85 • Errors: 1', 'time': '10 mins ago', 'icon': Icons.extension},
      {'game': 'Reflex Tap', 'detail': 'Avg Response: 245ms • False Starts: 0', 'time': '1 hour ago', 'icon': Icons.touch_app},
      {'game': 'Grid Matrix', 'detail': 'Level: 4 • Time: 12.5s', 'time': 'Yesterday', 'icon': Icons.grid_on},
    ];

    return Column(
      children: sessions.map((session) {
        final gameName = session['game'] as String;
        final isSelected = _selectedFilter == gameName;

        return Card(
          elevation: isSelected ? 4 : 1,
          margin: const EdgeInsets.only(bottom: 8.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: isSelected ? const BorderSide(color: AppTheme.primaryNavy, width: 2) : BorderSide.none,
          ),
          child: ListTile(
            onTap: () => _onFilterSelected(gameName),
            leading: CircleAvatar(
              backgroundColor: isSelected ? AppTheme.primaryNavy : Colors.grey[200],
              child: Icon(session['icon'] as IconData, color: isSelected ? Colors.white : AppTheme.primaryNavy),
            ),
            title: Text(gameName, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(session['detail'] as String),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(session['time'] as String, style: TextStyle(color: Colors.grey[500], fontSize: 11)),
                const SizedBox(height: 4),
                Icon(isSelected ? Icons.check_circle : Icons.chevron_right, size: 18, color: isSelected ? AppTheme.primaryNavy : Colors.grey),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildLoadingState(TextTheme textTheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: AppTheme.primaryNavy),
          const SizedBox(height: 20),
          Text('Parsing Stored Patient Records...', style: textTheme.titleMedium),
        ],
      ),
    );
  }

  Widget _buildDeepAnalysisTrigger() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Colors.indigo, Colors.deepPurple]),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Row(
          children: [
            const Icon(Icons.auto_awesome, color: Colors.white),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Multi-Module Predictive Model', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  Text('Cross-evaluating motor reflexes & visual working memory.', style: TextStyle(color: Colors.white70, fontSize: 11)),
                ],
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black, elevation: 0),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Re-running diagnostic ML models across offline datasets...')),
                );
              },
              child: const Text('Analyze'),
            )
          ],
        ),
      ),
    );
  }
}