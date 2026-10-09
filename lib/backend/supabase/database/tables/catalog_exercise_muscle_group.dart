import '../database.dart';

class CatalogExerciseMuscleGroupTable
    extends SupabaseTable<CatalogExerciseMuscleGroupRow> {
  @override
  String get tableName => 'catalog_exercise_muscle_group';

  @override
  CatalogExerciseMuscleGroupRow createRow(Map<String, dynamic> data) =>
      CatalogExerciseMuscleGroupRow(data);
}

class CatalogExerciseMuscleGroupRow extends SupabaseDataRow {
  CatalogExerciseMuscleGroupRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => CatalogExerciseMuscleGroupTable();

  int get id => getField<int>('id')!;
  set id(int value) => setField<int>('id', value);

  int? get muscleGroupId => getField<int>('muscle_group_id');
  set muscleGroupId(int? value) => setField<int>('muscle_group_id', value);

  bool? get isPrimary => getField<bool>('is_primary');
  set isPrimary(bool? value) => setField<bool>('is_primary', value);

  int? get exerciseId => getField<int>('exercise_id');
  set exerciseId(int? value) => setField<int>('exercise_id', value);
}
