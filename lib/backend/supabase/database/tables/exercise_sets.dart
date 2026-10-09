import '../database.dart';

class ExerciseSetsTable extends SupabaseTable<ExerciseSetsRow> {
  @override
  String get tableName => 'exercise_sets';

  @override
  ExerciseSetsRow createRow(Map<String, dynamic> data) => ExerciseSetsRow(data);
}

class ExerciseSetsRow extends SupabaseDataRow {
  ExerciseSetsRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => ExerciseSetsTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String get workoutExerciseId => getField<String>('workout_exercise_id')!;
  set workoutExerciseId(String value) =>
      setField<String>('workout_exercise_id', value);

  int get orderIndex => getField<int>('order_index')!;
  set orderIndex(int value) => setField<int>('order_index', value);

  String? get targetReps => getField<String>('target_reps');
  set targetReps(String? value) => setField<String>('target_reps', value);

  String? get targetWeight => getField<String>('target_weight');
  set targetWeight(String? value) => setField<String>('target_weight', value);

  bool get isWarmup => getField<bool>('is_warmup')!;
  set isWarmup(bool value) => setField<bool>('is_warmup', value);

  int? get isDropset => getField<int>('is_dropset');
  set isDropset(int? value) => setField<int>('is_dropset', value);
}
