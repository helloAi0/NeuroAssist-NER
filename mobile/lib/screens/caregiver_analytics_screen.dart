import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/cognitive_trends_chart.dart';
import 'caregiver_analytics_screen.dart';

class CaregiverAnalyticsScreen extends StatefulWidget {
  const CaregiverAnalyticsScreen({Key? key}) : super(key: key);

  @override
  State<CaregiverAnalyticsScreen> createState() => _CaregiverAnalyticsScreenState();
}

class _CaregiverAnalyticsScreenState extends State<CaregiverAnalyticsScreen> {
  // Mock data representing the polymorphic game types
  final List<Map<String, dynamic>> recentEvents = [
    {
      "type": "memory_match",
      "payload": {"game": "Memory Match", "score": 85, "errors": 1}
    },
    {
      "type": "reaction_time",
      "payload": {"game": "Reflex Tap", "average_ms": 345, "false_starts": 1}
    },
    {
      "type": "spatial_reasoning",
      "payload": {"game": "Grid Matrix", "level_reached": 4, "time_to_solve_sec": 12.5}
    }
  ];

  // The Phase 4 bottom sheet modal for Gemini Insights
  void _showInsightsModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          height: MediaQuery.of(context).size.height * 0.6,
          child: FutureBuilder<String>(
            future: fetchPredictiveInsights(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text("Analyzing cognitive patterns..."),
                    ],
                  ),
                );
              } else if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.auto_awesome, color: Colors.deepPurple),
                        SizedBox(width: 8),
                        Text(
                          "Deep AI Insights",
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const Divider(height: 32),
                    Text(
                      snapshot.data ?? "No insights available.",
                      style: const TextStyle(fontSize: 16, height: 1.5),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  // The Phase 2 dynamic card builder
  Widget buildEventCard(Map<String, dynamic> event) {
    final String type = event['event_type'] ?? event['type'];
    final Map<String, dynamic> payload = event['payload'];
    final String gameName = payload['game'] ?? 'Unknown Game';

    String statsText = "";
    IconData gameIcon = Icons.extension;

    if (type == 'memory_match') {
      statsText = "Score: ${payload['score']} • Errors: ${payload['errors']}";
      gameIcon = Icons.psychology;
    } else if (type == 'reaction_time') {
      statsText = "Avg Response: ${payload['average_ms']}ms • False Starts: ${payload['false_starts']}";
      gameIcon = Icons.timer;
    } else if (type == 'spatial_reasoning') {
      statsText = "Level: ${payload['level_reached']} • Time: ${payload['time_to_solve_sec']}s";
      gameIcon = Icons.grid_on;
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.indigo.shade50,
          child: Icon(gameIcon, color: Colors.indigo),
        ),
        title: Text(
          gameName.toUpperCase(),
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo),
        ),
        subtitle: Text(statsText),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Caregiver Analytics'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            
            // Phase 4: AI Insights Action Card
            GestureDetector(
              onTap: () => _showInsightsModal(context),
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.deepPurple.shade400, Colors.indigo.shade600],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4))
                  ],
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.auto_awesome, color: Colors.white, size: 28),
                        SizedBox(width: 12),
                        Text(
                          "Generate Deep Analysis",
                          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      "Tap to run predictive models on historical cognitive data.",
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),

            // Phase 1: Performance Trends Chart
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Text("Performance Trends", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            
            FutureBuilder<List<TrendData>>(
              future: fetchAnalyticsTrends(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(height: 250, child: Center(child: CircularProgressIndicator()));
                } else if (snapshot.hasError) {
                  return SizedBox(
                    height: 250, 
                    child: Center(child: Text('Chart Error: ${snapshot.error}'))
                  );
                } else if (snapshot.hasData) {
                  return CognitiveTrendsChart(trends: snapshot.data!);
                }
                return const SizedBox.shrink();
              },
            ),

            const Divider(height: 32),

            // Phase 2: Dynamic Recent Modules
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Text("Recent Modules Completed", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: recentEvents.length,
              itemBuilder: (context, index) {
                return buildEventCard(recentEvents[index]);
              },
            ),
            
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}