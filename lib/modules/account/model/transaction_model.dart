class TransactionModel {
  final String uuid;
  final double debit;
  final double credit;
  final double mainBalance;
  final double bounceDebit;
  final double bounceCredit;
  final double bounceMainBalance;
  final String description;
  final String createdAt;

  TransactionModel({
    required this.uuid,
    required this.debit,
    required this.credit,
    required this.mainBalance,
    required this.bounceDebit,
    required this.bounceCredit,
    required this.bounceMainBalance,
    required this.description,
    required this.createdAt,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      uuid: json['uuid']?.toString() ?? '',
      debit: double.tryParse(json['debit']?.toString() ?? '0') ?? 0.0,
      credit: double.tryParse(json['credit']?.toString() ?? '0') ?? 0.0,
      mainBalance: double.tryParse(json['main_balance']?.toString() ?? '0') ?? 0.0,
      bounceDebit: double.tryParse(json['bounce_debit']?.toString() ?? '0') ?? 0.0,
      bounceCredit: double.tryParse(json['bounce_credit']?.toString() ?? '0') ?? 0.0,
      bounceMainBalance: double.tryParse(json['bounce_main_balance']?.toString() ?? '0') ?? 0.0,
      description: json['description']?.toString() ?? '',
      createdAt: json['created_at']?.toString() ?? '',
    );
  }
}
