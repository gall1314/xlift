// ignore_for_file: unnecessary_getters_setters


import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class LandmarksStruct extends BaseStruct {
  LandmarksStruct({
    List<LandmarkStruct>? items,
  }) : _items = items;

  // "items" field.
  List<LandmarkStruct>? _items;
  List<LandmarkStruct> get items => _items ?? const [];
  set items(List<LandmarkStruct>? val) => _items = val;

  void updateItems(Function(List<LandmarkStruct>) updateFn) {
    updateFn(_items ??= []);
  }

  bool hasItems() => _items != null;

  static LandmarksStruct fromMap(Map<String, dynamic> data) => LandmarksStruct(
        items: getStructList(
          data['items'],
          LandmarkStruct.fromMap,
        ),
      );

  static LandmarksStruct? maybeFromMap(dynamic data) => data is Map
      ? LandmarksStruct.fromMap(data.cast<String, dynamic>())
      : null;

  Map<String, dynamic> toMap() => {
        'items': _items?.map((e) => e.toMap()).toList(),
      }.withoutNulls;

  @override
  Map<String, dynamic> toSerializableMap() => {
        'items': serializeParam(
          _items,
          ParamType.DataStruct,
          isList: true,
        ),
      }.withoutNulls;

  static LandmarksStruct fromSerializableMap(Map<String, dynamic> data) =>
      LandmarksStruct(
        items: deserializeStructParam<LandmarkStruct>(
          data['items'],
          ParamType.DataStruct,
          true,
          structBuilder: LandmarkStruct.fromSerializableMap,
        ),
      );

  @override
  String toString() => 'LandmarksStruct(${toMap()})';

  @override
  bool operator ==(Object other) {
    const listEquality = ListEquality();
    return other is LandmarksStruct && listEquality.equals(items, other.items);
  }

  @override
  int get hashCode =>
      const ListEquality().hash([const ListEquality().hash(items)]);
}

LandmarksStruct createLandmarksStruct() => LandmarksStruct();
