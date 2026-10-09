import '../database.dart';

class VExerciseWithMusclesTable extends SupabaseTable<VExerciseWithMusclesRow> {
  @override
  String get tableName => 'v_exercise_with_muscles';

  @override
  VExerciseWithMusclesRow createRow(Map<String, dynamic> data) =>
      VExerciseWithMusclesRow(data);
}

class VExerciseWithMusclesRow extends SupabaseDataRow {
  VExerciseWithMusclesRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => VExerciseWithMusclesTable();

  int? get exerciseId => getField<int>('exercise_id');
  set exerciseId(int? value) => setField<int>('exercise_id', value);

  String? get exerciseName => getField<String>('exercise_name');
  set exerciseName(String? value) => setField<String>('exercise_name', value);

  String? get illustration => getField<String>('illustration');
  set illustration(String? value) => setField<String>('illustration', value);

  String? get equipment => getField<String>('equipment');
  set equipment(String? value) => setField<String>('equipment', value);

  String? get exerciseType => getField<String>('exercise_type');
  set exerciseType(String? value) => setField<String>('exercise_type', value);

  String? get primaryMuscle1 => getField<String>('primary_muscle_1');
  set primaryMuscle1(String? value) =>
      setField<String>('primary_muscle_1', value);

  String? get primaryMuscle2 => getField<String>('primary_muscle_2');
  set primaryMuscle2(String? value) =>
      setField<String>('primary_muscle_2', value);

  String? get subMuscle1 => getField<String>('sub_muscle_1');
  set subMuscle1(String? value) => setField<String>('sub_muscle_1', value);

  String? get subMuscle2 => getField<String>('sub_muscle_2');
  set subMuscle2(String? value) => setField<String>('sub_muscle_2', value);

  String? get subMuscle3 => getField<String>('sub_muscle_3');
  set subMuscle3(String? value) => setField<String>('sub_muscle_3', value);
}
