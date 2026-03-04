class Group {
  final String id;
  final String name;
  final String? description;
  final String province;
  final String district;
  final String sector;
  final String cell;
  final String village;
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

  Group({
    required this.id,
    required this.name,
    this.description,
    required this.province,
    required this.district,
    required this.sector,
    required this.cell,
    required this.village,
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
  });

  factory Group.fromJson(Map<String, dynamic> json) {
    return Group(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      province: json['province'],
      district: json['district'],
      sector: json['sector'],
      cell: json['cell'],
      village: json['village'],
      shareValue: (json['shareValue'] as num).toDouble(),
      joinFee: (json['joinFee'] as num).toDouble(),
      penaltyAmount: (json['penaltyAmount'] as num).toDouble(),
      penaltyType: json['penaltyType'],
      interestRate: (json['interestRate'] as num).toDouble(),
      cycleType: json['cycleType'],
      collectionDay: json['collectionDay'],
      collectionTime: json['collectionTime'],
      approvalThreshold: json['approvalThreshold'],
      isPublic: json['isPublic'],
      inviteCode: json['inviteCode'],
      escrowBalance: (json['escrowBalance'] as num).toDouble(),
      socialFund: (json['socialFund'] as num).toDouble(),
      profitPool: (json['profitPool'] as num).toDouble(),
      status: json['status'],
      memberCount: json['_count']?['members'] ?? 0,
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  String get fullLocation => '$village, $cell, $sector, $district, $province';
}

class Membership {
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
  final Group? group;

  Membership({
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

  factory Membership.fromJson(Map<String, dynamic> json) {
    return Membership(
      id: json['id'],
      userId: json['userId'],
      groupId: json['groupId'],
      role: json['role'],
      status: json['status'],
      totalShares: (json['totalShares'] as num).toDouble(),
      totalDeposits: (json['totalDeposits'] as num).toDouble(),
      totalPenalties: (json['totalPenalties'] as num).toDouble(),
      pendingPenalties: (json['pendingPenalties'] as num).toDouble(),
      joinedAt: DateTime.parse(json['joinedAt']),
      approvedAt: json['approvedAt'] != null ? DateTime.parse(json['approvedAt']) : null,
      group: json['group'] != null ? Group.fromJson(json['group']) : null,
    );
  }

  double get balance => totalShares * (group?.shareValue ?? 0);
}

class Transaction {
  final String id;
  final String type;
  final double amount;
  final double shares;
  final String status;
  final String? description;
  final DateTime createdAt;

  Transaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.shares,
    required this.status,
    this.description,
    required this.createdAt,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'],
      type: json['type'],
      amount: (json['amount'] as num).toDouble(),
      shares: (json['shares'] as num).toDouble(),
      status: json['status'],
      description: json['description'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}

class Loan {
  final String id;
  final double amount;
  final double interest;
  final double totalAmount;
  final double amountPaid;
  final int duration;
  final String status;
  final DateTime requestedAt;
  final DateTime? approvedAt;
  final DateTime dueDate;

  Loan({
    required this.id,
    required this.amount,
    required this.interest,
    required this.totalAmount,
    required this.amountPaid,
    required this.duration,
    required this.status,
    required this.requestedAt,
    this.approvedAt,
    required this.dueDate,
  });

  factory Loan.fromJson(Map<String, dynamic> json) {
    return Loan(
      id: json['id'],
      amount: (json['amount'] as num).toDouble(),
      interest: (json['interest'] as num).toDouble(),
      totalAmount: (json['totalAmount'] as num).toDouble(),
      amountPaid: (json['amountPaid'] as num).toDouble(),
      duration: json['duration'],
      status: json['status'],
      requestedAt: DateTime.parse(json['requestedAt']),
      approvedAt: json['approvedAt'] != null ? DateTime.parse(json['approvedAt']) : null,
      dueDate: DateTime.parse(json['dueDate']),
    );
  }

  double get remainingAmount => totalAmount - amountPaid;
}
