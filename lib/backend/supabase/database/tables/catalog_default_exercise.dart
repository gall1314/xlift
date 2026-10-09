import '../database.dart';

class CatalogDefaultExerciseTable
    extends SupabaseTable<CatalogDefaultExerciseRow> {
  @override
  String get tableName => 'catalog_default_exercise';

  @override
  CatalogDefaultExerciseRow createRow(Map<String, dynamic> data) =>
      CatalogDefaultExerciseRow(data);
}

class CatalogDefaultExerciseRow extends SupabaseDataRow {
  CatalogDefaultExerciseRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => CatalogDefaultExerciseTable();

  int get id => getField<int>('id')!;
  set id(int value) => setField<int>('id', value);

  String? get name => getField<String>('name');
  set name(String? value) => setField<String>('name', value);

  String? get shortDescription => getField<String>('short_description');
  set shortDescription(String? value) =>
      setField<String>('short_description', value);

  String? get longDescription => getField<String>('long_description');
  set longDescription(String? value) =>
      setField<String>('long_description', value);

  String? get targetMuscles => getField<String>('target_muscles');
  set targetMuscles(String? value) => setField<String>('target_muscles', value);

  int? get isBodyweight => getField<int>('is_bodyweight');
  set isBodyweight(int? value) => setField<int>('is_bodyweight', value);

  int? get isTimeBased => getField<int>('is_time_based');
  set isTimeBased(int? value) => setField<int>('is_time_based', value);

  int? get aiFormAnalysis => getField<int>('ai_form_analysis');
  set aiFormAnalysis(int? value) => setField<int>('ai_form_analysis', value);

  String? get exerciseType => getField<String>('exercise_type');
  set exerciseType(String? value) => setField<String>('exercise_type', value);

  String? get equipment => getField<String>('equipment');
  set equipment(String? value) => setField<String>('equipment', value);

  dynamic get stepByStep => getField<dynamic>('step_by_step');
  set stepByStep(dynamic value) => setField<dynamic>('step_by_step', value);

  dynamic get formTips => getField<dynamic>('form_tips');
  set formTips(dynamic value) => setField<dynamic>('form_tips', value);

  String? get video => getField<String>('video');
  set video(String? value) => setField<String>('video', value);

  String? get illustration => getField<String>('illustration');
  set illustration(String? value) => setField<String>('illustration', value);

  String? get noVideoIllustration => getField<String>('no_video_illustration');
  set noVideoIllustration(String? value) =>
      setField<String>('no_video_illustration', value);

  int? get allowsBodyweight => getField<int>('allows_bodyweight');
  set allowsBodyweight(int? value) => setField<int>('allows_bodyweight', value);
}
