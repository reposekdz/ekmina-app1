import 'package:json_annotation/json_annotation.dart';

part 'group_model.g.dart';

@JsonSerializable()
class GroupModel {
  final String id;
  final String name;
  final String? description;
  final double shareValue;
  final double joinFee;
  final double penaltyAmount;
  final String penaltyType;
  final double interestRate;
  final String cycleType;
  final int? collectionDay;
  final String collectionTime;
  final int approvalThreshold;
  final bool isPublic;
  final String inviteCode;
  final double escrowBalance;
  final double socialFund;
  final double profitPool;
  final String status;
  final int memberCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  GroupModel({
    required this.id,
    required this.name,
    this.description,
    required this.shareValue,
    required this.joinFee,
    required this.penaltyAmount,
    required this.penaltyType,
    required this.interestRate,
    required this.cycleType,
    this.collectionDay,
    required this.collectionTime,
    required this.approvalThreshold,
    required this.isPublic,
    required this.inviteCode,
    required this.escrowBalance,
    required this.socialFund,
    required this.profitPool,
    required this.status,
    required this.memberCount,
    required this.createdAt,
    required this.updatedAt,
  });
  
  factory GroupModel.fromJson(Map<String, dynamic> json) => _$GroupModelFromJson(json);
  Map<String, dynamic> toJson() => _$GroupModelToJson(this);
}

@JsonSerializable()
class MembershipModel {
  final String id;
  final String userId;
  final String groupId;
  final String role;
  final String status;
  final double totalShares;
  final double totalDeposits;
  final double totalPenalties;
  final double pendingPenalties;
  final DateTime joinedAt;
  final DateTime? approvedAt;
  final GroupModel? group;
  
  MembershipModel({
    required this.id,
    required this.userId,
    required this.groupId,
    required this.role,
    required this.status,
    required this.totalShares,
    required this.totalDeposits,
    required this.totalPenalties,
    required this.pendingPenalties,
    required this.joinedAt,
    this.approvedAt,
    this.group,
  });
  
  factory MembershipModel.fromJson(Map<String, dynamic> json) => _$MembershipModelFromJson(json);
  Map<String, dynamic> toJson() => _$MembershipModelToJson(this);
}
