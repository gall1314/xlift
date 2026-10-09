// ignore_for_file: unnecessary_getters_setters

import '/backend/schema/util/schema_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class LandmarkStruct extends BaseStruct {
  LandmarkStruct({
    double? xValue,
    double? yValue,
    double? zValue,
    double? score,
  })  : _xValue = xValue,
        _yValue = yValue,
        _zValue = zValue,
        _score = score;

  // "xValue" field.
  double? _xValue;
  double get xValue => _xValue ?? 0.0;
  set xValue(double? val) => _xValue = val;

  void incrementXValue(double amount) => xValue = xValue + amount;

  bool hasXValue() => _xValue != null;

  // "yValue" field.
  double? _yValue;
  double get yValue => _yValue ?? 0.0;
  set yValue(double? val) => _yValue = val;

  void incrementYValue(double amount) => yValue = yValue + amount;

  bool hasYValue() => _yValue != null;

  // "zValue" field.
  double? _zValue;
  double get zValue => _zValue ?? 0.0;
  set zValue(double? val) => _zValue = val;

  void incrementZValue(double amount) => zValue = zValue + amount;

  bool hasZValue() => _zValue != null;

  // "score" field.
  double? _score;
  double get score => _score ?? 0.0;
  set score(double? val) => _score = val;

  void incrementScore(double amount) => score = score + amount;

  bool hasScore() => _score != null;

  static LandmarkStruct fromMap(Map<String, dynamic> data) => LandmarkStruct(
        xValue: castToType<double>(data['xValue']),
        yValue: castToType<double>(data['yValue']),
        zValue: castToType<double>(data['zValue']),
        score: castToType<double>(data['score']),
      );

  static LandmarkStruct? maybeFromMap(dynamic data) =>
      data is Map ? LandmarkStruct.fromMap(data.cast<String, dynamic>()) : null;

  Map<String, dynamic> toMap() => {
        'xValue': _xValue,
        'yValue': _yValue,
        'zValue': _zValue,
        'score': _score,
      }.withoutNulls;

  @override
  Map<String, dynamic> toSerializableMap() => {
        'xValue': serializeParam(
          _xValue,
          ParamType.double,
        ),
        'yValue': serializeParam(
          _yValue,
          ParamType.double,
        ),
        'zValue': serializeParam(
          _zValue,
          ParamType.double,
        ),
        'score': serializeParam(
          _score,
          ParamType.double,
        ),
      }.withoutNulls;

  static LandmarkStruct fromSerializableMap(Map<String, dynamic> data) =>
      LandmarkStruct(
        xValue: deserializeParam(
          data['xValue'],
          ParamType.double,
          false,
        ),
        yValue: deserializeParam(
          data['yValue'],
          ParamType.double,
          false,
        ),
        zValue: deserializeParam(
          data['zValue'],
          ParamType.double,
          false,
        ),
        score: deserializeParam(
          data['score'],
          ParamType.double,
          false,
        ),
      );

  @override
  String toString() => 'LandmarkStruct(${toMap()})';

  @override
  bool operator ==(Object other) {
    return other is LandmarkStruct &&
        xValue == other.xValue &&
        yValue == other.yValue &&
        zValue == other.zValue &&
        score == other.score;
  }

  @override
  int get hashCode =>
      const ListEquality().hash([xValue, yValue, zValue, score]);
}

LandmarkStruct createLandmarkStruct({
  double? xValue,
  double? yValue,
  double? zValue,
  double? score,
}) =>
    LandmarkStruct(
      xValue: xValue,
      yValue: yValue,
      zValue: zValue,
      score: score,
    );
