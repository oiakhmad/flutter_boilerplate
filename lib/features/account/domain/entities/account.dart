import 'package:equatable/equatable.dart';

/// The Account domain entity.
///
/// Pure Dart, no Flutter/Sembast imports - this is what the rest of the
/// domain and presentation layers work with. [AccountModel] in the data
/// layer is the persistence-shaped counterpart of this class.
class Account extends Equatable {
  const Account({
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

  Account copyWith({
    String? name,
    String? email,
    String? avatarPath,
    DateTime? updatedAt,
  }) {
    return Account(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      avatarPath: avatarPath ?? this.avatarPath,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [id, name, email, avatarPath, createdAt, updatedAt];
}
