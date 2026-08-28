import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../core/theme/app_theme.dart';

class CaregiverDashboardScreen extends StatefulWidget {
  const CaregiverDashboardScreen({super.key});

  @override
  State<CaregiverDashboardScreen> createState() => _CaregiverDashboardScreenState();
}

class _CaregiverDashboardScreenState extends State<CaregiverDashboardScreen> {
  List<dynamic> _events = [];
  String _aiSummary = '';
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Fetch both events and the AI summary simultaneously
      final eventsResponse = await http.get(Uri.parse('http://localhost:8000/api/events'));
      final summaryResponse = await http.get(Uri.parse('http://localhost:8000/api/summary'));
      
      if (eventsResponse.statusCode == 200) {
        setState(() {
          _events = jsonDecode(eventsResponse.body);
          _events.sort((a, b) => b['id'].compareTo(a['id']));
          
          if (summaryResponse.statusCode == 200) {
            _aiSummary = jsonDecode(summaryResponse.body)['summary'] ?? '';
          }
          
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Server error: ${eventsResponse.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to connect. Is the FastAPI backend running?';
        _isLoading = false;
      });
    }
  }

  IconData _getEventIcon(String type) {
    switch (type) {
      case 'GAME_COMPLETION':
        return Icons.extension;
      case 'REMINDER_TRIGGERED':
        return Icons.alarm_on;
      case 'VOICE_ASSESSMENT':
        return Icons.mic;
      default:
        return Icons.data_usage;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundGray,
      appBar: AppBar(
        title: const Text('Caregiver Analytics', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.primaryNavy,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Data',
            onPressed: _fetchDashboardData,
          ),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryNavy))
        : _errorMessage.isNotEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text(
                  _errorMessage, 
                  style: const TextStyle(color: Colors.red, fontSize: 16, fontWeight: FontWeight.bold), 
                  textAlign: TextAlign.center
                ),
              ),
            )
          : CustomScrollView(
              slivers: [
                if (_aiSummary.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppTheme.primaryNavy, AppTheme.primaryNavy.withOpacity(0.8)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.auto_awesome, color: AppTheme.accentAmber),
                                const SizedBox(width: 8),
                                Text(
                                  'AI Health Summary',
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _aiSummary,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                if (_events.isEmpty)
                  const SliverFillRemaining(
                    child: Center(
                      child: Text(
                        'No synced data found.\nPlay a game and sync to see data here.', 
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final event = _events[index];
                          String payloadDisplay = event['payload'] ?? '';
                          payloadDisplay = payloadDisplay.replaceAll(RegExp(r'[{}"\\]'), '').replaceAll(',', ' • ');

                          return Card(
                            elevation: 0,
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: Colors.grey.withOpacity(0.2)),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              leading: CircleAvatar(
                                backgroundColor: AppTheme.softTeal.withOpacity(0.2),
                                radius: 24,
                                child: Icon(
                                  _getEventIcon(event['event_type']),
                                  color: AppTheme.softTeal,
                                  size: 28,
                                ),
                              ),
                              title: Text(
                                (event['event_type'] ?? 'Unknown Event').replaceAll('_', ' '),
                                style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryNavy),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(payloadDisplay, style: const TextStyle(fontSize: 14)),
                              ),
                            ),
                          );
                        },
                        childCount: _events.length,
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}