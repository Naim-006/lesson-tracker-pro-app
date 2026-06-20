import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/models.dart';
import '../services/supabase_sync_service.dart';

final appStateProvider =
    StateNotifierProvider<AppStateNotifier, AppState>((ref) {
  return AppStateNotifier();
});

final currentTabProvider = StateProvider<int>((ref) => 0);

final settingsProvider = StateNotifierProvider<SettingsNotifier, AppSettings>(
  (ref) => SettingsNotifier(),
);

class AppState {
  final List<Pupil> pupils;
  final List<Lesson> lessons;
  final List<OpenSlot> openSlots;
  final List<CalendarEvent> events;
  final List<Transaction> transactions;
  final List<ChatMessage> messages;
  final List<ActivityEntry> activities;
  final List<AppNotification> notifications;
  final List<Enquiry> enquiries;
  final List<TestReport> testReports;
  final List<MileageEntry> mileageEntries;
  final List<ProgressCategory> progressCategories;
  final List<ProgressSkill> progressSkills;
  final List<RequestPaymentInvoice> invoices;
  final List<Vehicle> vehicles;
  final List<Map<String, dynamic>> teachingResources;

  const AppState({
    this.pupils = const [],
    this.lessons = const [],
    this.openSlots = const [],
    this.events = const [],
    this.transactions = const [],
    this.messages = const [],
    this.activities = const [],
    this.notifications = const [],
    this.enquiries = const [],
    this.testReports = const [],
    this.mileageEntries = const [],
    this.progressCategories = const [],
    this.progressSkills = const [],
    this.invoices = const [],
    this.vehicles = const [],
    this.teachingResources = const [],
  });

  AppState copyWith({
    List<Pupil>? pupils,
    List<Lesson>? lessons,
    List<OpenSlot>? openSlots,
    List<CalendarEvent>? events,
    List<Transaction>? transactions,
    List<ChatMessage>? messages,
    List<ActivityEntry>? activities,
    List<AppNotification>? notifications,
    List<Enquiry>? enquiries,
    List<TestReport>? testReports,
    List<MileageEntry>? mileageEntries,
    List<ProgressCategory>? progressCategories,
    List<ProgressSkill>? progressSkills,
    List<RequestPaymentInvoice>? invoices,
    List<Vehicle>? vehicles,
    List<Map<String, dynamic>>? teachingResources,
  }) {
    return AppState(
      pupils: pupils ?? this.pupils,
      lessons: lessons ?? this.lessons,
      openSlots: openSlots ?? this.openSlots,
      events: events ?? this.events,
      transactions: transactions ?? this.transactions,
      messages: messages ?? this.messages,
      activities: activities ?? this.activities,
      notifications: notifications ?? this.notifications,
      enquiries: enquiries ?? this.enquiries,
      testReports: testReports ?? this.testReports,
      mileageEntries: mileageEntries ?? this.mileageEntries,
      progressCategories: progressCategories ?? this.progressCategories,
      progressSkills: progressSkills ?? this.progressSkills,
      invoices: invoices ?? this.invoices,
      vehicles: vehicles ?? this.vehicles,
      teachingResources: teachingResources ?? this.teachingResources,
    );
  }

  double get totalIncome => transactions
      .where((t) => t.type == TransactionType.income)
      .fold(0.0, (s, t) => s + t.amount);

  double get totalExpenses => transactions
      .where((t) => t.type == TransactionType.expense)
      .fold(0.0, (s, t) => s + t.amount);

  double get profit => totalIncome - totalExpenses;

  double monthlyIncome(DateTime now) => transactions
      .where((t) =>
          t.type == TransactionType.income &&
          t.date.month == now.month &&
          t.date.year == now.year)
      .fold(0.0, (s, t) => s + t.amount);

  double monthlyExpenses(DateTime now) => transactions
      .where((t) =>
          t.type == TransactionType.expense &&
          t.date.month == now.month &&
          t.date.year == now.year)
      .fold(0.0, (s, t) => s + t.amount);

  List<Lesson> lessonsForDay(DateTime day) {
    return lessons
        .where((l) =>
            l.date.year == day.year &&
            l.date.month == day.month &&
            l.date.day == day.day)
        .toList()
      ..sort((a, b) => a.time.compareTo(b.time));
  }

  List<Lesson> get unpaidLessons => lessons
      .where((l) =>
          l.status == LessonStatus.completed && !l.paid)
      .toList();

  List<String> conversationPupilIds() {
    final ids = <String>{};
    for (final m in messages) {
      ids.add(m.pupilId);
    }
    return ids.toList();
  }
}

class AppStateNotifier extends StateNotifier<AppState> {
  AppStateNotifier() : super(const AppState()) {
    _init();
  }

  static const _key = 'lesson_tracker_pro_v1';
  bool _loaded = false;
  final _supabase = SupabaseSyncService();

  Future<void> _init() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      await _hydrateFromSupabase();
    }
    if (!_loaded) {
      await _load();
    }
    if (!_loaded && state.pupils.isEmpty) {
      _seedMockData();
    }
  }

  Future<void> _hydrateFromSupabase() async {
    try {
      final pupils = await _supabase.fetchPupils();
      final lessons = await _supabase.fetchLessons();
      final transactions = await _supabase.fetchTransactions();
      final openSlots = await _supabase.fetchOpenSlots();
      final enquiries = await _supabase.fetchEnquiries();
      final messages = await _supabase.fetchMessages();

      state = AppState(
        pupils: pupils
            .map((e) => Pupil.fromJson(_snakeToCamelMap(e)))
            .toList(),
        lessons: lessons
            .map((e) => Lesson.fromJson(_snakeToCamelMap(e)))
            .toList(),
        transactions: transactions
            .map((e) => Transaction.fromJson(_snakeToCamelMap(e)))
            .toList(),
        openSlots: openSlots
            .map((e) => OpenSlot.fromJson(_snakeToCamelMap(e)))
            .toList(),
        enquiries: enquiries
            .map((e) => Enquiry.fromJson(_snakeToCamelMap(e)))
            .toList(),
        messages: messages
            .map((e) => ChatMessage.fromJson(_snakeToCamelMap(e)))
            .toList(),
      );
      _loaded = true;
      _save();
    } catch (_) {
      // fall back to local storage
    }
  }

  static Map<String, dynamic> _snakeToCamelMap(Map<String, dynamic> input) {
    final result = <String, dynamic>{};
    for (final entry in input.entries) {
      final camelKey = entry.key.replaceAllMapped(
        RegExp(r'_([a-z])'),
        (match) => match.group(1)!.toUpperCase(),
      );
      result[camelKey] = entry.value;
    }
    return result;
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null) return;
      final json = jsonDecode(raw) as Map<String, dynamic>;
      state = AppState(
        pupils: (json['pupils'] as List?)
                ?.map((e) => Pupil.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        lessons: (json['lessons'] as List?)
                ?.map((e) => Lesson.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        openSlots: (json['openSlots'] as List?)
                ?.map((e) => OpenSlot.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        events: (json['events'] as List?)
                ?.map((e) => CalendarEvent.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        transactions: (json['transactions'] as List?)
                ?.map((e) => Transaction.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        messages: (json['messages'] as List?)
                ?.map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        activities: (json['activities'] as List?)
                ?.map((e) => ActivityEntry.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        notifications: (json['notifications'] as List?)
                ?.map((e) => AppNotification.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        enquiries: (json['enquiries'] as List?)
                ?.map((e) => Enquiry.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        testReports: (json['testReports'] as List?)
                ?.map((e) => TestReport.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        mileageEntries: (json['mileageEntries'] as List?)
                ?.map((e) => MileageEntry.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        progressCategories: (json['progressCategories'] as List?)
                ?.map((e) => ProgressCategory.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        progressSkills: (json['progressSkills'] as List?)
                ?.map((e) => ProgressSkill.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        invoices: (json['invoices'] as List?)
                ?.map((e) => RequestPaymentInvoice.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        vehicles: (json['vehicles'] as List?)
                ?.map((e) => Vehicle.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        teachingResources: (json['teachingResources'] as List?)
                ?.cast<Map<String, dynamic>>() ??
            [],
      );
      _loaded = true;
    } catch (_) {
      // use empty / seed
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final json = {
      'pupils': state.pupils.map((e) => e.toJson()).toList(),
      'lessons': state.lessons.map((e) => e.toJson()).toList(),
      'openSlots': state.openSlots.map((e) => e.toJson()).toList(),
      'events': state.events.map((e) => e.toJson()).toList(),
      'transactions': state.transactions.map((e) => e.toJson()).toList(),
      'messages': state.messages.map((e) => e.toJson()).toList(),
      'activities': state.activities.map((e) => e.toJson()).toList(),
      'notifications': state.notifications.map((e) => e.toJson()).toList(),
      'enquiries': state.enquiries.map((e) => e.toJson()).toList(),
      'testReports': state.testReports.map((e) => e.toJson()).toList(),
      'mileageEntries': state.mileageEntries.map((e) => e.toJson()).toList(),
      'progressCategories': state.progressCategories.map((e) => e.toJson()).toList(),
      'progressSkills': state.progressSkills.map((e) => e.toJson()).toList(),
      'invoices': state.invoices.map((e) => e.toJson()).toList(),
      'vehicles': state.vehicles.map((e) => e.toJson()).toList(),
      'teachingResources': state.teachingResources,
    };
    await prefs.setString(_key, jsonEncode(json));
  }

  void _seedMockData() {
    final emma = Pupil(
      firstName: 'Emma',
      lastName: 'Wilson',
      phone: '07123456789',
      email: 'emma@example.com',
      hourlyRate: 40,
      status: PupilStatus.current,
      mechanicalGearboxPreference: GearboxType.manual,
      tags: ['Test ready'],
    );
    final james = Pupil(
      firstName: 'James',
      lastName: 'Smith',
      phone: '07234567890',
      email: 'james@example.com',
      hourlyRate: 45,
      status: PupilStatus.current,
      mechanicalGearboxPreference: GearboxType.automatic,
    );
    final sophie = Pupil(
      firstName: 'Sophie',
      lastName: 'Brown',
      phone: '07345678901',
      status: PupilStatus.waiting,
    );
    final now = DateTime.now();
    state = AppState(
      pupils: [emma, james, sophie],
      lessons: [
        Lesson(
          pupilId: emma.id,
          pupilName: emma.fullName,
          date: now,
          time: '09:00',
          duration: 120,
          rate: 80,
          pickupLocation: '12 Oak Street',
        ),
        Lesson(
          pupilId: james.id,
          pupilName: james.fullName,
          date: now,
          time: '14:00',
          duration: 60,
          rate: 45,
        ),
        Lesson(
          pupilId: emma.id,
          pupilName: emma.fullName,
          date: now.subtract(const Duration(days: 2)),
          time: '10:00',
          duration: 60,
          rate: 40,
          status: LessonStatus.completed,
          paid: false,
        ),
      ],
      openSlots: [
        OpenSlot(date: now, startTime: '16:00', duration: 120),
      ],
      transactions: [
        Transaction(
          type: TransactionType.income,
          amount: 80,
          description: 'Block payment — Emma Wilson',
          date: now.subtract(const Duration(days: 5)),
          pupilId: emma.id,
          pupilName: emma.fullName,
          paymentMethod: PaymentMethod.bankTransfer,
        ),
        Transaction(
          type: TransactionType.expense,
          amount: 65.5,
          description: 'Fuel',
          date: now.subtract(const Duration(days: 3)),
          category: ExpenseCategory.fuel,
        ),
      ],
      messages: [
        ChatMessage(
          pupilId: emma.id,
          pupilName: emma.fullName,
          body: 'Can we move Thursday to Friday?',
          timestamp: now.subtract(const Duration(hours: 3)),
          isFromInstructor: false,
        ),
        ChatMessage(
          pupilId: emma.id,
          pupilName: emma.fullName,
          body: 'Yes — I have 2pm free on Friday.',
          timestamp: now.subtract(const Duration(hours: 2)),
          isFromInstructor: true,
        ),
      ],
      enquiries: [
        Enquiry(
          name: 'Michael Oliver',
          email: 'michael@example.com',
          phone: '07456789012',
          experience: ExperienceLevel.beginner,
          status: EnquiryStatus.pending,
        ),
      ],
      testReports: [
        TestReport(
          pupilId: emma.id,
          pupilName: emma.fullName,
          date: now.subtract(const Duration(days: 30)),
          result: TestResult.pass,
          gradeLevel: 'Category B',
          manoeuvres: ['Parallel park', 'Bay park'],
        ),
      ],
      activities: [
        ActivityEntry(
          type: 'lesson_booked',
          title: 'Lesson booked',
          description: 'Emma Wilson — today 09:00',
          timestamp: now.subtract(const Duration(hours: 1)),
        ),
      ],
      notifications: [
        AppNotification(
          title: 'Welcome',
          body: 'Lesson Tracker Pro is ready. Your data is saved on this device.',
          timestamp: now.subtract(const Duration(minutes: 5)),
        ),
      ],
    );
    _save();
  }

  void _log(String type, String title, String description) {
    final entry = ActivityEntry(
      type: type,
      title: title,
      description: description,
      timestamp: DateTime.now(),
    );
    state = state.copyWith(
      activities: [entry, ...state.activities].take(100).toList(),
    );
  }

  void _notify(String title, String body) {
    final n = AppNotification(
      title: title,
      body: body,
      timestamp: DateTime.now(),
    );
    state = state.copyWith(
      notifications: [n, ...state.notifications].take(50).toList(),
    );
  }

  // Pupils
  void addPupil(Pupil p) {
    state = state.copyWith(pupils: [...state.pupils, p]);
    _log('pupil_added', 'Pupil added', p.fullName);
    _notify('Pupil added', p.fullName);
    _save();
    _supabase.syncPupil(p);
  }

  void updatePupil(Pupil p) {
    state = state.copyWith(
      pupils: state.pupils.map((x) => x.id == p.id ? p : x).toList(),
    );
    _save();
    _supabase.syncPupil(p);
  }

  void deletePupil(String id) {
    final pupil = state.pupils.firstWhere((p) => p.id == id);
    final name = pupil.fullName;
    state = state.copyWith(
      pupils: state.pupils.where((p) => p.id != id).toList(),
    );
    _log('pupil_removed', 'Pupil removed', name);
    _save();
    _supabase.syncPupil(pupil, isDelete: true);
  }

  // Lessons
  void addLesson(Lesson l) {
    state = state.copyWith(lessons: [...state.lessons, l]);
    _log('lesson_booked', 'Lesson booked', '${l.pupilName} ${l.time}');
    _notify('Lesson booked', '${l.pupilName} · ${l.time}');
    _save();
    _supabase.syncLesson(l);
  }

  void updateLesson(Lesson l) {
    final old = state.lessons.firstWhere((x) => x.id == l.id);
    state = state.copyWith(
      lessons: state.lessons.map((x) => x.id == l.id ? l : x).toList(),
    );
    if (old.status != l.status && l.status == LessonStatus.completed) {
      _log('lesson_completed', 'Lesson completed', l.pupilName);
    }
    if (!old.paid && l.paid) {
      _log('payment_received', 'Lesson marked paid', l.pupilName);
    }
    _save();
    _supabase.syncLesson(l);
  }

  void deleteLesson(String id) {
    final lesson = state.lessons.firstWhere((l) => l.id == id);
    state = state.copyWith(
      lessons: state.lessons.where((l) => l.id != id).toList(),
    );
    _save();
    _supabase.syncLesson(lesson, isDelete: true);
  }

  // Slots
  void addOpenSlot(OpenSlot s) {
    state = state.copyWith(openSlots: [...state.openSlots, s]);
    _log('slot_created', 'Open slot', '${s.startTime} ${s.duration}min');
    _save();
    _supabase.syncOpenSlot(s);
  }

  void deleteOpenSlot(String id) {
    final slot = state.openSlots.firstWhere((s) => s.id == id);
    state = state.copyWith(
      openSlots: state.openSlots.where((s) => s.id != id).toList(),
    );
    _save();
    _supabase.syncOpenSlot(slot, isDelete: true);
  }

  // Events
  void addEvent(CalendarEvent e) {
    state = state.copyWith(events: [...state.events, e]);
    _log('event_created', 'Event', e.title);
    _save();
    _supabase.syncEvent(e);
  }

  void deleteEvent(String id) {
    final event = state.events.firstWhere((e) => e.id == id);
    state = state.copyWith(
      events: state.events.where((e) => e.id != id).toList(),
    );
    _save();
    _supabase.syncEvent(event, isDelete: true);
  }

  // Transactions
  void addTransaction(Transaction t) {
    state = state.copyWith(transactions: [...state.transactions, t]);
    if (t.type == TransactionType.income) {
      _log('payment_received', 'Payment', '£${t.amount.toStringAsFixed(2)}');
      _notify('Payment received', '£${t.amount.toStringAsFixed(2)}');
    } else {
      _log('expense_recorded', 'Expense', t.description);
      _notify('Expense recorded', t.description);
    }
    _save();
    _supabase.syncTransaction(t);
  }

  // Messages
  void sendMessage(ChatMessage m) {
    state = state.copyWith(messages: [...state.messages, m]);
    _save();
    _supabase.syncMessage(m);
  }

  void updateMessage(ChatMessage updated) {
    state = state.copyWith(
      messages: state.messages
          .map((m) => m.id == updated.id ? updated : m)
          .toList(),
    );
    _save();
    _supabase.syncMessage(updated);
  }

  void toggleMessageLock(String id) {
    state = state.copyWith(
      messages: state.messages
          .map((m) => m.id == id ? m.copyWith(isLocked: !m.isLocked) : m)
          .toList(),
    );
    _save();
    final msg = state.messages.firstWhere((m) => m.id == id);
    _supabase.syncMessage(msg);
  }

  // Enquiries
  void addEnquiry(Enquiry e) {
    state = state.copyWith(enquiries: [...state.enquiries, e]);
    _log('enquiry_new', 'New enquiry', e.name);
    _save();
    _supabase.syncEnquiry(e);
  }

  void updateEnquiry(Enquiry e) {
    state = state.copyWith(
      enquiries: state.enquiries.map((x) => x.id == e.id ? e : x).toList(),
    );
    _save();
    _supabase.syncEnquiry(e);
  }

  void deleteEnquiry(String id) {
    final enquiry = state.enquiries.firstWhere((e) => e.id == id);
    state = state.copyWith(
      enquiries: state.enquiries.where((e) => e.id != id).toList(),
    );
    _save();
    _supabase.syncEnquiry(enquiry, isDelete: true);
  }

  // Test reports
  void addTestReport(TestReport r) {
    state = state.copyWith(testReports: [...state.testReports, r]);
    _log('test_report', 'Test report', r.pupilName);
    _save();
    _supabase.syncTestReport(r);
  }

  void deleteTestReport(String id) {
    final report = state.testReports.firstWhere((r) => r.id == id);
    state = state.copyWith(
      testReports: state.testReports.where((r) => r.id != id).toList(),
    );
    _save();
    _supabase.syncTestReport(report, isDelete: true);
  }

  void updateTestReport(TestReport r) {
    state = state.copyWith(
      testReports: state.testReports.map((x) => x.id == r.id ? r : x).toList(),
    );
    _save();
    _supabase.syncTestReport(r);
  }

  // Mileage
  void addMileage(MileageEntry m) {
    state = state.copyWith(mileageEntries: [...state.mileageEntries, m]);
    _log('mileage', 'Mileage', '${m.miles} miles');
    _notify('Mileage logged', '${m.miles} miles');
    _save();
    _supabase.syncMileage(m);
  }

  // Progress Categories
  void addProgressCategory(ProgressCategory c) {
    state = state.copyWith(progressCategories: [...state.progressCategories, c]);
    _save();
  }

  void updateProgressCategory(ProgressCategory c) {
    state = state.copyWith(
      progressCategories: state.progressCategories.map((x) => x.id == c.id ? c : x).toList(),
    );
    _save();
  }

  void deleteProgressCategory(String id) {
    state = state.copyWith(
      progressCategories: state.progressCategories.where((c) => c.id != id).toList(),
    );
    _save();
  }

  // Progress Skills
  void addProgressSkill(ProgressSkill s) {
    state = state.copyWith(progressSkills: [...state.progressSkills, s]);
    _save();
  }

  void updateProgressSkill(ProgressSkill s) {
    state = state.copyWith(
      progressSkills: state.progressSkills.map((x) => x.id == s.id ? s : x).toList(),
    );
    _save();
  }

  void deleteProgressSkill(String id) {
    state = state.copyWith(
      progressSkills: state.progressSkills.where((s) => s.id != id).toList(),
    );
    _save();
  }

  // Invoices
  void addInvoice(RequestPaymentInvoice i) {
    state = state.copyWith(invoices: [...state.invoices, i]);
    _log('invoice_created', 'Invoice created', i.pupilName);
    _save();
    _supabase.syncInvoice(i);
  }

  void updateInvoice(RequestPaymentInvoice i) {
    state = state.copyWith(
      invoices: state.invoices.map((x) => x.id == i.id ? i : x).toList(),
    );
    _save();
    _supabase.syncInvoice(i);
  }

  void deleteInvoice(String id) {
    final invoice = state.invoices.firstWhere((i) => i.id == id);
    state = state.copyWith(
      invoices: state.invoices.where((i) => i.id != id).toList(),
    );
    _save();
    _supabase.syncInvoice(invoice, isDelete: true);
  }

  // Vehicles
  void addVehicle(Vehicle v) {
    state = state.copyWith(vehicles: [...state.vehicles, v]);
    _log('vehicle_added', 'Vehicle added', '${v.make} ${v.model}');
    _save();
    _supabase.syncVehicle(v);
  }

  void updateVehicle(Vehicle v) {
    state = state.copyWith(
      vehicles: state.vehicles.map((x) => x.id == v.id ? v : x).toList(),
    );
    _save();
    _supabase.syncVehicle(v);
  }

  void deleteVehicle(String id) {
    final vehicle = state.vehicles.firstWhere((v) => v.id == id);
    state = state.copyWith(
      vehicles: state.vehicles.where((v) => v.id != id).toList(),
    );
    _save();
    _supabase.syncVehicle(vehicle, isDelete: true);
  }

  // Teaching Resources
  void addTeachingResource(Map<String, dynamic> resource) {
    state = state.copyWith(teachingResources: [...state.teachingResources, resource]);
    _log('resource_added', 'Resource added', resource['title'] as String);
    _save();
  }

  void updateTeachingResource(Map<String, dynamic> resource) {
    state = state.copyWith(
      teachingResources: state.teachingResources.map((r) => r['id'] == resource['id'] ? resource : r).toList(),
    );
    _save();
  }

  void deleteTeachingResource(String id) {
    state = state.copyWith(
      teachingResources: state.teachingResources.where((r) => r['id'] != id).toList(),
    );
    _save();
  }

  void markNotificationRead(String id) {
    state = state.copyWith(
      notifications: state.notifications
          .map((n) => n.id == id ? n.copyWith(read: true) : n)
          .toList(),
    );
    _save();
  }

  void markAllNotificationsRead() {
    state = state.copyWith(
      notifications: state.notifications.map((n) => n.copyWith(read: true)).toList(),
    );
    _save();
  }
}

final dataRefreshProvider = StateProvider<int>((ref) => 0);

final unreadNotificationsCountProvider = Provider<int>((ref) {
  final list = ref.watch(appStateProvider).notifications;
  return list.where((n) => !n.read).length;
});

class SettingsNotifier extends StateNotifier<AppSettings> {
  SettingsNotifier() : super(const AppSettings()) {
    _load();
  }

  static const _key = 'ltp_settings';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw != null) {
      state = AppSettings.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    }
  }

  Future<void> update(AppSettings s) async {
    state = s;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(s.toJson()));
  }
}
