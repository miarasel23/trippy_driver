import 'package_details_model.dart';
import 'transaction_model.dart';

class AccountResponseModel {
  final bool status;
  final String message;
  final PackageDetailsModel? activePackageDetails;
  final double currentBalance;
  final double dueBalance;
  final double totalEarning;
  final List<TransactionModel> transactions;

  AccountResponseModel({
    required this.status,
    required this.message,
    this.activePackageDetails,
    required this.currentBalance,
    required this.dueBalance,
    required this.totalEarning,
    required this.transactions,
  });

  factory AccountResponseModel.fromJson(Map<String, dynamic> json) {
    PackageDetailsModel? packageDetails;
    if (json['active_pacage_details'] != null) {
      packageDetails = PackageDetailsModel.fromJson(json['active_pacage_details']);
    }

    List<TransactionModel> transactionList = [];
    if (json['data'] != null && json['data'] is List) {
      transactionList = (json['data'] as List)
          .map((item) => TransactionModel.fromJson(item))
          .toList();
    }

    return AccountResponseModel(
      status: json['status'] ?? false,
      message: json['message']?.toString() ?? '',
      activePackageDetails: packageDetails,
      currentBalance: double.tryParse(json['current_blanc']?.toString() ?? '0') ?? 0.0,
      dueBalance: double.tryParse(json['due_blanc']?.toString() ?? '0') ?? 0.0,
      totalEarning: double.tryParse(json['total_earning']?.toString() ?? '0') ?? 0.0,
      transactions: transactionList,
    );
  }
}
