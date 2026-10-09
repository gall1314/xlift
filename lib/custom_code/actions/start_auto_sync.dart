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

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:async';

StreamSubscription? _connectivitySubscription;

Future<void> startAutoSync() async {
  print('🔄 Starting auto-sync listener');

  await _connectivitySubscription?.cancel();

  _connectivitySubscription =
      Connectivity().onConnectivityChanged.listen((result) async {
    print('📡 Connectivity changed: $result');

    if (result.contains(ConnectivityResult.wifi) ||
        result.contains(ConnectivityResult.mobile)) {
      print('✅ Internet detected, attempting sync...');

      try {
        // Sync workouts
        final workoutBox = await Hive.openBox('pendingWorkouts');
        print('📦 Pending workouts: ${workoutBox.length}');

        if (workoutBox.isNotEmpty) {
          final workouts = workoutBox.values.toList();

          for (var i = workouts.length - 1; i >= 0; i--) {
            try {
              print(
                  '⬆️ Syncing workout ${workouts.length - i}/${workouts.length}');

              await SupaFlow.client.from('workout').insert(workouts[i]);

              await workoutBox.deleteAt(i);
              print('✅ Workout synced successfully');
            } catch (e) {
              if (e.toString().contains('duplicate key')) {
                print('⚠️ Workout already exists, removing from queue');
                await workoutBox.deleteAt(i);
              } else {
                print('❌ Workout sync error: $e');
              }
            }
          }
        }

        // Sync workout exercises - LOOP FORWARD TO PRESERVE ORDER
        final exerciseBox = await Hive.openBox('pendingWorkoutExercises');
        print('📦 Pending workout exercises: ${exerciseBox.length}');

        if (exerciseBox.isNotEmpty) {
          final exercises = exerciseBox.values.toList();
          final indicesToDelete = <int>[];

          for (var i = 0; i < exercises.length; i++) {
            try {
              print('⬆️ Syncing exercise ${i + 1}/${exercises.length}');

              await SupaFlow.client
                  .from('workout_exercise')
                  .insert(exercises[i]);

              indicesToDelete.add(i);
              print('✅ Exercise synced successfully');
            } catch (e) {
              if (e.toString().contains('duplicate key')) {
                print('⚠️ Exercise already exists, removing from queue');
                indicesToDelete.add(i);
              } else {
                print('❌ Exercise sync error: $e');
                break; // Stop on real errors
              }
            }
          }

          // Delete synced items in reverse order to preserve indices
          for (var i = indicesToDelete.length - 1; i >= 0; i--) {
            await exerciseBox.deleteAt(indicesToDelete[i]);
          }
        }

        // Sync workout logs
        final logBox = await Hive.openBox('pendingWorkoutLogs');
        print('📦 Pending workout logs: ${logBox.length}');

        if (logBox.isNotEmpty) {
          final logs = logBox.values.toList();
          final indicesToDelete = <int>[];

          for (var i = 0; i < logs.length; i++) {
            try {
              print('⬆️ Syncing log ${i + 1}/${logs.length}');

              await SupaFlow.client.from('workout_log').insert(logs[i]);

              indicesToDelete.add(i);
              print('✅ Log synced successfully');
            } catch (e) {
              if (e.toString().contains('duplicate key')) {
                print('⚠️ Log already exists, removing from queue');
                indicesToDelete.add(i);
              } else {
                print('❌ Log sync error: $e');
                break;
              }
            }
          }

          // Delete synced items in reverse order
          for (var i = indicesToDelete.length - 1; i >= 0; i--) {
            await logBox.deleteAt(indicesToDelete[i]);
          }
        }

        // Sync set logs
        final setLogBox = await Hive.openBox('pendingSetLogs');
        print('📦 Pending set logs: ${setLogBox.length}');

        if (setLogBox.isNotEmpty) {
          final setLogs = setLogBox.values.toList();
          final indicesToDelete = <int>[];

          for (var i = 0; i < setLogs.length; i++) {
            try {
              print('⬆️ Syncing set log ${i + 1}/${setLogs.length}');

              await SupaFlow.client.from('set_log').insert(setLogs[i]);

              indicesToDelete.add(i);
              print('✅ Set log synced successfully');
            } catch (e) {
              if (e.toString().contains('duplicate key')) {
                print('⚠️ Set log already exists, removing from queue');
                indicesToDelete.add(i);
              } else {
                print('❌ Set log sync error: $e');
                break;
              }
            }
          }

          // Delete synced items in reveהrse order
          for (var i = indicesToDelete.length - 1; i >= 0; i--) {
            await setLogBox.deleteAt(indicesToDelete[i]);
          }
        }

        print('🎉 All data synced!');
      } catch (e) {
        print('❌ Sync error: $e');
      }
    }
  });
}
