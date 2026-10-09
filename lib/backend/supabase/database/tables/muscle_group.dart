import '../database.dart';

class MuscleGroupTable extends SupabaseTable<MuscleGroupRow> {
  @override
  String get tableName => 'muscle_group';

  @override
  MuscleGroupRow createRow(Map<String, dynamic> data) => MuscleGroupRow(data);
}

class MuscleGroupRow extends SupabaseDataRow {
  MuscleGroupRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => MuscleGroupTable();

  int get id => getField<int>('id')!;
  set id(int value) => setField<int>('id', value);

  String? get name => getField<String>('name');
  set name(String? value) => setField<String>('name', value);

  String? get color => getField<String>('color');
  set color(String? value) => setField<String>('color', value);

  String? get imageUrl => getField<String>('image_url');
  set imageUrl(String? value) => setField<String>('image_url', value);

  int? get primaryMuscleGroupId => getField<int>('primary_muscle_group_id');
  set primaryMuscleGroupId(int? value) =>
      setField<int>('primary_muscle_group_id', value);
}
