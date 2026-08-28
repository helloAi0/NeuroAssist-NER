import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../data/reminder_repository.dart';

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  final ReminderRepository _repo = ReminderRepository();
  List<Reminder> _reminders = [];

  @override
  void initState() {
    super.initState();
    _loadReminders();
  }

  Future<void> _loadReminders() async {
    final reminders = await _repo.getActiveReminders();
    setState(() {
      _reminders = reminders;
    });
  }

  Future<void> _addReminder() async {
    TimeOfDay? selectedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            timePickerTheme: const TimePickerThemeData(
              helpTextStyle: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
          child: child!,
        );
      },
    );

    if (selectedTime != null && mounted) {
      // Mocking a selection of standard tasks for accessibility
      String taskTitle = "Take Medication"; 

      final newReminder = Reminder(
        id: 'rem_${DateTime.now().millisecondsSinceEpoch}',
        title: taskTitle,
        hour: selectedTime.hour,
        minute: selectedTime.minute,
        isActive: true,
        lastTriggeredDate: '',
      );

      await _repo.addReminder(newReminder);
      _loadReminders();
    }
  }

  Future<void> _deleteReminder(String id) async {
    await _repo.deleteReminder(id);
    _loadReminders();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Reminders'),
        backgroundColor: AppTheme.primaryNavy,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ElevatedButton.icon(
                onPressed: _addReminder,
                icon: const Icon(Icons.add_alarm, size: 32),
                label: const Text('Add New Reminder'),
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.successGreen),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: _reminders.isEmpty
                    ? const Center(
                        child: Text(
                          'No active reminders.\nTap the button above to add one.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 20, color: Colors.black54),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _reminders.length,
                        itemBuilder: (context, index) {
                          final rem = _reminders[index];
                          final timeString = TimeOfDay(hour: rem.hour, minute: rem.minute).format(context);
                          
                          return Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(16),
                              leading: const Icon(Icons.alarm, size: 40, color: AppTheme.accentAmber),
                              title: Text(rem.title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                              subtitle: Text(timeString, style: const TextStyle(fontSize: 20)),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete, size: 32, color: AppTheme.alertRed),
                                onPressed: () => _deleteReminder(rem.id),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}