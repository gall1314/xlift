import '../database.dart';

class ExerciseMuscleGroupTable extends SupabaseTable<ExerciseMuscleGroupRow> {
  @override
  String get tableName => 'exercise_muscle_group';

  @override
  ExerciseMuscleGroupRow createRow(Map<String, dynamic> data) =>
      ExerciseMuscleGroupRow(data);
}

class ExerciseMuscleGroupRow extends SupabaseDataRow {
  ExerciseMuscleGroupRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => ExerciseMuscleGroupTable();

  int get id => getField<int>('id')!;
  set id(int value) => setField<int>('id', value);

  int? get muscleGroupId => getField<int>('muscle_group_id');
  set muscleGroupId(int? value) => setField<int>('muscle_group_id', value);

  bool? get isPrimary => getField<bool>('is_primary');
  set isPrimary(bool? value) => setField<bool>('is_primary', value);

  int? get exerciseId => getField<int>('exercise_id');
  set exerciseId(int? value) => setField<int>('exercise_id', value);
}
