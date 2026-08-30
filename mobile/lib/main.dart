import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io' show Platform;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'core/theme/app_theme.dart';
import 'core/ui/cultural_motifs.dart';
import 'data/sync_repository.dart';
import 'data/reminder_repository.dart';
import 'features/reminders/reminders_screen.dart';
import 'features/voice/voice_assessment_screen.dart';
import 'screens/caregiver_analytics_screen.dart'; 
import 'features/games/games_screen.dart';
import 'features/stats/stats_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialize DotEnv safely
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    dotenv.loadFromString(envString: '''
      API_BASE_URL=http://127.0.0.1:8000
    ''');
  }

  // 2. Initialize SQLite for Windows / Linux Desktop
  if (Platform.isWindows || Platform.isLinux) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // 3. Non-blocking startup sync
  final syncRepo = SyncRepository();
  await syncRepo.pushToCloud();

  runApp(const NeuroAssistApp());
}

class NeuroAssistApp extends StatelessWidget {
  const NeuroAssistApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NeuroAssist NER',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.elderlyTheme.copyWith(
        snackBarTheme: const SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          // margin removed: Floating behavior applies default padding automatically
          elevation: 6,
        ),
      ),
      home: const MainNavigationScreen(),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  int _pendingSyncCount = 0;
  final SyncRepository _syncRepo = SyncRepository();
  Timer? _syncTimer;

  final List<Widget> _screens = [
    const PatientHomeScreen(),
    const GamesScreen(),
    const StatsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _refreshSyncCount();
    // Periodically update global sync indicator count
    _syncTimer = Timer.periodic(const Duration(seconds: 5), (_) => _refreshSyncCount());
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    super.dispose();
  }

  Future<void> _refreshSyncCount() async {
    final count = await _syncRepo.getPendingEventCount();
    if (mounted) {
      setState(() {
        _pendingSyncCount = count;
      });
    }
  }

  Future<void> _triggerManualSync() async {
    final success = await _syncRepo.pushToCloud();
    await _refreshSyncCount();
    if (mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Sync successful!' : 'Backend unreachable.'),
          backgroundColor: success ? AppTheme.successGreen : AppTheme.alertRed,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Global Non-Overlapping Sync Status Banner
          InkWell(
            onTap: _triggerManualSync,
            child: Container(
              color: _pendingSyncCount > 0 ? AppTheme.accentAmber : AppTheme.primaryNavy,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _pendingSyncCount > 0 ? Icons.sync_problem : Icons.cloud_done,
                    color: _pendingSyncCount > 0 ? Colors.black : Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _pendingSyncCount > 0
                        ? '$_pendingSyncCount offline events pending. Tap to sync.'
                        : 'All data synced with server',
                    style: TextStyle(
                      color: _pendingSyncCount > 0 ? Colors.black : Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
          BottomNavigationBar(
            currentIndex: _currentIndex,
            iconSize: 32,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
              _refreshSyncCount();
            },
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.sports_esports),
                label: 'Games',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.bar_chart),
                label: 'Stats',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class PatientHomeScreen extends StatefulWidget {
  const PatientHomeScreen({super.key});

  @override
  State<PatientHomeScreen> createState() => _PatientHomeScreenState();
}

class _PatientHomeScreenState extends State<PatientHomeScreen> {
  MotifType _selectedMotif = MotifType.assamese;
  final SyncRepository _syncRepo = SyncRepository();
  final ReminderRepository _reminderRepo = ReminderRepository(); 
  Timer? _reminderTimer; 

  @override
  void initState() {
    super.initState();
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

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.accentAmber,
        title: const Icon(Icons.warning_rounded, size: 64, color: Colors.black),
        content: Text(
          "Time to: ${reminder.title}!",
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black),
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

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('NeuroAssist NER'),
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
                child: Text('Assamese Motif', style: TextStyle(fontSize: 18)),
              ),
              const PopupMenuItem<MotifType>(
                value: MotifType.naga,
                child: Text('Naga Motif', style: TextStyle(fontSize: 18)),
              ),
              const PopupMenuItem<MotifType>(
                value: MotifType.mizo,
                child: Text('Mizo Motif', style: TextStyle(fontSize: 18)),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              height: 80,
              width: double.infinity,
              color: AppTheme.accentAmber.withOpacity(0.15),
              child: CustomPaint(
                painter: CulturalMotifPainter(
                  type: _selectedMotif,
                  primaryColor: AppTheme.accentAmber.withOpacity(0.35),
                  secondaryColor: AppTheme.primaryNavy.withOpacity(0.25),
                ),
                child: Center(
                  child: Text(
                    'Welcome Back',
                    style: textTheme.headlineSmall?.copyWith(color: AppTheme.primaryNavy),
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // High-Contrast Voice Assessment Target
                  Card(
                    color: AppTheme.primaryNavy,
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const VoiceAssessmentScreen()),
                        );
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Row(
                          children: [
                            const CircleAvatar(
                              radius: 32,
                              backgroundColor: AppTheme.accentAmber,
                              child: Icon(Icons.mic, size: 38, color: Colors.black),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Voice Check-In',
                                    style: textTheme.titleLarge?.copyWith(color: Colors.white),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Tap here for daily voice check.',
                                    style: textTheme.bodyMedium?.copyWith(color: Colors.white.withOpacity(0.9)),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Reminders Target
                  Card(
                    color: AppTheme.accentAmber,
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const RemindersScreen()),
                        );
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Row(
                          children: [
                            const Icon(Icons.alarm, size: 40, color: Colors.black),
                            const SizedBox(width: 16),
                            Text(
                              'My Daily Reminders',
                              style: textTheme.titleMedium?.copyWith(color: Colors.black),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Caregiver Dashboard Target
                  Card(
                    color: AppTheme.surfaceWhite,
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: const BorderSide(color: AppTheme.primaryNavy, width: 2),
                    ),
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const CaregiverAnalyticsScreen()),
                        );
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Row(
                          children: [
                            const Icon(Icons.analytics, size: 40, color: AppTheme.primaryNavy),
                            const SizedBox(width: 16),
                            Text(
                              'Caregiver View',
                              style: textTheme.titleMedium,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}