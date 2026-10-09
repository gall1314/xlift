// ignore_for_file: unnecessary_getters_setters

import '/backend/schema/util/schema_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class PendingWorkoutStruct extends BaseStruct {
  PendingWorkoutStruct({
    String? id,
    String? name,
    String? userId,
    DateTime? createdAt,
  })  : _id = id,
        _name = name,
        _userId = userId,
        _createdAt = createdAt;

  // "id" field.
  String? _id;
  String get id => _id ?? '';
  set id(String? val) => _id = val;

  bool hasId() => _id != null;

  // "name" field.
  String? _name;
  String get name => _name ?? '';
  set name(String? val) => _name = val;

  bool hasName() => _name != null;

  // "userId" field.
  String? _userId;
  String get userId => _userId ?? '';
  set userId(String? val) => _userId = val;

  bool hasUserId() => _userId != null;

  // "createdAt" field.
  DateTime? _createdAt;
  DateTime? get createdAt => _createdAt;
  set createdAt(DateTime? val) => _createdAt = val;

  bool hasCreatedAt() => _createdAt != null;

  static PendingWorkoutStruct fromMap(Map<String, dynamic> data) =>
      PendingWorkoutStruct(
        id: data['id'] as String?,
        name: data['name'] as String?,
        userId: data['userId'] as String?,
        createdAt: data['createdAt'] as DateTime?,
      );

  static PendingWorkoutStruct? maybeFromMap(dynamic data) => data is Map
      ? PendingWorkoutStruct.fromMap(data.cast<String, dynamic>())
      : null;

  Map<String, dynamic> toMap() => {
        'id': _id,
        'name': _name,
        'userId': _userId,
        'createdAt': _createdAt,
      }.withoutNulls;

  @override
  Map<String, dynamic> toSerializableMap() => {
        'id': serializeParam(
          _id,
          ParamType.String,
        ),
        'name': serializeParam(
          _name,
          ParamType.String,
        ),
        'userId': serializeParam(
          _userId,
          ParamType.String,
        ),
        'createdAt': serializeParam(
          _createdAt,
          ParamType.DateTime,
        ),
      }.withoutNulls;

  static PendingWorkoutStruct fromSerializableMap(Map<String, dynamic> data) =>
      PendingWorkoutStruct(
        id: deserializeParam(
          data['id'],
          ParamType.String,
          false,
        ),
        name: deserializeParam(
          data['name'],
          ParamType.String,
          false,
        ),
        userId: deserializeParam(
          data['userId'],
          ParamType.String,
          false,
        ),
        createdAt: deserializeParam(
          data['createdAt'],
          ParamType.DateTime,
          false,
        ),
      );

  @override
  String toString() => 'PendingWorkoutStruct(${toMap()})';

  @override
  bool operator ==(Object other) {
    return other is PendingWorkoutStruct &&
        id == other.id &&
        name == other.name &&
        userId == other.userId &&
        createdAt == other.createdAt;
  }

  @override
  int get hashCode => const ListEquality().hash([id, name, userId, createdAt]);
}

PendingWorkoutStruct createPendingWorkoutStruct({
  String? id,
  String? name,
  String? userId,
  DateTime? createdAt,
}) =>
    PendingWorkoutStruct(
      id: id,
      name: name,
      userId: userId,
      createdAt: createdAt,
    );
