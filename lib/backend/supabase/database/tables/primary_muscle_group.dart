import '../database.dart';

class PrimaryMuscleGroupTable extends SupabaseTable<PrimaryMuscleGroupRow> {
  @override
  String get tableName => 'primary_muscle_group';

  @override
  PrimaryMuscleGroupRow createRow(Map<String, dynamic> data) =>
      PrimaryMuscleGroupRow(data);
}

class PrimaryMuscleGroupRow extends SupabaseDataRow {
  PrimaryMuscleGroupRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => PrimaryMuscleGroupTable();

  int get id => getField<int>('id')!;
  set id(int value) => setField<int>('id', value);

  String get name => getField<String>('name')!;
  set name(String value) => setField<String>('name', value);

  String? get illustration => getField<String>('illustration');
  set illustration(String? value) => setField<String>('illustration', value);
}
