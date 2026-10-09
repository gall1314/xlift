import '../database.dart';

class WorkoutTemplateTable extends SupabaseTable<WorkoutTemplateRow> {
  @override
  String get tableName => 'workout_template';

  @override
  WorkoutTemplateRow createRow(Map<String, dynamic> data) =>
      WorkoutTemplateRow(data);
}

class WorkoutTemplateRow extends SupabaseDataRow {
  WorkoutTemplateRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => WorkoutTemplateTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String get name => getField<String>('name')!;
  set name(String value) => setField<String>('name', value);

  String? get description => getField<String>('description');
  set description(String? value) => setField<String>('description', value);

  int? get estimatedTime => getField<int>('estimated_time');
  set estimatedTime(int? value) => setField<int>('estimated_time', value);

  String? get level => getField<String>('level');
  set level(String? value) => setField<String>('level', value);

  String? get mainMuscles => getField<String>('main_muscles');
  set mainMuscles(String? value) => setField<String>('main_muscles', value);

  String? get thumbnailUrl => getField<String>('thumbnail_url');
  set thumbnailUrl(String? value) => setField<String>('thumbnail_url', value);

  String get workoutId => getField<String>('workout_id')!;
  set workoutId(String value) => setField<String>('workout_id', value);

  String? get recommendation1 => getField<String>('recommendation_1');
  set recommendation1(String? value) =>
      setField<String>('recommendation_1', value);

  String? get recommendation2 => getField<String>('recommendation_2');
  set recommendation2(String? value) =>
      setField<String>('recommendation_2', value);

  String? get recommendation3 => getField<String>('recommendation_3');
  set recommendation3(String? value) =>
      setField<String>('recommendation_3', value);

  String? get recommendation4 => getField<String>('recommendation_4');
  set recommendation4(String? value) =>
      setField<String>('recommendation_4', value);

  String? get recommendation5 => getField<String>('recommendation_5');
  set recommendation5(String? value) =>
      setField<String>('recommendation_5', value);

  String? get recommendation6 => getField<String>('recommendation_6');
  set recommendation6(String? value) =>
      setField<String>('recommendation_6', value);

  String? get recommendation7 => getField<String>('recommendation_7');
  set recommendation7(String? value) =>
      setField<String>('recommendation_7', value);
}
