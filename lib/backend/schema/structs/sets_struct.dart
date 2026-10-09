// ignore_for_file: unnecessary_getters_setters

import '/backend/schema/util/schema_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class SetsStruct extends BaseStruct {
  SetsStruct({
    int? setnumber,
    int? weight,
    bool? deci,
  })  : _setnumber = setnumber,
        _weight = weight,
        _deci = deci;

  // "setnumber" field.
  int? _setnumber;
  int get setnumber => _setnumber ?? 12;
  set setnumber(int? val) => _setnumber = val;

  void incrementSetnumber(int amount) => setnumber = setnumber + amount;

  bool hasSetnumber() => _setnumber != null;

  // "weight" field.
  int? _weight;
  int get weight => _weight ?? 0;
  set weight(int? val) => _weight = val;

  void incrementWeight(int amount) => weight = weight + amount;

  bool hasWeight() => _weight != null;

  // "deci" field.
  bool? _deci;
  bool get deci => _deci ?? false;
  set deci(bool? val) => _deci = val;

  bool hasDeci() => _deci != null;

  static SetsStruct fromMap(Map<String, dynamic> data) => SetsStruct(
        setnumber: castToType<int>(data['setnumber']),
        weight: castToType<int>(data['weight']),
        deci: data['deci'] as bool?,
      );

  static SetsStruct? maybeFromMap(dynamic data) =>
      data is Map ? SetsStruct.fromMap(data.cast<String, dynamic>()) : null;

  Map<String, dynamic> toMap() => {
        'setnumber': _setnumber,
        'weight': _weight,
        'deci': _deci,
      }.withoutNulls;

  @override
  Map<String, dynamic> toSerializableMap() => {
        'setnumber': serializeParam(
          _setnumber,
          ParamType.int,
        ),
        'weight': serializeParam(
          _weight,
          ParamType.int,
        ),
        'deci': serializeParam(
          _deci,
          ParamType.bool,
        ),
      }.withoutNulls;

  static SetsStruct fromSerializableMap(Map<String, dynamic> data) =>
      SetsStruct(
        setnumber: deserializeParam(
          data['setnumber'],
          ParamType.int,
          false,
        ),
        weight: deserializeParam(
          data['weight'],
          ParamType.int,
          false,
        ),
        deci: deserializeParam(
          data['deci'],
          ParamType.bool,
          false,
        ),
      );

  @override
  String toString() => 'SetsStruct(${toMap()})';

  @override
  bool operator ==(Object other) {
    return other is SetsStruct &&
        setnumber == other.setnumber &&
        weight == other.weight &&
        deci == other.deci;
  }

  @override
  int get hashCode => const ListEquality().hash([setnumber, weight, deci]);
}

SetsStruct createSetsStruct({
  int? setnumber,
  int? weight,
  bool? deci,
}) =>
    SetsStruct(
      setnumber: setnumber,
      weight: weight,
      deci: deci,
    );
