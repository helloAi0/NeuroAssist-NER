import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../core/theme/app_theme.dart';
import '../../data/sync_repository.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  int _pendingEvents = 0;
  List<dynamic> _cloudTrends = [];
  bool _isLoading = true;
  final String _baseUrl = 'https://neuroassist-ner-1.onrender.com'; // Hardcoded for stage demo reliability

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    _pendingEvents = await SyncRepository().getPendingEventCount();
    
    try {
      final response = await http.get(Uri.parse('$_baseUrl/api/analytics/trends')).timeout(const Duration(seconds: 3));
      if (response.statusCode == 200) {
        _cloudTrends = jsonDecode(response.body)['trends'] ?? [];
      }
    } catch (_) {
      // Ensure it doesn't crash if backend is down
    }
    
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _forceSync() async {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Syncing data to cloud...')));
    await SyncRepository().pushToCloud();
    await _loadData();
  }

  Future<void> _fetchAIInsights() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final response = await http.get(Uri.parse('$_baseUrl/api/ai/insights')).timeout(const Duration(seconds: 10));
      Navigator.pop(context); // Close loading dialog

      if (response.statusCode == 200) {
        final insight = jsonDecode(response.body)['insight'];
        _showInsightDialog(insight);
      } else {
        _showInsightDialog("Unable to analyze data at this time.");
      }
    } catch (e) {
      Navigator.pop(context);
      _showInsightDialog("Connection error. Please check your backend.");
    }
  }

  void _showInsightDialog(String content) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome, color: Colors.deepPurple.shade400),
                const SizedBox(width: 12),
                const Text('Deep AI Insights', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              ],
            ),
            const Divider(height: 30),
            Text(content, style: const TextStyle(fontSize: 16, height: 1.5)),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close Report'),
              ),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Caregiver Analytics'),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData)],
      ),
      backgroundColor: Colors.grey.shade100,
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _loadData,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // 1. SYNC STATUS CARD
                Card(
                  elevation: 2,
                  color: _pendingEvents > 0 ? Colors.orange.shade50 : Colors.green.shade50,
                  child: ListTile(
                    leading: Icon(
                      _pendingEvents > 0 ? Icons.cloud_upload : Icons.cloud_done,
                      color: _pendingEvents > 0 ? Colors.orange.shade800 : Colors.green.shade800,
                      size: 36,
                    ),
                    title: const Text('Connectivity Status', style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('$_pendingEvents records waiting to sync'),
                    trailing: _pendingEvents > 0 
                      ? ElevatedButton(onPressed: _forceSync, child: const Text('Sync Now'))
                      : const Icon(Icons.check_circle, color: Colors.green),
                  ),
                ),
                const SizedBox(height: 20),

                // 2. AI INSIGHTS BUTTON
                InkWell(
                  onTap: _fetchAIInsights,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [Colors.deepPurple.shade800, Colors.deepPurple.shade500]),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.auto_awesome, color: Colors.white, size: 32),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text('Generate Deep Analysis', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                              SizedBox(height: 4),
                              Text('Tap to run predictive models on historical data.', style: TextStyle(color: Colors.white70, fontSize: 13)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                // 3. PERFORMANCE TRENDS
                const Text('Daily Performance Trends', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                
                if (_cloudTrends.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(30.0),
                    child: Center(
                      child: Text('No cloud data found. Go to Games, tap "Bulk Generate History", and Sync!', 
                      textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 16)),
                    ),
                  )
                else
                  ..._cloudTrends.reversed.map((trend) {
                    final double avgScore = (trend['avg_score'] as num).toDouble();
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 1,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(trend['date'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                Text('${trend['total_sessions']} sessions', style: TextStyle(color: Colors.grey.shade600)),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                const Text('Avg Score: '),
                                Text('${avgScore.toStringAsFixed(1)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: avgScore / 100,
                                      minHeight: 8,
                                      backgroundColor: Colors.grey.shade200,
                                      color: avgScore > 70 ? Colors.green : (avgScore > 40 ? Colors.orange : Colors.red),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text('Avg Errors: ${trend['avg_errors']}', style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
              ],
            ),
          ),
    );
  }
}