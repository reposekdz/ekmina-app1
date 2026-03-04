import 'package:json_annotation/json_annotation.dart';

part 'transaction_model.g.dart';

@JsonSerializable()
class TransactionModel {
  final String id;
  final String userId;
  final String membershipId;
  final String groupId;
  final String type;
  final double amount;
  final double shares;
  final String status;
  final String? referenceId;
  final String? description;
  final DateTime createdAt;
  
  TransactionModel({
    required this.id,
    required this.userId,
    required this.membershipId,
    required this.groupId,
    required this.type,
    required this.amount,
    required this.shares,
    required this.status,
    this.referenceId,
    this.description,
    required this.createdAt,
  });
  
  factory TransactionModel.fromJson(Map<String, dynamic> json) => _$TransactionModelFromJson(json);
  Map<String, dynamic> toJson() => _$TransactionModelToJson(this);
}

@JsonSerializable()
class LoanModel {
  final String id;
  final String membershipId;
  final String groupId;
  final double amount;
  final double interest;
  final double totalAmount;
  final double amountPaid;
  final int duration;
  final String status;
  final DateTime requestedAt;
  final DateTime? approvedAt;
  final DateTime? disbursedAt;
  final DateTime dueDate;
  final DateTime? paidAt;
  final int approvalsCount;
  final int guarantorsCount;
  
  LoanModel({
    required this.id,
    required this.membershipId,
    required this.groupId,
    required this.amount,
    required this.interest,
    required this.totalAmount,
    required this.amountPaid,
    required this.duration,
    required this.status,
    required this.requestedAt,
    this.approvedAt,
    this.disbursedAt,
    required this.dueDate,
    this.paidAt,
    required this.approvalsCount,
    required this.guarantorsCount,
  });
  
  factory LoanModel.fromJson(Map<String, dynamic> json) => _$LoanModelFromJson(json);
  Map<String, dynamic> toJson() => _$LoanModelToJson(this);
}

@JsonSerializable()
class NotificationModel {
  final String id;
  final String userId;
  final String title;
  final String message;
  final String type;
  final String category;
  final bool isRead;
  final DateTime createdAt;
  
  NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.type,
    required this.category,
    required this.isRead,
    required this.createdAt,
  });
  
  factory NotificationModel.fromJson(Map<String, dynamic> json) => _$NotificationModelFromJson(json);
  Map<String, dynamic> toJson() => _$NotificationModelToJson(this);
}
