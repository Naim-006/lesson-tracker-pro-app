import 'package:uuid/uuid.dart';

const _uuid = Uuid();

enum PupilStatus { current, waiting, passed, archived, cancelled }

enum GearboxType { any, manual, automatic }

enum LessonStatus { scheduled, completed, cancelled, noShow }

enum LessonType { drivingLesson, mockTestSession, refresherCourse, administrativeBlock }

enum PaymentMethod { bankTransfer, cash, card, paypal, lessonTrackerPro, cheque, online }

enum PaymentType { individual, block }

enum TransactionType { income, expense }

enum ExpenseCategory {
  accounts,
  advertising,
  association,
  bankCharges,
  computer,
  dvsaFees,
  equipment,
  foodDrink,
  franchiseFee,
  fuel,
  insuranceBusiness,
  insurancePersonal,
  insuranceVehicle,
  insurance,
  maintenance,
  lease,
  training,
  other,
}

enum RecurrenceType { daily, workingDays, weekly, fortnightly }

enum EnquiryStatus {
  pending,
  contacted,
  interested,
  notInterested,
  converted,
}

enum TestResult { pending, pass, fail }

enum ExperienceLevel { beginner, intermediate, advanced }

enum BookingStatus { confirmed, tentative, completed }

enum SlotGroupFilter { currentPupilsOnly, privateToSchool }

class AppNotification {
  final String id;
  final String title;
  final String body;
  final DateTime timestamp;
  final bool read;

  AppNotification({
    String? id,
    required this.title,
    required this.body,
    required this.timestamp,
    this.read = false,
  }) : id = id ?? _uuid.v4();

  AppNotification copyWith({bool? read}) => AppNotification(
        id: id,
        title: title,
        body: body,
        timestamp: timestamp,
        read: read ?? this.read,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'body': body,
        'timestamp': timestamp.toIso8601String(),
        'read': read,
      };

  factory AppNotification.fromJson(Map<String, dynamic> json) => AppNotification(
        id: json['id'] as String,
        title: json['title'] as String,
        body: json['body'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
        read: json['read'] as bool? ?? false,
      );
}

class Pupil {
  final String id;
  final String firstName;
  final String lastName;
  final String phone;
  final String? secondaryPhone;
  final String email;
  final String? postcode;
  final List<String> pickupAddresses;
  final List<String> dropoffAddresses;
  final String? assignedPostcode;
  final String? assignedBillingRateId;
  final double hourlyRate;
  final GearboxType mechanicalGearboxPreference;
  final PupilStatus status;
  final List<String> tags;
  final Map<String, List<int>> availability;
  final List<String> weeklyAvailabilityDays;
  final String? notes;
  final bool onWaitingList;
  final bool inviteToApp;
  final bool termsAccepted;
  final bool requireSignatureBeforeBooking;
  final int aggregatedTotalLessonsCount;
  final double grossRevenueEarned;
  final int packageTimePrepaidMinutes;
  final int packageTimeRemainingMinutes;
  final bool companionAppLinkedStatus;
  final double outstandingBalance;
  final Map<String, Map<String, int>> progressScores;
  final int progressScaleType;
  final DateTime createdAt;
  final int registrationTimestamp;
  final DateTime? testDate;
  final bool? testPassed;

  Pupil({
    String? id,
    required this.firstName,
    required this.lastName,
    required this.phone,
    this.secondaryPhone,
    this.email = '',
    this.postcode,
    this.pickupAddresses = const [],
    this.dropoffAddresses = const [],
    this.assignedPostcode,
    this.assignedBillingRateId,
    this.hourlyRate = 40,
    this.mechanicalGearboxPreference = GearboxType.manual,
    this.status = PupilStatus.current,
    this.tags = const [],
    this.availability = const {},
    this.weeklyAvailabilityDays = const [],
    this.notes,
    this.onWaitingList = false,
    this.inviteToApp = false,
    this.termsAccepted = false,
    this.requireSignatureBeforeBooking = false,
    this.aggregatedTotalLessonsCount = 0,
    this.grossRevenueEarned = 0.0,
    this.packageTimePrepaidMinutes = 0,
    this.packageTimeRemainingMinutes = 0,
    this.companionAppLinkedStatus = false,
    this.outstandingBalance = 0.0,
    this.progressScores = const {},
    this.progressScaleType = 5,
    DateTime? createdAt,
    int? registrationTimestamp,
    this.testDate,
    this.testPassed,
  })  : id = id ?? _uuid.v4(),
        createdAt = createdAt ?? DateTime.now(),
        registrationTimestamp = registrationTimestamp ?? DateTime.now().millisecondsSinceEpoch;

  String get fullName => '$firstName $lastName'.trim();

  String get initials {
    final f = firstName.isNotEmpty ? firstName[0] : '';
    final l = lastName.isNotEmpty ? lastName[0] : '';
    return '$f$l'.toUpperCase();
  }

  Pupil copyWith({
    String? firstName,
    String? lastName,
    String? phone,
    String? secondaryPhone,
    String? email,
    String? postcode,
    List<String>? pickupAddresses,
    List<String>? dropoffAddresses,
    String? assignedPostcode,
    String? assignedBillingRateId,
    double? hourlyRate,
    GearboxType? mechanicalGearboxPreference,
    PupilStatus? status,
    List<String>? tags,
    Map<String, List<int>>? availability,
    List<String>? weeklyAvailabilityDays,
    String? notes,
    bool? onWaitingList,
    bool? inviteToApp,
    bool? termsAccepted,
    bool? requireSignatureBeforeBooking,
    int? aggregatedTotalLessonsCount,
    double? grossRevenueEarned,
    int? packageTimePrepaidMinutes,
    int? packageTimeRemainingMinutes,
    bool? companionAppLinkedStatus,
    double? outstandingBalance,
    Map<String, Map<String, int>>? progressScores,
    int? progressScaleType,
    DateTime? createdAt,
    int? registrationTimestamp,
    DateTime? testDate,
    bool? testPassed,
  }) {
    return Pupil(
      id: id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phone: phone ?? this.phone,
      secondaryPhone: secondaryPhone ?? this.secondaryPhone,
      email: email ?? this.email,
      postcode: postcode ?? this.postcode,
      pickupAddresses: pickupAddresses ?? this.pickupAddresses,
      dropoffAddresses: dropoffAddresses ?? this.dropoffAddresses,
      assignedPostcode: assignedPostcode ?? this.assignedPostcode,
      assignedBillingRateId: assignedBillingRateId ?? this.assignedBillingRateId,
      hourlyRate: hourlyRate ?? this.hourlyRate,
      mechanicalGearboxPreference: mechanicalGearboxPreference ?? this.mechanicalGearboxPreference,
      status: status ?? this.status,
      tags: tags ?? this.tags,
      availability: availability ?? this.availability,
      weeklyAvailabilityDays: weeklyAvailabilityDays ?? this.weeklyAvailabilityDays,
      notes: notes ?? this.notes,
      onWaitingList: onWaitingList ?? this.onWaitingList,
      inviteToApp: inviteToApp ?? this.inviteToApp,
      termsAccepted: termsAccepted ?? this.termsAccepted,
      requireSignatureBeforeBooking: requireSignatureBeforeBooking ?? this.requireSignatureBeforeBooking,
      aggregatedTotalLessonsCount: aggregatedTotalLessonsCount ?? this.aggregatedTotalLessonsCount,
      grossRevenueEarned: grossRevenueEarned ?? this.grossRevenueEarned,
      packageTimePrepaidMinutes: packageTimePrepaidMinutes ?? this.packageTimePrepaidMinutes,
      packageTimeRemainingMinutes: packageTimeRemainingMinutes ?? this.packageTimeRemainingMinutes,
      companionAppLinkedStatus: companionAppLinkedStatus ?? this.companionAppLinkedStatus,
      outstandingBalance: outstandingBalance ?? this.outstandingBalance,
      progressScores: progressScores ?? this.progressScores,
      progressScaleType: progressScaleType ?? this.progressScaleType,
      createdAt: createdAt,
      registrationTimestamp: registrationTimestamp,
      testDate: testDate ?? this.testDate,
      testPassed: testPassed ?? this.testPassed,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'firstName': firstName,
        'lastName': lastName,
        'phone': phone,
        'secondaryPhone': secondaryPhone,
        'email': email,
        'postcode': postcode,
        'pickupAddresses': pickupAddresses,
        'dropoffAddresses': dropoffAddresses,
        'assignedPostcode': assignedPostcode,
        'assignedBillingRateId': assignedBillingRateId,
        'hourlyRate': hourlyRate,
        'mechanicalGearboxPreference': mechanicalGearboxPreference.name,
        'status': status.name,
        'tags': tags,
        'availability': availability.map((k, v) => MapEntry(k, v)),
        'weeklyAvailabilityDays': weeklyAvailabilityDays,
        'notes': notes,
        'onWaitingList': onWaitingList,
        'inviteToApp': inviteToApp,
        'termsAccepted': termsAccepted,
        'requireSignatureBeforeBooking': requireSignatureBeforeBooking,
        'aggregatedTotalLessonsCount': aggregatedTotalLessonsCount,
        'grossRevenueEarned': grossRevenueEarned,
        'packageTimePrepaidMinutes': packageTimePrepaidMinutes,
        'packageTimeRemainingMinutes': packageTimeRemainingMinutes,
        'companionAppLinkedStatus': companionAppLinkedStatus,
        'outstandingBalance': outstandingBalance,
        'progressScores': progressScores.map((k, v) => MapEntry(k, v.map((k2, v2) => MapEntry(k2, v2)))),
        'progressScaleType': progressScaleType,
        'createdAt': createdAt.toIso8601String(),
        'registrationTimestamp': registrationTimestamp,
        'testDate': testDate?.toIso8601String(),
        'testPassed': testPassed,
      };

  factory Pupil.fromJson(Map<String, dynamic> json) => Pupil(
        id: json['id'] as String,
        firstName: json['firstName'] as String,
        lastName: json['lastName'] as String,
        phone: json['phone'] as String,
        secondaryPhone: json['secondaryPhone'] as String?,
        email: json['email'] as String? ?? '',
        postcode: json['postcode'] as String?,
        pickupAddresses: List<String>.from(json['pickupAddresses'] as List? ?? []),
        dropoffAddresses: List<String>.from(json['dropoffAddresses'] as List? ?? []),
        assignedPostcode: json['assignedPostcode'] as String?,
        assignedBillingRateId: json['assignedBillingRateId'] as String?,
        hourlyRate: (json['hourlyRate'] as num?)?.toDouble() ?? 40,
        mechanicalGearboxPreference: GearboxType.values.byName(json['mechanicalGearboxPreference'] as String? ?? 'manual'),
        status: PupilStatus.values.byName(json['status'] as String? ?? 'current'),
        tags: List<String>.from(json['tags'] as List? ?? []),
        availability: (json['availability'] as Map<String, dynamic>? ?? {})
            .map((k, v) => MapEntry(k, List<int>.from(v as List))),
        weeklyAvailabilityDays: List<String>.from(json['weeklyAvailabilityDays'] as List? ?? []),
        notes: json['notes'] as String?,
        onWaitingList: json['onWaitingList'] as bool? ?? false,
        inviteToApp: json['inviteToApp'] as bool? ?? false,
        termsAccepted: json['termsAccepted'] as bool? ?? false,
        requireSignatureBeforeBooking: json['requireSignatureBeforeBooking'] as bool? ?? false,
        aggregatedTotalLessonsCount: json['aggregatedTotalLessonsCount'] as int? ?? 0,
        grossRevenueEarned: (json['grossRevenueEarned'] as num?)?.toDouble() ?? 0.0,
        packageTimePrepaidMinutes: json['packageTimePrepaidMinutes'] as int? ?? 0,
        packageTimeRemainingMinutes: json['packageTimeRemainingMinutes'] as int? ?? 0,
        companionAppLinkedStatus: json['companionAppLinkedStatus'] as bool? ?? false,
        outstandingBalance: (json['outstandingBalance'] as num?)?.toDouble() ?? 0.0,
        progressScores: (json['progressScores'] as Map<String, dynamic>? ?? {}).map(
            (k, v) => MapEntry(k, (v as Map<String, dynamic>).map((k2, v2) => MapEntry(k2, v2 as int)))),
        progressScaleType: json['progressScaleType'] as int? ?? 5,
        createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt'] as String) : null,
        registrationTimestamp: json['registrationTimestamp'] as int?,
        testDate: json['testDate'] != null ? DateTime.parse(json['testDate'] as String) : null,
        testPassed: json['testPassed'] as bool?,
      );
}

class Lesson {
  final String id;
  final String pupilId;
  final String pupilName;
  final DateTime date;
  final String time;
  final int duration;
  final LessonType type;
  final LessonStatus status;
  final double rate;
  final bool paid;
  final String? pickupLocation;
  final String? dropoffLocation;
  final String? notes;
  final bool isRecurring;
  final bool sharedWithPupil;
  final bool requireOnlinePayment;
  final LessonType sessionClassification;
  final BookingStatus bookingStatus;
  final bool isSharedWithPupilCompanionView;

  Lesson({
    String? id,
    required this.pupilId,
    required this.pupilName,
    required this.date,
    required this.time,
    this.duration = 60,
    this.type = LessonType.drivingLesson,
    this.status = LessonStatus.scheduled,
    required this.rate,
    this.paid = false,
    this.pickupLocation,
    this.dropoffLocation,
    this.notes,
    this.isRecurring = false,
    this.sharedWithPupil = false,
    this.requireOnlinePayment = false,
    this.sessionClassification = LessonType.drivingLesson,
    this.bookingStatus = BookingStatus.confirmed,
    this.isSharedWithPupilCompanionView = false,
  }) : id = id ?? _uuid.v4();

  Lesson copyWith({
    DateTime? date,
    String? time,
    int? duration,
    LessonType? type,
    LessonStatus? status,
    double? rate,
    bool? paid,
    String? pickupLocation,
    String? dropoffLocation,
    String? notes,
    bool? isRecurring,
    bool? sharedWithPupil,
    bool? requireOnlinePayment,
    LessonType? sessionClassification,
    BookingStatus? bookingStatus,
    bool? isSharedWithPupilCompanionView,
  }) {
    return Lesson(
      id: id,
      pupilId: pupilId,
      pupilName: pupilName,
      date: date ?? this.date,
      time: time ?? this.time,
      duration: duration ?? this.duration,
      type: type ?? this.type,
      status: status ?? this.status,
      rate: rate ?? this.rate,
      paid: paid ?? this.paid,
      pickupLocation: pickupLocation ?? this.pickupLocation,
      dropoffLocation: dropoffLocation ?? this.dropoffLocation,
      notes: notes ?? this.notes,
      isRecurring: isRecurring ?? this.isRecurring,
      sharedWithPupil: sharedWithPupil ?? this.sharedWithPupil,
      requireOnlinePayment: requireOnlinePayment ?? this.requireOnlinePayment,
      sessionClassification: sessionClassification ?? this.sessionClassification,
      bookingStatus: bookingStatus ?? this.bookingStatus,
      isSharedWithPupilCompanionView: isSharedWithPupilCompanionView ?? this.isSharedWithPupilCompanionView,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'pupilId': pupilId,
        'pupilName': pupilName,
        'date': date.toIso8601String(),
        'time': time,
        'duration': duration,
        'type': type.name,
        'status': status.name,
        'rate': rate,
        'paid': paid,
        'pickupLocation': pickupLocation,
        'dropoffLocation': dropoffLocation,
        'notes': notes,
        'isRecurring': isRecurring,
        'sharedWithPupil': sharedWithPupil,
        'requireOnlinePayment': requireOnlinePayment,
        'sessionClassification': sessionClassification.name,
        'bookingStatus': bookingStatus.name,
        'isSharedWithPupilCompanionView': isSharedWithPupilCompanionView,
      };

  factory Lesson.fromJson(Map<String, dynamic> json) => Lesson(
        id: json['id'] as String,
        pupilId: json['pupilId'] as String,
        pupilName: json['pupilName'] as String,
        date: DateTime.parse(json['date'] as String),
        time: json['time'] as String,
        duration: json['duration'] as int? ?? 60,
        type: LessonType.values.byName(json['type'] as String? ?? 'drivingLesson'),
        status: LessonStatus.values.byName(json['status'] as String? ?? 'scheduled'),
        rate: (json['rate'] as num).toDouble(),
        paid: json['paid'] as bool? ?? false,
        pickupLocation: json['pickupLocation'] as String?,
        dropoffLocation: json['dropoffLocation'] as String?,
        notes: json['notes'] as String?,
        isRecurring: json['isRecurring'] as bool? ?? false,
        sharedWithPupil: json['sharedWithPupil'] as bool? ?? false,
        requireOnlinePayment: json['requireOnlinePayment'] as bool? ?? false,
        sessionClassification: LessonType.values.byName(json['sessionClassification'] as String? ?? 'drivingLesson'),
        bookingStatus: BookingStatus.values.byName(json['bookingStatus'] as String? ?? 'confirmed'),
        isSharedWithPupilCompanionView: json['isSharedWithPupilCompanionView'] as bool? ?? false,
      );
}

class OpenSlot {
  final String id;
  final DateTime date;
  final String startTime;
  final int duration;
  final bool isRecurring;
  final RecurrenceType? recurrenceType;
  final bool acceptsOnlinePayment;
  final SlotGroupFilter groupFilter;
  final GearboxType gearboxFilter;
  final List<String> targetPupilIds;
  final String? customMessage;
  final int slotCount;
  final BookingStatus status;
  final String? offeredToPupilId;

  OpenSlot({
    String? id,
    required this.date,
    required this.startTime,
    this.duration = 60,
    this.isRecurring = false,
    this.recurrenceType,
    this.acceptsOnlinePayment = false,
    this.groupFilter = SlotGroupFilter.currentPupilsOnly,
    this.gearboxFilter = GearboxType.any,
    this.targetPupilIds = const [],
    this.customMessage,
    this.slotCount = 1,
    this.status = BookingStatus.tentative,
    this.offeredToPupilId,
  }) : id = id ?? _uuid.v4();

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String(),
        'startTime': startTime,
        'duration': duration,
        'isRecurring': isRecurring,
        'recurrenceType': recurrenceType?.name,
        'acceptsOnlinePayment': acceptsOnlinePayment,
        'groupFilter': groupFilter.name,
        'gearboxFilter': gearboxFilter.name,
        'targetPupilIds': targetPupilIds,
        'customMessage': customMessage,
        'slotCount': slotCount,
        'status': status.name,
        'offeredToPupilId': offeredToPupilId,
      };

  factory OpenSlot.fromJson(Map<String, dynamic> json) => OpenSlot(
        id: json['id'] as String,
        date: DateTime.parse(json['date'] as String),
        startTime: json['startTime'] as String,
        duration: json['duration'] as int? ?? 60,
        isRecurring: json['isRecurring'] as bool? ?? false,
        recurrenceType: json['recurrenceType'] != null
            ? RecurrenceType.values.byName(json['recurrenceType'] as String)
            : null,
        acceptsOnlinePayment: json['acceptsOnlinePayment'] as bool? ?? false,
        groupFilter: SlotGroupFilter.values.byName(json['groupFilter'] as String? ?? 'currentPupilsOnly'),
        gearboxFilter: GearboxType.values.byName(json['gearboxFilter'] as String? ?? 'any'),
        targetPupilIds: List<String>.from(json['targetPupilIds'] as List? ?? []),
        customMessage: json['customMessage'] as String?,
        slotCount: json['slotCount'] as int? ?? 1,
        status: BookingStatus.values.byName(json['status'] as String? ?? 'tentative'),
        offeredToPupilId: json['offeredToPupilId'] as String?,
      );
}

class CalendarEvent {
  final String id;
  final String title;
  final String? location;
  final DateTime date;
  final String? time;
  final bool isAllDay;
  final String? notes;
  final DateTime? endDate;
  final String? endTime;
  final bool syncToExternalCalendar;

  CalendarEvent({
    String? id,
    required this.title,
    this.location,
    required this.date,
    this.time,
    this.isAllDay = false,
    this.notes,
    this.endDate,
    this.endTime,
    this.syncToExternalCalendar = false,
  }) : id = id ?? _uuid.v4();

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'location': location,
        'date': date.toIso8601String(),
        'time': time,
        'isAllDay': isAllDay,
        'notes': notes,
        'endDate': endDate?.toIso8601String(),
        'endTime': endTime,
        'syncToExternalCalendar': syncToExternalCalendar,
      };

  factory CalendarEvent.fromJson(Map<String, dynamic> json) => CalendarEvent(
        id: json['id'] as String,
        title: json['title'] as String,
        location: json['location'] as String?,
        date: DateTime.parse(json['date'] as String),
        time: json['time'] as String?,
        isAllDay: json['isAllDay'] as bool? ?? false,
        notes: json['notes'] as String?,
        endDate: json['endDate'] != null ? DateTime.parse(json['endDate'] as String) : null,
        endTime: json['endTime'] as String?,
        syncToExternalCalendar: json['syncToExternalCalendar'] as bool? ?? false,
      );
}

class Transaction {
  final String id;
  final TransactionType type;
  final double amount;
  final String description;
  final DateTime date;
  final String? pupilId;
  final String? pupilName;
  final PaymentMethod? paymentMethod;
  final PaymentType? paymentType;
  final ExpenseCategory? category;
  final bool isRecurring;
  final String? receiptUrl;
  final String? vendorName;
  final bool isReconciled;
  final bool taxDeductible;

  Transaction({
    String? id,
    required this.type,
    required this.amount,
    required this.description,
    required this.date,
    this.pupilId,
    this.pupilName,
    this.paymentMethod,
    this.paymentType,
    this.category,
    this.isRecurring = false,
    this.receiptUrl,
    this.vendorName,
    this.isReconciled = false,
    this.taxDeductible = true,
  }) : id = id ?? _uuid.v4();

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'amount': amount,
        'description': description,
        'date': date.toIso8601String(),
        'pupilId': pupilId,
        'pupilName': pupilName,
        'paymentMethod': paymentMethod?.name,
        'paymentType': paymentType?.name,
        'category': category?.name,
        'isRecurring': isRecurring,
        'receiptUrl': receiptUrl,
        'vendorName': vendorName,
        'isReconciled': isReconciled,
        'taxDeductible': taxDeductible,
      };

  factory Transaction.fromJson(Map<String, dynamic> json) => Transaction(
        id: json['id'] as String,
        type: TransactionType.values.byName(json['type'] as String),
        amount: (json['amount'] as num).toDouble(),
        description: json['description'] as String,
        date: DateTime.parse(json['date'] as String),
        pupilId: json['pupilId'] as String?,
        pupilName: json['pupilName'] as String?,
        paymentMethod: json['paymentMethod'] != null
            ? PaymentMethod.values.byName(json['paymentMethod'] as String)
            : null,
        paymentType: json['paymentType'] != null
            ? PaymentType.values.byName(json['paymentType'] as String)
            : null,
        category: json['category'] != null
            ? ExpenseCategory.values.byName(json['category'] as String)
            : null,
        isRecurring: json['isRecurring'] as bool? ?? false,
        receiptUrl: json['receiptUrl'] as String?,
        vendorName: json['vendorName'] as String?,
        isReconciled: json['isReconciled'] as bool? ?? false,
        taxDeductible: json['taxDeductible'] as bool? ?? true,
      );
}

class ChatMessage {
  final String id;
  final String pupilId;
  final String pupilName;
  final String body;
  final DateTime timestamp;
  final bool isFromInstructor;
  final bool isLocked;
  final MessageStatus status;
  final bool isEdited;
  final bool isDeleted;
  final DateTime? scheduledFor;

  ChatMessage({
    String? id,
    required this.pupilId,
    required this.pupilName,
    required this.body,
    required this.timestamp,
    required this.isFromInstructor,
    this.isLocked = false,
    this.status = MessageStatus.sent,
    this.isEdited = false,
    this.isDeleted = false,
    this.scheduledFor,
  }) : id = id ?? _uuid.v4();

  ChatMessage copyWith({
    bool? isLocked,
    String? body,
    MessageStatus? status,
    bool? isEdited,
    bool? isDeleted,
    DateTime? scheduledFor,
  }) => ChatMessage(
        id: id,
        pupilId: pupilId,
        pupilName: pupilName,
        body: body ?? this.body,
        timestamp: timestamp,
        isFromInstructor: isFromInstructor,
        isLocked: isLocked ?? this.isLocked,
        status: status ?? this.status,
        isEdited: isEdited ?? this.isEdited,
        isDeleted: isDeleted ?? this.isDeleted,
        scheduledFor: scheduledFor ?? this.scheduledFor,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'pupilId': pupilId,
        'pupilName': pupilName,
        'body': body,
        'timestamp': timestamp.toIso8601String(),
        'isFromInstructor': isFromInstructor,
        'isLocked': isLocked,
        'status': status.name,
        'isEdited': isEdited,
        'isDeleted': isDeleted,
        'scheduledFor': scheduledFor?.toIso8601String(),
      };

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        id: json['id'] as String,
        pupilId: json['pupilId'] as String,
        pupilName: json['pupilName'] as String,
        body: json['body'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
        isFromInstructor: json['isFromInstructor'] as bool,
        isLocked: json['isLocked'] as bool? ?? false,
        status: json['status'] != null
            ? MessageStatus.values.byName(json['status'] as String)
            : MessageStatus.sent,
        isEdited: json['isEdited'] as bool? ?? false,
        isDeleted: json['isDeleted'] as bool? ?? false,
        scheduledFor: json['scheduledFor'] != null
            ? DateTime.parse(json['scheduledFor'] as String)
            : null,
      );
}

enum MessageStatus {
  sending,
  sent,
  delivered,
  seen,
}

class ActivityEntry {
  final String id;
  final String type;
  final String title;
  final String description;
  final DateTime timestamp;

  ActivityEntry({
    String? id,
    required this.type,
    required this.title,
    required this.description,
    required this.timestamp,
  }) : id = id ?? _uuid.v4();

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'title': title,
        'description': description,
        'timestamp': timestamp.toIso8601String(),
      };

  factory ActivityEntry.fromJson(Map<String, dynamic> json) => ActivityEntry(
        id: json['id'] as String,
        type: json['type'] as String,
        title: json['title'] as String,
        description: json['description'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
      );
}

class Enquiry {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String address;
  final String postcode;
  final String notes;
  final ExperienceLevel experience;
  final GearboxType gearboxPreference;
  final bool hasProvisionalLicense;
  final int priorPracticeHours;
  final List<String> weeklyAvailabilityDays;
  final List<String> availability;
  final EnquiryStatus status;
  final DateTime createdAt;
  final DateTime? lastContacted;
  final String? source;
  final String? assignedToId;
  final bool isMockData;

  Enquiry({
    String? id,
    String? name,
    String? firstName,
    String? lastName,
    this.email = '',
    this.phone = '',
    this.address = '',
    this.postcode = '',
    this.notes = '',
    this.experience = ExperienceLevel.beginner,
    this.gearboxPreference = GearboxType.manual,
    this.hasProvisionalLicense = false,
    this.priorPracticeHours = 0,
    this.weeklyAvailabilityDays = const [],
    this.availability = const [],
    this.status = EnquiryStatus.pending,
    DateTime? createdAt,
    this.lastContacted,
    this.source,
    this.assignedToId,
    this.isMockData = false,
  })  : id = id ?? _uuid.v4(),
        firstName = firstName ?? (name != null ? name.split(' ').first : ''),
        lastName = lastName ?? (name != null && name.split(' ').length > 1 ? name.split(' ').sublist(1).join(' ') : ''),
        createdAt = createdAt ?? DateTime.now();

  String get name => '$firstName $lastName'.trim().isNotEmpty ? '$firstName $lastName'.trim() : firstName;

  Enquiry copyWith({
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    String? address,
    String? postcode,
    String? notes,
    ExperienceLevel? experience,
    GearboxType? gearboxPreference,
    bool? hasProvisionalLicense,
    int? priorPracticeHours,
    List<String>? weeklyAvailabilityDays,
    List<String>? availability,
    EnquiryStatus? status,
    DateTime? lastContacted,
    String? source,
    String? assignedToId,
    bool? isMockData,
  }) {
    return Enquiry(
      id: id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      postcode: postcode ?? this.postcode,
      notes: notes ?? this.notes,
      experience: experience ?? this.experience,
      gearboxPreference: gearboxPreference ?? this.gearboxPreference,
      hasProvisionalLicense: hasProvisionalLicense ?? this.hasProvisionalLicense,
      priorPracticeHours: priorPracticeHours ?? this.priorPracticeHours,
      weeklyAvailabilityDays: weeklyAvailabilityDays ?? this.weeklyAvailabilityDays,
      availability: availability ?? this.availability,
      status: status ?? this.status,
      createdAt: createdAt,
      lastContacted: lastContacted ?? this.lastContacted,
      source: source ?? this.source,
      assignedToId: assignedToId ?? this.assignedToId,
      isMockData: isMockData ?? this.isMockData,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'phone': phone,
        'address': address,
        'postcode': postcode,
        'notes': notes,
        'experience': experience.name,
        'gearboxPreference': gearboxPreference.name,
        'hasProvisionalLicense': hasProvisionalLicense,
        'priorPracticeHours': priorPracticeHours,
        'weeklyAvailabilityDays': weeklyAvailabilityDays,
        'availability': availability,
        'status': status.name,
        'createdAt': createdAt.toIso8601String(),
        'lastContacted': lastContacted?.toIso8601String(),
        'source': source,
        'assignedToId': assignedToId,
        'isMockData': isMockData,
      };

  factory Enquiry.fromJson(Map<String, dynamic> json) {
    final nameVal = json['name'] as String?;
    return Enquiry(
      id: json['id'] as String,
      firstName: json['firstName'] as String? ?? (nameVal != null ? nameVal.split(' ').first : ''),
      lastName: json['lastName'] as String? ?? (nameVal != null && nameVal.split(' ').length > 1 ? nameVal.split(' ').sublist(1).join(' ') : ''),
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      address: json['address'] as String? ?? '',
      postcode: json['postcode'] as String? ?? '',
      notes: json['notes'] as String? ?? '',
      experience: ExperienceLevel.values.byName(json['experience'] as String? ?? 'beginner'),
      gearboxPreference: GearboxType.values.byName(json['gearboxPreference'] as String? ?? 'manual'),
      hasProvisionalLicense: json['hasProvisionalLicense'] as bool? ?? false,
      priorPracticeHours: json['priorPracticeHours'] as int? ?? 0,
      weeklyAvailabilityDays: List<String>.from(json['weeklyAvailabilityDays'] as List? ?? []),
      availability: List<String>.from(json['availability'] as List? ?? []),
      status: _parseEnquiryStatus(json['status'] as String? ?? 'pending'),
      createdAt: DateTime.parse(json['createdAt'] as String? ?? DateTime.now().toIso8601String()),
      lastContacted: json['lastContacted'] != null ? DateTime.parse(json['lastContacted'] as String) : null,
      source: json['source'] as String?,
      assignedToId: json['assignedToId'] as String?,
      isMockData: json['isMockData'] as bool? ?? false,
    );
  }
}

class TestReport {
  final String id;
  final String pupilId;
  final String pupilName;
  final DateTime date;
  final String gradeLevel;
  final TestResult result;
  final List<String> manoeuvres;
  final String scalesNotes;
  final String auralNotes;
  final String notes;
  final int testCenterId;
  final String? testCenterName;
  final int faults;
  final int seriousFaults;
  final int dangerousFaults;
  final String? examinerName;

  TestReport({
    String? id,
    required this.pupilId,
    required this.pupilName,
    required this.date,
    this.gradeLevel = 'Practical',
    this.result = TestResult.pending,
    this.manoeuvres = const [],
    this.scalesNotes = '',
    this.auralNotes = '',
    this.notes = '',
    this.testCenterId = 0,
    this.testCenterName,
    this.faults = 0,
    this.seriousFaults = 0,
    this.dangerousFaults = 0,
    this.examinerName,
  }) : id = id ?? _uuid.v4();

  Map<String, dynamic> toJson() => {
        'id': id,
        'pupilId': pupilId,
        'pupilName': pupilName,
        'date': date.toIso8601String(),
        'gradeLevel': gradeLevel,
        'result': result.name,
        'manoeuvres': manoeuvres,
        'scalesNotes': scalesNotes,
        'auralNotes': auralNotes,
        'notes': notes,
        'testCenterId': testCenterId,
        'testCenterName': testCenterName,
        'faults': faults,
        'seriousFaults': seriousFaults,
        'dangerousFaults': dangerousFaults,
        'examinerName': examinerName,
      };

  factory TestReport.fromJson(Map<String, dynamic> json) => TestReport(
        id: json['id'] as String,
        pupilId: json['pupilId'] as String,
        pupilName: json['pupilName'] as String,
        date: DateTime.parse(json['date'] as String),
        gradeLevel: json['gradeLevel'] as String? ?? 'Practical',
        result: TestResult.values.byName(json['result'] as String),
        manoeuvres: List<String>.from(json['manoeuvres'] as List? ?? []),
        scalesNotes: json['scalesNotes'] as String? ?? '',
        auralNotes: json['auralNotes'] as String? ?? '',
        notes: json['notes'] as String? ?? '',
        testCenterId: json['testCenterId'] as int? ?? 0,
        testCenterName: json['testCenterName'] as String?,
        faults: json['faults'] as int? ?? 0,
        seriousFaults: json['seriousFaults'] as int? ?? 0,
        dangerousFaults: json['dangerousFaults'] as int? ?? 0,
        examinerName: json['examinerName'] as String?,
      );
}

class AppSettings {
  final bool notificationsEnabled;
  final bool emailNotifications;
  final int lessonReminderMinutes;
  final String currency;
  final int defaultLessonDuration;
  final String timezone;
  final String instructorName;
  final String instructorTitle;
  final int themeMode;
  final String defaultThemeColor;
  final bool enableSync;
  final String? syncEndpoint;
  final String? syncToken;
  final int appVersionSchema;
  final double hourlyRate;
  final String businessName;
  final String termsAndConditions;
  final bool acceptOnlinePayments;
  final bool covidSafetyEnabled;
  final bool progressTrackingEnabled;
  final int defaultProgressScale;
  final List<String> skillCategories;
  final bool theoryTestSyncEnabled;
  final String theoryTestProvider;
  final bool calendarSyncEnabled;
  final List<Map<String, dynamic>> teachingResources;
  final Map<String, dynamic> workHours;
  final List<Map<String, dynamic>> paymentMethods;
  final List<int> lessonLengths;
  final List<Map<String, dynamic>> customPackages;
  final String scoringSystem;
  final int cancellationPeriod;
  final String? brandLogoUrl;
  final String? brandPrimaryColor;
  final String? drivingTestSyncApiKey;
  final bool drivingTestAutoSync;
  final Map<String, dynamic> covidRiskData;

  const AppSettings({
    this.notificationsEnabled = true,
    this.emailNotifications = true,
    this.lessonReminderMinutes = 60,
    this.currency = 'GBP',
    this.defaultLessonDuration = 60,
    this.timezone = 'Europe/London',
    this.instructorName = 'Alex Rivers',
    this.instructorTitle = 'ADI Instructor',
    this.themeMode = 3,
    this.defaultThemeColor = '#007AFF',
    this.enableSync = false,
    this.syncEndpoint,
    this.syncToken,
    this.appVersionSchema = 2,
    this.hourlyRate = 35.0,
    this.businessName = 'Alex Rivers Driving School',
    this.termsAndConditions = 'Standard terms and conditions apply. Cancellations must be made at least 48 hours in advance.',
    this.acceptOnlinePayments = true,
    this.covidSafetyEnabled = true,
    this.progressTrackingEnabled = true,
    this.defaultProgressScale = 5,
    this.skillCategories = const ['Controls', 'Manoeuvres', 'Junctions', 'Road Positioning', 'Planning & Observation'],
    this.theoryTestSyncEnabled = false,
    this.theoryTestProvider = 'gov.uk',
    this.calendarSyncEnabled = false,
    this.teachingResources = const [],
    this.workHours = const {},
    this.paymentMethods = const [],
    this.lessonLengths = const [30, 45, 60, 90, 120],
    this.customPackages = const [],
    this.scoringSystem = 'Average',
    this.cancellationPeriod = 48,
    this.brandLogoUrl,
    this.brandPrimaryColor,
    this.drivingTestSyncApiKey,
    this.drivingTestAutoSync = false,
    this.covidRiskData = const {},
  });

  String get currencySymbol {
    switch (currency) {
      case 'USD':
        return '\$';
      case 'EUR':
        return '€';
      default:
        return '£';
    }
  }

  AppSettings copyWith({
    bool? notificationsEnabled,
    bool? emailNotifications,
    int? lessonReminderMinutes,
    String? currency,
    int? defaultLessonDuration,
    String? timezone,
    String? instructorName,
    String? instructorTitle,
    int? themeMode,
    String? defaultThemeColor,
    bool? enableSync,
    String? syncEndpoint,
    String? syncToken,
    int? appVersionSchema,
    double? hourlyRate,
    String? businessName,
    String? termsAndConditions,
    bool? acceptOnlinePayments,
    bool? covidSafetyEnabled,
    bool? progressTrackingEnabled,
    int? defaultProgressScale,
    List<String>? skillCategories,
    bool? theoryTestSyncEnabled,
    String? theoryTestProvider,
    bool? calendarSyncEnabled,
    List<Map<String, dynamic>>? teachingResources,
    Map<String, dynamic>? workHours,
    List<Map<String, dynamic>>? paymentMethods,
    List<int>? lessonLengths,
    List<Map<String, dynamic>>? customPackages,
    String? scoringSystem,
    int? cancellationPeriod,
    String? brandLogoUrl,
    String? brandPrimaryColor,
    String? drivingTestSyncApiKey,
    bool? drivingTestAutoSync,
    Map<String, dynamic>? covidRiskData,
  }) {
    return AppSettings(
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      emailNotifications: emailNotifications ?? this.emailNotifications,
      lessonReminderMinutes: lessonReminderMinutes ?? this.lessonReminderMinutes,
      currency: currency ?? this.currency,
      defaultLessonDuration: defaultLessonDuration ?? this.defaultLessonDuration,
      timezone: timezone ?? this.timezone,
      instructorName: instructorName ?? this.instructorName,
      instructorTitle: instructorTitle ?? this.instructorTitle,
      themeMode: themeMode ?? this.themeMode,
      defaultThemeColor: defaultThemeColor ?? this.defaultThemeColor,
      enableSync: enableSync ?? this.enableSync,
      syncEndpoint: syncEndpoint ?? this.syncEndpoint,
      syncToken: syncToken ?? this.syncToken,
      appVersionSchema: appVersionSchema ?? this.appVersionSchema,
      hourlyRate: hourlyRate ?? this.hourlyRate,
      businessName: businessName ?? this.businessName,
      termsAndConditions: termsAndConditions ?? this.termsAndConditions,
      acceptOnlinePayments: acceptOnlinePayments ?? this.acceptOnlinePayments,
      covidSafetyEnabled: covidSafetyEnabled ?? this.covidSafetyEnabled,
      progressTrackingEnabled: progressTrackingEnabled ?? this.progressTrackingEnabled,
      defaultProgressScale: defaultProgressScale ?? this.defaultProgressScale,
      skillCategories: skillCategories ?? this.skillCategories,
      theoryTestSyncEnabled: theoryTestSyncEnabled ?? this.theoryTestSyncEnabled,
      theoryTestProvider: theoryTestProvider ?? this.theoryTestProvider,
      calendarSyncEnabled: calendarSyncEnabled ?? this.calendarSyncEnabled,
      teachingResources: teachingResources ?? this.teachingResources,
      workHours: workHours ?? this.workHours,
      paymentMethods: paymentMethods ?? this.paymentMethods,
      lessonLengths: lessonLengths ?? this.lessonLengths,
      customPackages: customPackages ?? this.customPackages,
      scoringSystem: scoringSystem ?? this.scoringSystem,
      cancellationPeriod: cancellationPeriod ?? this.cancellationPeriod,
      brandLogoUrl: brandLogoUrl ?? this.brandLogoUrl,
      brandPrimaryColor: brandPrimaryColor ?? this.brandPrimaryColor,
      drivingTestSyncApiKey: drivingTestSyncApiKey ?? this.drivingTestSyncApiKey,
      drivingTestAutoSync: drivingTestAutoSync ?? this.drivingTestAutoSync,
      covidRiskData: covidRiskData ?? this.covidRiskData,
    );
  }

  Map<String, dynamic> toJson() => {
        'notificationsEnabled': notificationsEnabled,
        'emailNotifications': emailNotifications,
        'lessonReminderMinutes': lessonReminderMinutes,
        'currency': currency,
        'defaultLessonDuration': defaultLessonDuration,
        'timezone': timezone,
        'instructorName': instructorName,
        'instructorTitle': instructorTitle,
        'themeMode': themeMode,
        'defaultThemeColor': defaultThemeColor,
        'enableSync': enableSync,
        'syncEndpoint': syncEndpoint,
        'syncToken': syncToken,
        'appVersionSchema': appVersionSchema,
        'hourlyRate': hourlyRate,
        'businessName': businessName,
        'termsAndConditions': termsAndConditions,
        'acceptOnlinePayments': acceptOnlinePayments,
        'covidSafetyEnabled': covidSafetyEnabled,
        'progressTrackingEnabled': progressTrackingEnabled,
        'defaultProgressScale': defaultProgressScale,
        'skillCategories': skillCategories,
        'theoryTestSyncEnabled': theoryTestSyncEnabled,
        'theoryTestProvider': theoryTestProvider,
        'calendarSyncEnabled': calendarSyncEnabled,
        'teachingResources': teachingResources,
        'workHours': workHours,
        'paymentMethods': paymentMethods,
        'lessonLengths': lessonLengths,
        'customPackages': customPackages,
        'scoringSystem': scoringSystem,
        'cancellationPeriod': cancellationPeriod,
        'brandLogoUrl': brandLogoUrl,
        'brandPrimaryColor': brandPrimaryColor,
        'drivingTestSyncApiKey': drivingTestSyncApiKey,
        'drivingTestAutoSync': drivingTestAutoSync,
        'covidRiskData': covidRiskData,
      };

  factory AppSettings.fromJson(Map<String, dynamic> json) => AppSettings(
        notificationsEnabled: json['notificationsEnabled'] as bool? ?? true,
        emailNotifications: json['emailNotifications'] as bool? ?? true,
        lessonReminderMinutes: json['lessonReminderMinutes'] as int? ?? 60,
        currency: json['currency'] as String? ?? 'GBP',
        defaultLessonDuration: json['defaultLessonDuration'] as int? ?? 60,
        timezone: json['timezone'] as String? ?? 'Europe/London',
        instructorName: json['instructorName'] as String? ?? 'Alex Rivers',
        instructorTitle: json['instructorTitle'] as String? ?? 'ADI Instructor',
        themeMode: json['themeMode'] as int? ?? 3,
        defaultThemeColor: json['defaultThemeColor'] as String? ?? '#007AFF',
        enableSync: json['enableSync'] as bool? ?? false,
        syncEndpoint: json['syncEndpoint'] as String?,
        syncToken: json['syncToken'] as String?,
        appVersionSchema: json['appVersionSchema'] as int? ?? 2,
        hourlyRate: (json['hourlyRate'] as num?)?.toDouble() ?? 35.0,
        businessName: json['businessName'] as String? ?? 'Alex Rivers Driving School',
        termsAndConditions: json['termsAndConditions'] as String? ?? 'Standard terms and conditions apply. Cancellations must be made at least 48 hours in advance.',
        acceptOnlinePayments: json['acceptOnlinePayments'] as bool? ?? true,
        covidSafetyEnabled: json['covidSafetyEnabled'] as bool? ?? true,
        progressTrackingEnabled: json['progressTrackingEnabled'] as bool? ?? true,
        defaultProgressScale: json['defaultProgressScale'] as int? ?? 5,
        skillCategories: (json['skillCategories'] as List<dynamic>?)?.cast<String>() ?? const ['Controls', 'Manoeuvres', 'Junctions', 'Road Positioning', 'Planning & Observation'],
        theoryTestSyncEnabled: json['theoryTestSyncEnabled'] as bool? ?? false,
        theoryTestProvider: json['theoryTestProvider'] as String? ?? 'gov.uk',
        calendarSyncEnabled: json['calendarSyncEnabled'] as bool? ?? false,
        teachingResources: (json['teachingResources'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? const [],
        workHours: (json['workHours'] as Map<String, dynamic>?) ?? const {},
        paymentMethods: (json['paymentMethods'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? const [],
        lessonLengths: (json['lessonLengths'] as List<dynamic>?)?.cast<int>() ?? const [30, 45, 60, 90, 120],
        customPackages: (json['customPackages'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? const [],
        scoringSystem: json['scoringSystem'] as String? ?? 'Average',
        cancellationPeriod: json['cancellationPeriod'] as int? ?? 48,
        brandLogoUrl: json['brandLogoUrl'] as String?,
        brandPrimaryColor: json['brandPrimaryColor'] as String?,
        drivingTestSyncApiKey: json['drivingTestSyncApiKey'] as String?,
        drivingTestAutoSync: json['drivingTestAutoSync'] as bool? ?? false,
        covidRiskData: (json['covidRiskData'] as Map<String, dynamic>?) ?? const {},
      );
}

class MileageEntry {
  final String id;
  final double miles;
  final DateTime date;
  final String? notes;

  MileageEntry({
    String? id,
    required this.miles,
    required this.date,
    this.notes,
  }) : id = id ?? _uuid.v4();

  Map<String, dynamic> toJson() => {
        'id': id,
        'miles': miles,
        'date': date.toIso8601String(),
        'notes': notes,
      };

  factory MileageEntry.fromJson(Map<String, dynamic> json) => MileageEntry(
        id: json['id'] as String,
        miles: (json['miles'] as num).toDouble(),
        date: DateTime.parse(json['date'] as String),
        notes: json['notes'] as String?,
      );
}

EnquiryStatus _parseEnquiryStatus(String raw) {
  if (raw == 'new' || raw == 'newEnquiry') return EnquiryStatus.pending;
  return EnquiryStatus.values.byName(raw);
}

String enquiryStatusLabel(EnquiryStatus s) {
  switch (s) {
    case EnquiryStatus.pending:
      return 'Pending';
    case EnquiryStatus.contacted:
      return 'Contacted';
    case EnquiryStatus.interested:
      return 'Interested';
    case EnquiryStatus.notInterested:
      return 'Not interested';
    case EnquiryStatus.converted:
      return 'Converted';
  }
}

class ProgressCategory {
  final String id;
  final String title;
  final String description;
  final int orderIndex;
  final List<ProgressSkill> skills;

  ProgressCategory({
    String? id,
    required this.title,
    this.description = '',
    this.orderIndex = 0,
    this.skills = const [],
  }) : id = id ?? _uuid.v4();

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'orderIndex': orderIndex,
        'skills': skills.map((e) => e.toJson()).toList(),
      };

  factory ProgressCategory.fromJson(Map<String, dynamic> json) => ProgressCategory(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String? ?? '',
        orderIndex: json['orderIndex'] as int? ?? 0,
        skills: (json['skills'] as List? ?? []).map((e) => ProgressSkill.fromJson(e as Map<String, dynamic>)).toList(),
      );
}

class ProgressSkill {
  final String id;
  final String title;
  final String description;
  final int orderIndex;
  final bool requiresIndependentDriving;

  ProgressSkill({
    String? id,
    required this.title,
    this.description = '',
    this.orderIndex = 0,
    this.requiresIndependentDriving = false,
  }) : id = id ?? _uuid.v4();

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'orderIndex': orderIndex,
        'requiresIndependentDriving': requiresIndependentDriving,
      };

  factory ProgressSkill.fromJson(Map<String, dynamic> json) => ProgressSkill(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String? ?? '',
        orderIndex: json['orderIndex'] as int? ?? 0,
        requiresIndependentDriving: json['requiresIndependentDriving'] as bool? ?? false,
      );
}

class RequestPaymentInvoice {
  final String id;
  final String pupilId;
  final String pupilName;
  final double amount;
  final String status;
  final DateTime issuedAt;
  final DateTime dueDate;
  final String? stripePaymentIntentId;

  RequestPaymentInvoice({
    String? id,
    required this.pupilId,
    required this.pupilName,
    required this.amount,
    this.status = 'pending',
    required this.issuedAt,
    required this.dueDate,
    this.stripePaymentIntentId,
  }) : id = id ?? _uuid.v4();

  Map<String, dynamic> toJson() => {
        'id': id,
        'pupilId': pupilId,
        'pupilName': pupilName,
        'amount': amount,
        'status': status,
        'issuedAt': issuedAt.toIso8601String(),
        'dueDate': dueDate.toIso8601String(),
        'stripePaymentIntentId': stripePaymentIntentId,
      };

  factory RequestPaymentInvoice.fromJson(Map<String, dynamic> json) => RequestPaymentInvoice(
        id: json['id'] as String,
        pupilId: json['pupilId'] as String,
        pupilName: json['pupilName'] as String,
        amount: (json['amount'] as num).toDouble(),
        status: json['status'] as String? ?? 'pending',
        issuedAt: DateTime.parse(json['issuedAt'] as String),
        dueDate: DateTime.parse(json['dueDate'] as String),
        stripePaymentIntentId: json['stripePaymentIntentId'] as String?,
      );
}

class Vehicle {
  final String id;
  final String make;
  final String model;
  final String registrationPlate;
  final GearboxType gearbox;
  final DateTime motExpiryDate;
  final DateTime taxExpiryDate;
  final DateTime insuranceExpiryDate;
  final DateTime? lastServiceDate;
  final int currentMileage;

  Vehicle({
    String? id,
    required this.make,
    required this.model,
    required this.registrationPlate,
    this.gearbox = GearboxType.manual,
    required this.motExpiryDate,
    required this.taxExpiryDate,
    required this.insuranceExpiryDate,
    this.lastServiceDate,
    this.currentMileage = 0,
  }) : id = id ?? _uuid.v4();

  Map<String, dynamic> toJson() => {
        'id': id,
        'make': make,
        'model': model,
        'registrationPlate': registrationPlate,
        'gearbox': gearbox.name,
        'motExpiryDate': motExpiryDate.toIso8601String(),
        'taxExpiryDate': taxExpiryDate.toIso8601String(),
        'insuranceExpiryDate': insuranceExpiryDate.toIso8601String(),
        'lastServiceDate': lastServiceDate?.toIso8601String(),
        'currentMileage': currentMileage,
      };

  factory Vehicle.fromJson(Map<String, dynamic> json) => Vehicle(
        id: json['id'] as String,
        make: json['make'] as String,
        model: json['model'] as String,
        registrationPlate: json['registrationPlate'] as String,
        gearbox: GearboxType.values.byName(json['gearbox'] as String? ?? 'manual'),
        motExpiryDate: DateTime.parse(json['motExpiryDate'] as String),
        taxExpiryDate: DateTime.parse(json['taxExpiryDate'] as String),
        insuranceExpiryDate: DateTime.parse(json['insuranceExpiryDate'] as String),
        lastServiceDate: json['lastServiceDate'] != null ? DateTime.parse(json['lastServiceDate'] as String) : null,
        currentMileage: json['currentMileage'] as int? ?? 0,
      );
}

String labelEnum(Enum e) {
  final n = e.name;
  return n
      .replaceAllMapped(RegExp(r'([A-Z])'), (m) => ' ${m.group(0)}')
      .trim()
      .split(' ')
      .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');
}
