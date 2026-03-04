import 'package:json_annotation/json_annotation.dart';

part 'wallet_model.g.dart';

@JsonSerializable()
class WalletModel {
  final double balance;
  final List<WalletTransaction> transactions;

  WalletModel({
    required this.balance,
    required this.transactions,
  });

  factory WalletModel.fromJson(Map<String, dynamic> json) => _$WalletModelFromJson(json);
  Map<String, dynamic> toJson() => _$WalletModelToJson(this);
}

@JsonSerializable()
class WalletTransaction {
  final String id;
  final String userId;
  final String type;
  final double amount;
  final double balanceBefore;
  final double balanceAfter;
  final String status;
  final String? referenceId;
  final String? description;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;

  WalletTransaction({
    required this.id,
    required this.userId,
    required this.type,
    required this.amount,
    required this.balanceBefore,
    required this.balanceAfter,
    required this.status,
    this.referenceId,
    this.description,
    this.metadata,
    required this.createdAt,
  });

  factory WalletTransaction.fromJson(Map<String, dynamic> json) => _$WalletTransactionFromJson(json);
  Map<String, dynamic> toJson() => _$WalletTransactionToJson(this);
}
