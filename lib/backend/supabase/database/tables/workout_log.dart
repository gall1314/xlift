import '../database.dart';

class WorkoutLogTable extends SupabaseTable<WorkoutLogRow> {
  @override
  String get tableName => 'workout_log';

  @override
  WorkoutLogRow createRow(Map<String, dynamic> data) => WorkoutLogRow(data);
}

class WorkoutLogRow extends SupabaseDataRow {
  WorkoutLogRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => WorkoutLogTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  DateTime get createdAt => getField<DateTime>('created_at')!;
  set createdAt(DateTime value) => setField<DateTime>('created_at', value);

  String? get duration => getField<String>('duration');
  set duration(String? value) => setField<String>('duration', value);

  String? get workoutId => getField<String>('workout_id');
  set workoutId(String? value) => setField<String>('workout_id', value);

  int? get volume => getField<int>('volume');
  set volume(int? value) => setField<int>('volume', value);

  String? get userId => getField<String>('user_id');
  set userId(String? value) => setField<String>('user_id', value);
}
