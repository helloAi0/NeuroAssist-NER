import 'dart:convert';
import 'package:http/http.dart' as http;

class SyncEvent {
  final String id;
  final String type;
  final String payload;

  SyncEvent(this.id, this.type, this.payload);

  Map<String, dynamic> toJson() => {
    "id": id,
    "type": type,
    "payload": payload,
  };
}

class SyncRepository {
  // In-memory queue for the prototype
  static final List<SyncEvent> _pendingEvents = [];

  Future<void> queueEvent(String id, String type, String payload) async {
    _pendingEvents.add(SyncEvent(id, type, payload));
  }

  Future<int> getPendingEventCount() async {
    return _pendingEvents.length;
  }

  Future<bool> pushToCloud() async {
    if (_pendingEvents.isEmpty) return true;

    final batch = {
      "device_id": "windows_flutter_client",
      "events": _pendingEvents.map((e) => e.toJson()).toList(),
    };

    try {
      // Pointing to your local FastAPI server
      final response = await http.post(
        Uri.parse('http://localhost:8000/api/sync'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(batch),
      );

      if (response.statusCode == 200) {
        // Server accepted the batch, safe to clear the local queue
        _pendingEvents.clear();
        return true;
      }
    } catch (e) {
      print("Sync error: $e");
    }
    return false;
  }
}