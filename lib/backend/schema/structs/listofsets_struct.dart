// ignore_for_file: unnecessary_getters_setters


import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class ListofsetsStruct extends BaseStruct {
  ListofsetsStruct({
    String? exerciseid,
    List<SetsStruct>? set,
  })  : _exerciseid = exerciseid,
        _set = set;

  // "exerciseid" field.
  String? _exerciseid;
  String get exerciseid => _exerciseid ?? '';
  set exerciseid(String? val) => _exerciseid = val;

  bool hasExerciseid() => _exerciseid != null;

  // "set" field.
  List<SetsStruct>? _set;
  List<SetsStruct> get set => _set ?? const [];
  set set(List<SetsStruct>? val) => _set = val;

  void updateSet(Function(List<SetsStruct>) updateFn) {
    updateFn(_set ??= []);
  }

  bool hasSet() => _set != null;

  static ListofsetsStruct fromMap(Map<String, dynamic> data) =>
      ListofsetsStruct(
        exerciseid: data['exerciseid'] as String?,
        set: getStructList(
          data['set'],
          SetsStruct.fromMap,
        ),
      );

  static ListofsetsStruct? maybeFromMap(dynamic data) => data is Map
      ? ListofsetsStruct.fromMap(data.cast<String, dynamic>())
      : null;

  Map<String, dynamic> toMap() => {
        'exerciseid': _exerciseid,
        'set': _set?.map((e) => e.toMap()).toList(),
      }.withoutNulls;

  @override
  Map<String, dynamic> toSerializableMap() => {
        'exerciseid': serializeParam(
          _exerciseid,
          ParamType.String,
        ),
        'set': serializeParam(
          _set,
          ParamType.DataStruct,
          isList: true,
        ),
      }.withoutNulls;

  static ListofsetsStruct fromSerializableMap(Map<String, dynamic> data) =>
      ListofsetsStruct(
        exerciseid: deserializeParam(
          data['exerciseid'],
          ParamType.String,
          false,
        ),
        set: deserializeStructParam<SetsStruct>(
          data['set'],
          ParamType.DataStruct,
          true,
          structBuilder: SetsStruct.fromSerializableMap,
        ),
      );

  @override
  String toString() => 'ListofsetsStruct(${toMap()})';

  @override
  bool operator ==(Object other) {
    const listEquality = ListEquality();
    return other is ListofsetsStruct &&
        exerciseid == other.exerciseid &&
        listEquality.equals(set, other.set);
  }

  @override
  int get hashCode =>
      const ListEquality().hash([exerciseid, const ListEquality().hash(set)]);
}

ListofsetsStruct createListofsetsStruct({
  String? exerciseid,
}) =>
    ListofsetsStruct(
      exerciseid: exerciseid,
    );
