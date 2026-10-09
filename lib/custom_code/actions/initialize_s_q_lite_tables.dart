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

import 'package:sqflite/sqflite.dart';

Future initializeSQLiteTables() async {
  final db = await SQLiteManager.instance.database;

  // Create exercise table
  await db.execute('''
    CREATE TABLE IF NOT EXISTS exercise (
      id INTEGER PRIMARY KEY,
      name TEXT,
      short_description TEXT,
      long_description TEXT,
      target_muscles TEXT,
      is_bodyweight INTEGER DEFAULT 0,
      is_public INTEGER DEFAULT 1,
      created_by_user_id TEXT,
      ai_form_analysis INTEGER DEFAULT 0,
      is_time_based INTEGER DEFAULT 0,
      video TEXT,
      illustration TEXT,
      no_video_illustration TEXT,
      step_by_step TEXT,
      form_tips TEXT,
      exercise_type TEXT,
      equipment TEXT,
      owner_user_id TEXT,
      is_deleted INTEGER DEFAULT 0
    )
  ''');

  // Create workout_exercise table if it doesn't exist
  await db.execute('''
    CREATE TABLE IF NOT EXISTS workout_exercise (
      id TEXT PRIMARY KEY,
      workout_id TEXT NOT NULL,
      exercise_id INTEGER NOT NULL,
      "order" INTEGER,
      sets INTEGER,
      reps INTEGER,
      created_at TEXT
    )
  ''');

  print('SQLite tables initialized successfully');
}
