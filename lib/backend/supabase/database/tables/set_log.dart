import '../database.dart';

class SetLogTable extends SupabaseTable<SetLogRow> {
  @override
  String get tableName => 'set_log';

  @override
  SetLogRow createRow(Map<String, dynamic> data) => SetLogRow(data);
}

class SetLogRow extends SupabaseDataRow {
  SetLogRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => SetLogTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  DateTime get createdAt => getField<DateTime>('created_at')!;
  set createdAt(DateTime value) => setField<DateTime>('created_at', value);

  int? get setNumber => getField<int>('set_number');
  set setNumber(int? value) => setField<int>('set_number', value);

  int? get reps => getField<int>('reps');
  set reps(int? value) => setField<int>('reps', value);

  double? get weight => getField<double>('weight');
  set weight(double? value) => setField<double>('weight', value);

  String? get workoutLogId => getField<String>('workout_log_id');
  set workoutLogId(String? value) => setField<String>('workout_log_id', value);

  int? get exerciseId => getField<int>('exercise_id');
  set exerciseId(int? value) => setField<int>('exercise_id', value);

  int? get durationSeconds => getField<int>('duration_seconds');
  set durationSeconds(int? value) => setField<int>('duration_seconds', value);

  String? get userId => getField<String>('user_id');
  set userId(String? value) => setField<String>('user_id', value);

  int? get isKg => getField<int>('is_kg');
  set isKg(int? value) => setField<int>('is_kg', value);

  int? get isDropset => getField<int>('is_dropset');
  set isDropset(int? value) => setField<int>('is_dropset', value);

  int? get dropNumber => getField<int>('drop_number');
  set dropNumber(int? value) => setField<int>('drop_number', value);

  int get exerciseSource => getField<int>('exercise_source')!;
  set exerciseSource(int value) => setField<int>('exercise_source', value);

  String? get customExerciseId => getField<String>('custom_exercise_id');
  set customExerciseId(String? value) =>
      setField<String>('custom_exercise_id', value);
}
