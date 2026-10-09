// ignore_for_file: unnecessary_getters_setters

import '/backend/schema/util/schema_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class SetLogStruct extends BaseStruct {
  SetLogStruct({
    String? id,
    String? workoutLogId,
    int? exerciseId,
    int? setNumber,
    int? reps,
    int? weight,
    int? durationSeconds,
    String? createdAt,
    int? isDirty,
  })  : _id = id,
        _workoutLogId = workoutLogId,
        _exerciseId = exerciseId,
        _setNumber = setNumber,
        _reps = reps,
        _weight = weight,
        _durationSeconds = durationSeconds,
        _createdAt = createdAt,
        _isDirty = isDirty;

  // "id" field.
  String? _id;
  String get id => _id ?? '';
  set id(String? val) => _id = val;

  bool hasId() => _id != null;

  // "workoutLogId" field.
  String? _workoutLogId;
  String get workoutLogId => _workoutLogId ?? '';
  set workoutLogId(String? val) => _workoutLogId = val;

  bool hasWorkoutLogId() => _workoutLogId != null;

  // "exerciseId" field.
  int? _exerciseId;
  int get exerciseId => _exerciseId ?? 0;
  set exerciseId(int? val) => _exerciseId = val;

  void incrementExerciseId(int amount) => exerciseId = exerciseId + amount;

  bool hasExerciseId() => _exerciseId != null;

  // "setNumber" field.
  int? _setNumber;
  int get setNumber => _setNumber ?? 0;
  set setNumber(int? val) => _setNumber = val;

  void incrementSetNumber(int amount) => setNumber = setNumber + amount;

  bool hasSetNumber() => _setNumber != null;

  // "reps" field.
  int? _reps;
  int get reps => _reps ?? 0;
  set reps(int? val) => _reps = val;

  void incrementReps(int amount) => reps = reps + amount;

  bool hasReps() => _reps != null;

  // "weight" field.
  int? _weight;
  int get weight => _weight ?? 0;
  set weight(int? val) => _weight = val;

  void incrementWeight(int amount) => weight = weight + amount;

  bool hasWeight() => _weight != null;

  // "durationSeconds" field.
  int? _durationSeconds;
  int get durationSeconds => _durationSeconds ?? 0;
  set durationSeconds(int? val) => _durationSeconds = val;

  void incrementDurationSeconds(int amount) =>
      durationSeconds = durationSeconds + amount;

  bool hasDurationSeconds() => _durationSeconds != null;

  // "createdAt" field.
  String? _createdAt;
  String get createdAt => _createdAt ?? '';
  set createdAt(String? val) => _createdAt = val;

  bool hasCreatedAt() => _createdAt != null;

  // "isDirty" field.
  int? _isDirty;
  int get isDirty => _isDirty ?? 0;
  set isDirty(int? val) => _isDirty = val;

  void incrementIsDirty(int amount) => isDirty = isDirty + amount;

  bool hasIsDirty() => _isDirty != null;

  static SetLogStruct fromMap(Map<String, dynamic> data) => SetLogStruct(
        id: data['id'] as String?,
        workoutLogId: data['workoutLogId'] as String?,
        exerciseId: castToType<int>(data['exerciseId']),
        setNumber: castToType<int>(data['setNumber']),
        reps: castToType<int>(data['reps']),
        weight: castToType<int>(data['weight']),
        durationSeconds: castToType<int>(data['durationSeconds']),
        createdAt: data['createdAt'] as String?,
        isDirty: castToType<int>(data['isDirty']),
      );

  static SetLogStruct? maybeFromMap(dynamic data) =>
      data is Map ? SetLogStruct.fromMap(data.cast<String, dynamic>()) : null;

  Map<String, dynamic> toMap() => {
        'id': _id,
        'workoutLogId': _workoutLogId,
        'exerciseId': _exerciseId,
        'setNumber': _setNumber,
        'reps': _reps,
        'weight': _weight,
        'durationSeconds': _durationSeconds,
        'createdAt': _createdAt,
        'isDirty': _isDirty,
      }.withoutNulls;

  @override
  Map<String, dynamic> toSerializableMap() => {
        'id': serializeParam(
          _id,
          ParamType.String,
        ),
        'workoutLogId': serializeParam(
          _workoutLogId,
          ParamType.String,
        ),
        'exerciseId': serializeParam(
          _exerciseId,
          ParamType.int,
        ),
        'setNumber': serializeParam(
          _setNumber,
          ParamType.int,
        ),
        'reps': serializeParam(
          _reps,
          ParamType.int,
        ),
        'weight': serializeParam(
          _weight,
          ParamType.int,
        ),
        'durationSeconds': serializeParam(
          _durationSeconds,
          ParamType.int,
        ),
        'createdAt': serializeParam(
          _createdAt,
          ParamType.String,
        ),
        'isDirty': serializeParam(
          _isDirty,
          ParamType.int,
        ),
      }.withoutNulls;

  static SetLogStruct fromSerializableMap(Map<String, dynamic> data) =>
      SetLogStruct(
        id: deserializeParam(
          data['id'],
          ParamType.String,
          false,
        ),
        workoutLogId: deserializeParam(
          data['workoutLogId'],
          ParamType.String,
          false,
        ),
        exerciseId: deserializeParam(
          data['exerciseId'],
          ParamType.int,
          false,
        ),
        setNumber: deserializeParam(
          data['setNumber'],
          ParamType.int,
          false,
        ),
        reps: deserializeParam(
          data['reps'],
          ParamType.int,
          false,
        ),
        weight: deserializeParam(
          data['weight'],
          ParamType.int,
          false,
        ),
        durationSeconds: deserializeParam(
          data['durationSeconds'],
          ParamType.int,
          false,
        ),
        createdAt: deserializeParam(
          data['createdAt'],
          ParamType.String,
          false,
        ),
        isDirty: deserializeParam(
          data['isDirty'],
          ParamType.int,
          false,
        ),
      );

  @override
  String toString() => 'SetLogStruct(${toMap()})';

  @override
  bool operator ==(Object other) {
    return other is SetLogStruct &&
        id == other.id &&
        workoutLogId == other.workoutLogId &&
        exerciseId == other.exerciseId &&
        setNumber == other.setNumber &&
        reps == other.reps &&
        weight == other.weight &&
        durationSeconds == other.durationSeconds &&
        createdAt == other.createdAt &&
        isDirty == other.isDirty;
  }

  @override
  int get hashCode => const ListEquality().hash([
        id,
        workoutLogId,
        exerciseId,
        setNumber,
        reps,
        weight,
        durationSeconds,
        createdAt,
        isDirty
      ]);
}

SetLogStruct createSetLogStruct({
  String? id,
  String? workoutLogId,
  int? exerciseId,
  int? setNumber,
  int? reps,
  int? weight,
  int? durationSeconds,
  String? createdAt,
  int? isDirty,
}) =>
    SetLogStruct(
      id: id,
      workoutLogId: workoutLogId,
      exerciseId: exerciseId,
      setNumber: setNumber,
      reps: reps,
      weight: weight,
      durationSeconds: durationSeconds,
      createdAt: createdAt,
      isDirty: isDirty,
    );
