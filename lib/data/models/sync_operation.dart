import 'dart:convert';
import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';

enum SyncStatus {
  pending,
  syncing,
  failed,
  completed,
}

/// Représente une opération de mutation en attente de synchronisation
class SyncOperation extends Equatable {
  final String id;
  final String endpoint;
  final String method;
  final Map<String, dynamic>? payload;
  final Map<String, String>? headers;
  final DateTime createdAt;
  final int retryCount;
  final SyncStatus status;
  final String? error;
  final String? description;

  const SyncOperation({
    required this.id,
    required this.endpoint,
    required this.method,
    this.payload,
    this.headers,
    required this.createdAt,
    this.retryCount = 0,
    this.status = SyncStatus.pending,
    this.error,
    this.description,
  });

  factory SyncOperation.create({
    required String endpoint,
    required String method,
    Map<String, dynamic>? payload,
    Map<String, String>? headers,
    String? description,
  }) {
    return SyncOperation(
      id: const Uuid().v4(),
      endpoint: endpoint,
      method: method.toUpperCase(),
      payload: payload,
      headers: headers,
      createdAt: DateTime.now(),
      retryCount: 0,
      status: SyncStatus.pending,
      description: description,
    );
  }

  SyncOperation copyWith({
    String? id,
    String? endpoint,
    String? method,
    Map<String, dynamic>? payload,
    Map<String, String>? headers,
    DateTime? createdAt,
    int? retryCount,
    SyncStatus? status,
    String? error,
    String? description,
  }) {
    return SyncOperation(
      id: id ?? this.id,
      endpoint: endpoint ?? this.endpoint,
      method: method ?? this.method,
      payload: payload ?? this.payload,
      headers: headers ?? this.headers,
      createdAt: createdAt ?? this.createdAt,
      retryCount: retryCount ?? this.retryCount,
      status: status ?? this.status,
      error: error ?? this.error,
      description: description ?? this.description,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'endpoint': endpoint,
      'method': method,
      'payload': payload != null ? jsonEncode(payload) : null,
      'headers': headers != null ? jsonEncode(headers) : null,
      'createdAt': createdAt.toIso8601String(),
      'retryCount': retryCount,
      'status': status.name,
      'error': error,
      'description': description,
    };
  }

  factory SyncOperation.fromMap(Map<String, dynamic> map) {
    Map<String, dynamic>? parsedPayload;
    if (map['payload'] != null) {
      if (map['payload'] is String) {
        try {
          parsedPayload = jsonDecode(map['payload'] as String) as Map<String, dynamic>;
        } catch (_) {
          parsedPayload = null;
        }
      } else if (map['payload'] is Map) {
        parsedPayload = Map<String, dynamic>.from(map['payload'] as Map);
      }
    }

    Map<String, String>? parsedHeaders;
    if (map['headers'] != null) {
      if (map['headers'] is String) {
        try {
          final decoded = jsonDecode(map['headers'] as String) as Map<String, dynamic>;
          parsedHeaders = decoded.map((k, v) => MapEntry(k, v.toString()));
        } catch (_) {
          parsedHeaders = null;
        }
      } else if (map['headers'] is Map) {
        parsedHeaders = (map['headers'] as Map).map((k, v) => MapEntry(k.toString(), v.toString()));
      }
    }

    SyncStatus parseStatus(String? val) {
      switch (val) {
        case 'syncing':
          return SyncStatus.syncing;
        case 'failed':
          return SyncStatus.failed;
        case 'completed':
          return SyncStatus.completed;
        case 'pending':
        default:
          return SyncStatus.pending;
      }
    }

    return SyncOperation(
      id: map['id']?.toString() ?? const Uuid().v4(),
      endpoint: map['endpoint']?.toString() ?? '',
      method: (map['method']?.toString() ?? 'POST').toUpperCase(),
      payload: parsedPayload,
      headers: parsedHeaders,
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      retryCount: map['retryCount'] is int ? map['retryCount'] as int : 0,
      status: parseStatus(map['status']?.toString()),
      error: map['error']?.toString(),
      description: map['description']?.toString(),
    );
  }

  @override
  List<Object?> get props => [
        id,
        endpoint,
        method,
        payload,
        headers,
        createdAt,
        retryCount,
        status,
        error,
        description,
      ];
}
