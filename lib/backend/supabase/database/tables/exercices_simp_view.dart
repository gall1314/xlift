import '../database.dart';

class ExercicesSimpViewTable extends SupabaseTable<ExercicesSimpViewRow> {
  @override
  String get tableName => 'exercices_simp_view';

  @override
  ExercicesSimpViewRow createRow(Map<String, dynamic> data) =>
      ExercicesSimpViewRow(data);
}

class ExercicesSimpViewRow extends SupabaseDataRow {
  ExercicesSimpViewRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => ExercicesSimpViewTable();

  String? get id => getField<String>('id');
  set id(String? value) => setField<String>('id', value);

  int? get exerciseId => getField<int>('exercise_id');
  set exerciseId(int? value) => setField<int>('exercise_id', value);

  int? get order => getField<int>('order');
  set order(int? value) => setField<int>('order', value);

  String? get exerciseName => getField<String>('exercise_name');
  set exerciseName(String? value) => setField<String>('exercise_name', value);

  int? get isBodyweight => getField<int>('is_bodyweight');
  set isBodyweight(int? value) => setField<int>('is_bodyweight', value);

  int? get weightedDefault => getField<int>('weighted_default');
  set weightedDefault(int? value) => setField<int>('weighted_default', value);
}
