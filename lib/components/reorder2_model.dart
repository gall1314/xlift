import '/flutter_flow/flutter_flow_util.dart';
import 'reorder2_widget.dart' show Reorder2Widget;
import 'package:flutter/material.dart';

class Reorder2Model extends FlutterFlowModel<Reorder2Widget> {
  ///  Local state fields for this component.

  List<dynamic> ordered = [];
  void addToOrdered(dynamic item) => ordered.add(item);
  void removeFromOrdered(dynamic item) => ordered.remove(item);
  void removeAtIndexFromOrdered(int index) => ordered.removeAt(index);
  void insertAtIndexInOrdered(int index, dynamic item) =>
      ordered.insert(index, item);
  void updateOrderedAtIndex(int index, Function(dynamic) updateFn) =>
      ordered[index] = updateFn(ordered[index]);

  ///  State fields for stateful widgets in this component.

  // Stores action output result for [Custom Action - moveExerciseInList] action in IconButton widget.
  List<dynamic>? downCopy;
  // Stores action output result for [Custom Action - moveExerciseInList] action in IconButton widget.
  List<dynamic>? up;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {}
}
