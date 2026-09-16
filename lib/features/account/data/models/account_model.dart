import 'package:flutter_clean_boilerplate/features/account/domain/entities/account.dart';

/// Persistence-shaped counterpart of [Account].
///
/// Keeping this separate from the domain entity means the on-disk shape
/// (map keys, date encoding) can evolve - e.g. a future migration - without
/// touching domain or presentation code.
class AccountModel {
  const AccountModel({
    required this.id,
    required this.name,
    required this.email,
    required this.createdAt,
    required this.updatedAt,
    this.avatarPath,
  });

  final String id;
  final String name;
  final String email;
  final String? avatarPath;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory AccountModel.fromEntity(Account account) => AccountModel(
        id: account.id,
        name: account.name,
        email: account.email,
        avatarPath: account.avatarPath,
        createdAt: account.createdAt,
        updatedAt: account.updatedAt,
      );

  Account toEntity() => Account(
        id: id,
        name: name,
        email: email,
        avatarPath: avatarPath,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

  factory AccountModel.fromMap(String id, Map<String, Object?> map) {
    return AccountModel(
      id: id,
      name: map['name'] as String,
      email: map['email'] as String,
      avatarPath: map['avatarPath'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }

  Map<String, Object?> toMap() => {
        'name': name,
        'email': email,
        'avatarPath': avatarPath,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };
}
