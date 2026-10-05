import 'package:equatable/equatable.dart';

/// Represents a failed SMS processing attempt that needs to be retried.
///
/// We store raw SMS data because failures can occur before parsing or
/// wallet resolution — the retry pipeline re-runs the full pipeline.
final class PendingSmsRetryItem extends Equatable {
  const PendingSmsRetryItem({
    required this.id,
    required this.sender,
    required this.body,
    required this.smsReceivedAt,
    required this.userUid,
    required this.createdAt,
    required this.updatedAt,
    this.walletId,
    this.providerName,
    this.retryCount = 0,
    this.lastError,
  });

  final String id;
  final String sender;
  final String body;
  final DateTime smsReceivedAt;
  final String userUid;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? walletId;
  final String? providerName;
  final int retryCount;
  final String? lastError;

  /// Convenience factory that creates a retry item with a deterministic queue key.
  static PendingSmsRetryItem create({
    required String sender,
    required String body,
    required DateTime smsReceivedAt,
    required String userUid,
    String? walletId,
    String? providerName,
    String? error,
  }) {
    final s = sender.trim().toLowerCase();
    final b = body.trim();
    final t = smsReceivedAt.millisecondsSinceEpoch;
    final id = '${s}_${b.hashCode}_$t';

    final now = DateTime.now();
    return PendingSmsRetryItem(
      id: id,
      sender: sender,
      body: body,
      smsReceivedAt: smsReceivedAt,
      userUid: userUid,
      createdAt: now,
      updatedAt: now,
      walletId: walletId,
      providerName: providerName,
      lastError: error,
    );
  }

  @override
  List<Object?> get props => [
    id,
    sender,
    body,
    smsReceivedAt,
    userUid,
    createdAt,
    updatedAt,
    walletId,
    providerName,
    retryCount,
    lastError,
  ];

  PendingSmsRetryItem copyWith({
    String? sender,
    String? body,
    DateTime? smsReceivedAt,
    String? userUid,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? walletId,
    String? providerName,
    int? retryCount,
    String? lastError,
  }) {
    return PendingSmsRetryItem(
      id: id,
      sender: sender ?? this.sender,
      body: body ?? this.body,
      smsReceivedAt: smsReceivedAt ?? this.smsReceivedAt,
      userUid: userUid ?? this.userUid,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      walletId: walletId ?? this.walletId,
      providerName: providerName ?? this.providerName,
      retryCount: retryCount ?? this.retryCount,
      lastError: lastError ?? this.lastError,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'sender': sender,
    'body': body,
    'smsReceivedAt': smsReceivedAt.toIso8601String(),
    'userUid': userUid,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'walletId': walletId,
    'providerName': providerName,
    'retryCount': retryCount,
    'lastError': lastError,
  };

  factory PendingSmsRetryItem.fromJson(Map<String, dynamic> json) {
    return PendingSmsRetryItem(
      id: json['id'] as String,
      sender: json['sender'] as String,
      body: json['body'] as String,
      smsReceivedAt: DateTime.parse(json['smsReceivedAt'] as String),
      userUid: json['userUid'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      walletId: json['walletId'] as String?,
      providerName: json['providerName'] as String?,
      retryCount: json['retryCount'] as int? ?? 0,
      lastError: json['lastError'] as String?,
    );
  }
}
