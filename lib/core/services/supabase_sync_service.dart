import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';

class SupabaseSyncService {
  static final SupabaseSyncService _instance = SupabaseSyncService._();
  factory SupabaseSyncService() => _instance;
  SupabaseSyncService._();

  SupabaseClient get _client => Supabase.instance.client;

  String? get _userId => _client.auth.currentUser?.id;

  static String camelToSnake(String input) {
    if (input.isEmpty) return input;
    final exp = RegExp(r'(?<=[a-z0-9])[A-Z]|(?<=[A-Z])[A-Z](?=[a-z])');
    final snake = input.replaceAllMapped(exp, (m) => '_${m.group(0)!}');
    return snake.toLowerCase();
  }

  Map<String, dynamic> _toSupabase(Map<String, dynamic> json) {
    final result = <String, dynamic>{};
    for (final entry in json.entries) {
      result[camelToSnake(entry.key)] = entry.value is Enum
          ? (entry.value as Enum).name
          : entry.value;
    }
    return result;
  }

  void _addPupilLink(String pupilId) {
    final uid = _userId;
    if (uid == null) return;
    try {
      _client.from('instructor_pupil_links').insert({
        'instructor_id': uid,
        'pupil_id': pupilId,
        'status': 'active',
        'linked_at': DateTime.now().toIso8601String(),
      });
    } catch (_) {}
  }

  void _removePupilLink(String pupilId) {
    final uid = _userId;
    if (uid == null) return;
    try {
      _client.from('instructor_pupil_links').delete().eq('instructor_id', uid).eq('pupil_id', pupilId);
    } catch (_) {}
  }

  Map<String, dynamic> _cleanJson(Map<String, dynamic> json) {
    final result = <String, dynamic>{};
    for (final entry in json.entries) {
      if (entry.key == 'isMockData') continue;
      if (entry.value is List) {
        if (entry.value.isEmpty) continue;
      }
      if (entry.value is Map) {
        if ((entry.value as Map).isEmpty) continue;
      }
      result[entry.key] = entry.value;
    }
    return result;
  }

  Future<bool> syncPupil(Pupil pupil, {bool isDelete = false}) async {
    final uid = _userId;
    if (uid == null) return false;
    try {
      final json = _cleanJson(pupil.toJson());
      final supabaseData = _toSupabase(json);
      supabaseData['instructor_id'] = uid;
      if (isDelete) {
        await _client.from('pupils').delete().eq('id', pupil.id);
        _removePupilLink(pupil.id);
      } else {
        final existing = await _client
            .from('pupils')
            .select('id')
            .eq('id', pupil.id)
            .maybeSingle();
        if (existing != null) {
          await _client.from('pupils').update(supabaseData).eq('id', pupil.id);
        } else {
          supabaseData['id'] = pupil.id;
          supabaseData['created_at'] = DateTime.now().toIso8601String();
          await _client.from('pupils').insert(supabaseData);
          _addPupilLink(pupil.id);
        }
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> syncLesson(Lesson lesson, {bool isDelete = false}) async {
    final uid = _userId;
    if (uid == null) return false;
    try {
      final json = _cleanJson(lesson.toJson());
      json['instructor_id'] = uid;
      final supabaseData = _toSupabase(json);
      if (isDelete) {
        await _client.from('lessons').delete().eq('id', lesson.id);
      } else {
        final existing = await _client
            .from('lessons')
            .select('id')
            .eq('id', lesson.id)
            .maybeSingle();
        if (existing != null) {
          await _client.from('lessons').update(supabaseData).eq('id', lesson.id);
        } else {
          supabaseData['id'] = lesson.id;
          supabaseData['created_at'] = DateTime.now().toIso8601String();
          await _client.from('lessons').insert(supabaseData);
        }
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> syncOpenSlot(OpenSlot slot, {bool isDelete = false}) async {
    final uid = _userId;
    if (uid == null) return false;
    try {
      final json = _cleanJson(slot.toJson());
      json['instructor_id'] = uid;
      final supabaseData = _toSupabase(json);
      if (isDelete) {
        await _client.from('open_slots').delete().eq('id', slot.id);
      } else {
        final existing = await _client
            .from('open_slots')
            .select('id')
            .eq('id', slot.id)
            .maybeSingle();
        if (existing != null) {
          await _client.from('open_slots').update(supabaseData).eq('id', slot.id);
        } else {
          supabaseData['id'] = slot.id;
          supabaseData['created_at'] = DateTime.now().toIso8601String();
          await _client.from('open_slots').insert(supabaseData);
        }
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> syncEvent(CalendarEvent event, {bool isDelete = false}) async {
    final uid = _userId;
    if (uid == null) return false;
    try {
      final json = _cleanJson(event.toJson());
      json['instructor_id'] = uid;
      final supabaseData = _toSupabase(json);
      if (isDelete) {
        await _client.from('calendar_events').delete().eq('id', event.id);
      } else {
        final existing = await _client
            .from('calendar_events')
            .select('id')
            .eq('id', event.id)
            .maybeSingle();
        if (existing != null) {
          await _client.from('calendar_events').update(supabaseData).eq('id', event.id);
        } else {
          supabaseData['id'] = event.id;
          supabaseData['created_at'] = DateTime.now().toIso8601String();
          await _client.from('calendar_events').insert(supabaseData);
        }
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> syncTransaction(Transaction t, {bool isDelete = false}) async {
    final uid = _userId;
    if (uid == null) return false;
    try {
      final json = _cleanJson(t.toJson());
      json['instructor_id'] = uid;
      final supabaseData = _toSupabase(json);
      final table = t.type == TransactionType.income ? 'instructor_payments' : 'expenses';
      if (isDelete) {
        await _client.from(table).delete().eq('id', t.id);
      } else {
        final existing = await _client
            .from(table)
            .select('id')
            .eq('id', t.id)
            .maybeSingle();
        if (existing != null) {
          await _client.from(table).update(supabaseData).eq('id', t.id);
        } else {
          supabaseData['id'] = t.id;
          supabaseData['created_at'] = DateTime.now().toIso8601String();
          await _client.from(table).insert(supabaseData);
        }
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> syncEnquiry(Enquiry e, {bool isDelete = false}) async {
    final uid = _userId;
    if (uid == null) return false;
    try {
      final json = _cleanJson(e.toJson());
      json['instructor_id'] = uid;
      final supabaseData = _toSupabase(json);
      if (isDelete) {
        await _client.from('enquiries').delete().eq('id', e.id);
      } else {
        final existing = await _client
            .from('enquiries')
            .select('id')
            .eq('id', e.id)
            .maybeSingle();
        if (existing != null) {
          await _client.from('enquiries').update(supabaseData).eq('id', e.id);
        } else {
          supabaseData['id'] = e.id;
          supabaseData['created_at'] = DateTime.now().toIso8601String();
          await _client.from('enquiries').insert(supabaseData);
        }
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> syncTestReport(TestReport r, {bool isDelete = false}) async {
    final uid = _userId;
    if (uid == null) return false;
    try {
      final json = _cleanJson(r.toJson());
      json['instructor_id'] = uid;
      final supabaseData = _toSupabase(json);
      if (isDelete) {
        await _client.from('test_reports').delete().eq('id', r.id);
      } else {
        final existing = await _client
            .from('test_reports')
            .select('id')
            .eq('id', r.id)
            .maybeSingle();
        if (existing != null) {
          await _client.from('test_reports').update(supabaseData).eq('id', r.id);
        } else {
          supabaseData['id'] = r.id;
          supabaseData['created_at'] = DateTime.now().toIso8601String();
          await _client.from('test_reports').insert(supabaseData);
        }
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> syncMileage(MileageEntry m, {bool isDelete = false}) async {
    final uid = _userId;
    if (uid == null) return false;
    try {
      final json = _cleanJson(m.toJson());
      json['instructor_id'] = uid;
      final supabaseData = _toSupabase(json);
      if (isDelete) {
        await _client.from('mileage_entries').delete().eq('id', m.id);
      } else {
        final existing = await _client
            .from('mileage_entries')
            .select('id')
            .eq('id', m.id)
            .maybeSingle();
        if (existing != null) {
          await _client.from('mileage_entries').update(supabaseData).eq('id', m.id);
        } else {
          supabaseData['id'] = m.id;
          supabaseData['created_at'] = DateTime.now().toIso8601String();
          await _client.from('mileage_entries').insert(supabaseData);
        }
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> syncVehicle(Vehicle v, {bool isDelete = false}) async {
    final uid = _userId;
    if (uid == null) return false;
    try {
      final json = _cleanJson(v.toJson());
      json['instructor_id'] = uid;
      final supabaseData = _toSupabase(json);
      if (isDelete) {
        await _client.from('vehicles').delete().eq('id', v.id);
      } else {
        final existing = await _client
            .from('vehicles')
            .select('id')
            .eq('id', v.id)
            .maybeSingle();
        if (existing != null) {
          await _client.from('vehicles').update(supabaseData).eq('id', v.id);
        } else {
          supabaseData['id'] = v.id;
          supabaseData['created_at'] = DateTime.now().toIso8601String();
          await _client.from('vehicles').insert(supabaseData);
        }
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> syncInvoice(RequestPaymentInvoice i, {bool isDelete = false}) async {
    final uid = _userId;
    if (uid == null) return false;
    try {
      final json = _cleanJson(i.toJson());
      json['instructor_id'] = uid;
      final supabaseData = _toSupabase(json);
      if (isDelete) {
        await _client.from('invoices').delete().eq('id', i.id);
      } else {
        final existing = await _client
            .from('invoices')
            .select('id')
            .eq('id', i.id)
            .maybeSingle();
        if (existing != null) {
          await _client.from('invoices').update(supabaseData).eq('id', i.id);
        } else {
          supabaseData['id'] = i.id;
          supabaseData['created_at'] = DateTime.now().toIso8601String();
          await _client.from('invoices').insert(supabaseData);
        }
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> syncMessage(ChatMessage m) async {
    final uid = _userId;
    if (uid == null) return false;
    try {
      final json = _cleanJson(m.toJson());
      json['sender_id'] = uid;
      json['receiver_id'] = m.pupilId;
      final supabaseData = _toSupabase(json);
      supabaseData['sender_id'] = uid;
      supabaseData['receiver_id'] = m.pupilId;
      supabaseData.remove('pupil_id');

      final existing = await _client
          .from('messages')
          .select('id')
          .eq('id', m.id)
          .maybeSingle();
      if (existing != null) {
        await _client.from('messages').update(supabaseData).eq('id', m.id);
      } else {
        supabaseData['id'] = m.id;
        supabaseData['created_at'] = DateTime.now().toIso8601String();
        await _client.from('messages').insert(supabaseData);
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> logActivity(String type, String title, String description) async {
    final uid = _userId;
    if (uid == null) return false;
    try {
      await _client.from('instructor_activity_logs').insert({
        'instructor_id': uid,
        'action': title,
        'details': description,
        'created_at': DateTime.now().toIso8601String(),
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> fetchPupils() async {
    final uid = _userId;
    if (uid == null) return [];
    try {
      final response = await _client
          .from('pupils')
          .select('*')
          .eq('instructor_id', uid)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (_) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> fetchLessons() async {
    final uid = _userId;
    if (uid == null) return [];
    try {
      final response = await _client
          .from('lessons')
          .select('*')
          .eq('instructor_id', uid)
          .order('date', ascending: true);
      return List<Map<String, dynamic>>.from(response);
    } catch (_) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> fetchTransactions() async {
    final uid = _userId;
    if (uid == null) return [];
    try {
      final payments = await _client
          .from('instructor_payments')
          .select('*')
          .eq('instructor_id', uid);
      final expenses = await _client
          .from('expenses')
          .select('*')
          .eq('instructor_id', uid);
      return [
        ...List<Map<String, dynamic>>.from(payments),
        ...List<Map<String, dynamic>>.from(expenses),
      ];
    } catch (_) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> fetchOpenSlots() async {
    final uid = _userId;
    if (uid == null) return [];
    try {
      final response = await _client
          .from('open_slots')
          .select('*')
          .eq('instructor_id', uid)
          .order('date', ascending: true);
      return List<Map<String, dynamic>>.from(response);
    } catch (_) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> fetchEnquiries() async {
    final uid = _userId;
    if (uid == null) return [];
    try {
      final response = await _client
          .from('enquiries')
          .select('*')
          .eq('instructor_id', uid)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (_) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> fetchMessages() async {
    final uid = _userId;
    if (uid == null) return [];
    try {
      final response = await _client
          .from('messages')
          .select('*')
          .or('sender_id.eq.$uid,receiver_id.eq.$uid')
          .order('created_at', ascending: true);
      return List<Map<String, dynamic>>.from(response);
    } catch (_) {
      return [];
    }
  }
}