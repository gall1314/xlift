// Automatic FlutterFlow imports
import '/backend/schema/structs/index.dart';
import '/backend/supabase/supabase.dart';
import '/backend/sqlite/sqlite_manager.dart';
import '/actions/actions.dart' as action_blocks;
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom actions
import '/flutter_flow/custom_functions.dart'; // Imports custom functions
import 'package:flutter/material.dart' hide RepeatMode;
// Begin custom action code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

List<dynamic> updateSetAnalyzedVideo(
  List<dynamic> analysisList,
  int exerciseId,
  int setNumber,
  String videoPath,
) {
  final updatedList = List<dynamic>.from(analysisList);

  final exerciseIndex =
      updatedList.indexWhere((e) => e['exerciseId'] == exerciseId);

  if (exerciseIndex == -1) return updatedList;

  final exercise = Map<String, dynamic>.from(updatedList[exerciseIndex]);
  final sets = List<dynamic>.from(exercise['sets'] ?? []);

  final setIndex = sets.indexWhere((s) => s['setNumber'] == setNumber);

  if (setIndex == -1) return updatedList;

  final updatedSet = Map<String, dynamic>.from(sets[setIndex]);

  // כאן אנחנו מכניסים בדיוק את video_path מה-Python
  updatedSet['analyzedVideoUrl'] = videoPath;

  sets[setIndex] = updatedSet;
  exercise['sets'] = sets;
  updatedList[exerciseIndex] = exercise;

  return updatedList;
}

// Set your action name, define your arguments and return parameter,
// and then add the boilerplate code using the green button on the right!
