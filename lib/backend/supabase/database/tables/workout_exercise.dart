import '../database.dart';

class WorkoutExerciseTable extends SupabaseTable<WorkoutExerciseRow> {
  @override
  String get tableName => 'workout_exercise';

  @override
  WorkoutExerciseRow createRow(Map<String, dynamic> data) =>
      WorkoutExerciseRow(data);
}

class WorkoutExerciseRow extends SupabaseDataRow {
  WorkoutExerciseRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => WorkoutExerciseTable();

  DateTime get createdAt => getField<DateTime>('created_at')!;
  set createdAt(DateTime value) => setField<DateTime>('created_at', value);

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String? get workoutId => getField<String>('workout_id');
  set workoutId(String? value) => setField<String>('workout_id', value);

  int? get order => getField<int>('order');
  set order(int? value) => setField<int>('order', value);

  int? get exerciseId => getField<int>('exercise_id');
  set exerciseId(int? value) => setField<int>('exercise_id', value);

  String? get exerciseName => getField<String>('exercise_name');
  set exerciseName(String? value) => setField<String>('exercise_name', value);

  String? get userId => getField<String>('user_id');
  set userId(String? value) => setField<String>('user_id', value);

  int? get restSeconds => getField<int>('rest_seconds');
  set restSeconds(int? value) => setField<int>('rest_seconds', value);

  String? get notes => getField<String>('notes');
  set notes(String? value) => setField<String>('notes', value);
}
