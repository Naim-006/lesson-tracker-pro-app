import '../models/models.dart';

/// Maps a Supabase `transactions` or `instructor_payments` row to a [Transaction].
Transaction transactionFromSupabaseMap(
  Map<String, dynamic> m, {
  Map<String, String>? pupilNames,
}) {
  final typeStr = m['type'] as String?;
  final txType = typeStr == 'expense' ? TransactionType.expense : TransactionType.income;

  final paymentMethodStr = m['payment_method'] as String?;
  PaymentMethod? paymentMethod;
  if (paymentMethodStr != null) {
    switch (paymentMethodStr) {
      case 'cash':
        paymentMethod = PaymentMethod.cash;
      case 'card':
        paymentMethod = PaymentMethod.card;
      case 'paypal':
        paymentMethod = PaymentMethod.paypal;
      case 'cheque':
        paymentMethod = PaymentMethod.cheque;
      case 'online':
        paymentMethod = PaymentMethod.online;
      case 'revolut':
        paymentMethod = PaymentMethod.revolut;
      case 'monzo':
        paymentMethod = PaymentMethod.monzo;
      case 'stripe':
        paymentMethod = PaymentMethod.stripe;
      case 'bank_transfer':
        paymentMethod = PaymentMethod.bankTransfer;
      default:
        paymentMethod = PaymentMethod.bankTransfer;
    }
  }

  final paymentTypeStr = m['payment_type'] as String?;
  PaymentType? paymentType;
  if (paymentTypeStr == 'individual') {
    paymentType = PaymentType.individual;
  } else if (paymentTypeStr == 'block') {
    paymentType = PaymentType.block;
  }

  final categoryStr = m['category'] as String?;
  ExpenseCategory? category;
  if (categoryStr != null) {
    switch (categoryStr) {
      case 'accounts':
        category = ExpenseCategory.accounts;
      case 'advertising':
        category = ExpenseCategory.advertising;
      case 'association':
        category = ExpenseCategory.association;
      case 'bank_charges':
        category = ExpenseCategory.bankCharges;
      case 'computer':
        category = ExpenseCategory.computer;
      case 'dvsa_fees':
        category = ExpenseCategory.dvsaFees;
      case 'equipment':
        category = ExpenseCategory.equipment;
      case 'food_drink':
        category = ExpenseCategory.foodDrink;
      case 'franchise_fee':
        category = ExpenseCategory.franchiseFee;
      case 'fuel':
        category = ExpenseCategory.fuel;
      case 'insurance_business':
        category = ExpenseCategory.insuranceBusiness;
      case 'insurance_personal':
        category = ExpenseCategory.insurancePersonal;
      case 'insurance_vehicle':
        category = ExpenseCategory.insuranceVehicle;
      case 'insurance':
        category = ExpenseCategory.insurance;
      case 'maintenance':
        category = ExpenseCategory.maintenance;
      case 'lease':
        category = ExpenseCategory.lease;
      case 'training':
        category = ExpenseCategory.training;
      default:
        category = ExpenseCategory.other;
    }
  }

  final pupilId = m['pupil_id'] as String?;
  final pupilName = m['pupil_name'] as String? ??
      (pupilId != null && pupilNames != null ? pupilNames[pupilId] : null);

  final dateStr = (m['date'] ?? m['payment_date'] ?? m['created_at']) as String;

  return Transaction(
    id: m['id'] as String,
    type: txType,
    amount: (m['amount'] as num).toDouble(),
    date: DateTime.parse(dateStr),
    description: m['description'] as String? ?? 'Payment',
    pupilId: pupilId,
    pupilName: pupilName,
    paymentMethod: paymentMethod,
    paymentType: paymentType,
    category: category,
    isRecurring: m['is_recurring'] as bool? ?? false,
    receiptUrl: m['receipt_url'] as String?,
  );
}
