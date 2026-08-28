import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:async';

import 'core/theme/app_theme.dart';
import 'core/ui/cultural_motifs.dart';
import 'data/sync_repository.dart';
import 'features/games/memory_match_game.dart';
import 'data/reminder_repository.dart';
import 'features/reminders/reminders_screen.dart';
import 'features/voice/voice_assessment_screen.dart';
import 'screens/caregiver_analytics_screen.dart'; 

// 1. Change main to async to load the env file before the app starts
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  runApp(const NeuroAssistApp());
}

class NeuroAssistApp extends StatelessWidget {
  const NeuroAssistApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NeuroAssist NER',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.elderlyTheme,
      home: const ElderlyHomeScreen(),
    );
  }
}

class ElderlyHomeScreen extends StatefulWidget {
  const ElderlyHomeScreen({super.key});

  @override
  State<ElderlyHomeScreen> createState() => _ElderlyHomeScreenState();
}

class _ElderlyHomeScreenState extends State<ElderlyHomeScreen> {
  // 2. Add the toggle flag here
  static const bool isDemoMode = true; // Switch to false for actual patient release

  MotifType _selectedMotif = MotifType.assamese;
  final SyncRepository _syncRepo = SyncRepository();
  final ReminderRepository _reminderRepo = ReminderRepository(); 
  
  int _pendingSyncCount = 0;
  Timer? _reminderTimer; 

  @override
  void initState() {
    super.initState();
    _refreshSyncCount();
    _startReminderChecker(); 
  }

  @override
  void dispose() {
    _reminderTimer?.cancel(); 
    super.dispose();
  }

  void _startReminderChecker() {
    _reminderTimer = Timer.periodic(const Duration(seconds: 30), (timer) async {
      final now = DateTime.now();
      final currentDateStr = "${now.year}-${now.month}-${now.day}";
      
      final activeReminders = await _reminderRepo.getActiveReminders();
      
      for (var reminder in activeReminders) {
        if (reminder.hour == now.hour && reminder.minute == now.minute) {
          if (reminder.lastTriggeredDate != currentDateStr) {
            await _reminderRepo.updateLastTriggered(reminder.id, currentDateStr);
            _showReminderAlert(reminder);
          }
        }
      }
    });
  }

  void _showReminderAlert(Reminder reminder) {
    if (!mounted) return;
    
    final eventId = 'alert_${DateTime.now().millisecondsSinceEpoch}';
    _syncRepo.queueEvent(eventId, 'REMINDER_TRIGGERED', '{"task": "${reminder.title}"}');
    _refreshSyncCount();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.accentAmber,
        title: const Icon(Icons.warning_rounded, size: 64, color: Colors.white),
        content: Text(
          "Time to: ${reminder.title}!",
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
            ),
            onPressed: () => Navigator.pop(context),
            child: const Text('I will do it now'),
          ),
        ],
      ),
    );
  }

  Future<void> _refreshSyncCount() async {
    final count = await _syncRepo.getPendingEventCount();
    setState(() {
      _pendingSyncCount = count;
    });
  }

  Future<void> _simulateOfflineGameCompletion() async {
    final eventId = 'evt_${DateTime.now().millisecondsSinceEpoch}';
    final mockPayload = '{"game": "Memory Match", "score": 85, "errors": 1}';
    
    await _syncRepo.queueEvent(eventId, 'GAME_COMPLETION', mockPayload);
    await _refreshSyncCount();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Game data saved offline securely!'),
          backgroundColor: AppTheme.successGreen,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.primaryNavy,
        foregroundColor: Colors.white,
        toolbarHeight: 70,
        title: Text(
          'NeuroAssist NER',
          style: textTheme.titleLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          PopupMenuButton<MotifType>(
            icon: const Icon(Icons.palette, size: 32, color: Colors.white),
            tooltip: 'Select Cultural Theme',
            onSelected: (MotifType motif) {
              setState(() {
                _selectedMotif = motif;
              });
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<MotifType>>[
              const PopupMenuItem<MotifType>(
                value: MotifType.assamese,
                child: Text('Assamese Gamosa Motif', style: TextStyle(fontSize: 18)),
              ),
              const PopupMenuItem<MotifType>(
                value: MotifType.naga,
                child: Text('Naga Chevron Motif', style: TextStyle(fontSize: 18)),
              ),
              const PopupMenuItem<MotifType>(
                value: MotifType.mizo,
                child: Text('Mizo Puan Motif', style: TextStyle(fontSize: 18)),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              height: 90,
              width: double.infinity,
              color: AppTheme.accentAmber.withOpacity(0.15),
              child: CustomPaint(
                painter: CulturalMotifPainter(
                  type: _selectedMotif,
                  primaryColor: AppTheme.accentAmber.withOpacity(0.35),
                  secondaryColor: AppTheme.primaryNavy.withOpacity(0.25),
                ),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 24),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Welcome Back',
                      style: textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryNavy,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // Clickable Voice Assessment Card
                  InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const VoiceAssessmentScreen()),
                      ).then((_) {
                        _refreshSyncCount();
                      });
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Card(
                      color: AppTheme.primaryNavy,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            const CircleAvatar(
                              radius: 30,
                              backgroundColor: AppTheme.accentAmber,
                              child: Icon(Icons.mic, size: 36, color: Colors.black),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Voice Check-In',
                                    style: textTheme.titleMedium?.copyWith(
                                      color: Colors.white, 
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Tap here to do your daily vocal test.',
                                    style: textTheme.bodyMedium?.copyWith(
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 25),
                  
                  // My Daily Reminders Button
                  SizedBox(
                    height: 65,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accentAmber,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const RemindersScreen()),
                        );
                      },
                      icon: const Icon(Icons.alarm, size: 32),
                      label: const Text('My Daily Reminders'),
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Caregiver Analytics Dashboard Button
                  SizedBox(
                    height: 65,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryNavy,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const CaregiverAnalyticsScreen()),
                        );
                      },
                      icon: const Icon(Icons.analytics, size: 32),
                      label: const Text('Caregiver Dashboard'),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 3. Wrap the Simulator button in the flag
                  if (isDemoMode)
                    SizedBox(
                      height: 65,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.primaryNavy,
                          side: const BorderSide(color: AppTheme.primaryNavy, width: 2),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        onPressed: _simulateOfflineGameCompletion,
                        icon: const Icon(Icons.cloud_off, size: 32),
                        label: const Text('Simulate Offline Play'),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      
      // Bottom Sync Bar
      bottomNavigationBar: InkWell(
        onTap: () async {
          if (_pendingSyncCount > 0) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Syncing with server...')),
            );
            
            final success = await _syncRepo.pushToCloud();
            
            if (success) {
              await _refreshSyncCount();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Sync complete! Data sent to backend.'), 
                    backgroundColor: AppTheme.successGreen
                  ),
                );
              }
            } else {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Sync failed. Is the FastAPI server running?'), 
                    backgroundColor: Colors.red
                  ),
                );
              }
            }
          }
        },
        child: Container(
          color: AppTheme.backgroundGray,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _pendingSyncCount > 0 ? Icons.sync_problem : Icons.cloud_done,
                color: _pendingSyncCount > 0 ? AppTheme.accentAmber : AppTheme.successGreen,
                size: 28,
              ),
              const SizedBox(width: 12),
              Text(
                _pendingSyncCount > 0
                    ? '$_pendingSyncCount offline events pending\nTap to sync now'
                    : 'All offline data synced',
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(
                  color: Colors.black87,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}