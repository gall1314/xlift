// ignore_for_file: unnecessary_getters_setters

import '/backend/schema/util/schema_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class IntStringStruct extends BaseStruct {
  IntStringStruct({
    int? integer,
    String? string,
  })  : _integer = integer,
        _string = string;

  // "integer" field.
  int? _integer;
  int get integer => _integer ?? 0;
  set integer(int? val) => _integer = val;

  void incrementInteger(int amount) => integer = integer + amount;

  bool hasInteger() => _integer != null;

  // "string" field.
  String? _string;
  String get string => _string ?? '';
  set string(String? val) => _string = val;

  bool hasString() => _string != null;

  static IntStringStruct fromMap(Map<String, dynamic> data) => IntStringStruct(
        integer: castToType<int>(data['integer']),
        string: data['string'] as String?,
      );

  static IntStringStruct? maybeFromMap(dynamic data) => data is Map
      ? IntStringStruct.fromMap(data.cast<String, dynamic>())
      : null;

  Map<String, dynamic> toMap() => {
        'integer': _integer,
        'string': _string,
      }.withoutNulls;

  @override
  Map<String, dynamic> toSerializableMap() => {
        'integer': serializeParam(
          _integer,
          ParamType.int,
        ),
        'string': serializeParam(
          _string,
          ParamType.String,
        ),
      }.withoutNulls;

  static IntStringStruct fromSerializableMap(Map<String, dynamic> data) =>
      IntStringStruct(
        integer: deserializeParam(
          data['integer'],
          ParamType.int,
          false,
        ),
        string: deserializeParam(
          data['string'],
          ParamType.String,
          false,
        ),
      );

  @override
  String toString() => 'IntStringStruct(${toMap()})';

  @override
  bool operator ==(Object other) {
    return other is IntStringStruct &&
        integer == other.integer &&
        string == other.string;
  }

  @override
  int get hashCode => const ListEquality().hash([integer, string]);
}

IntStringStruct createIntStringStruct({
  int? integer,
  String? string,
}) =>
    IntStringStruct(
      integer: integer,
      string: string,
    );
