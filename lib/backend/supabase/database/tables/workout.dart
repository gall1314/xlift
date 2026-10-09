import '../database.dart';

class WorkoutTable extends SupabaseTable<WorkoutRow> {
  @override
  String get tableName => 'workout';

  @override
  WorkoutRow createRow(Map<String, dynamic> data) => WorkoutRow(data);
}

class WorkoutRow extends SupabaseDataRow {
  WorkoutRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => WorkoutTable();

  DateTime get createdAt => getField<DateTime>('created_at')!;
  set createdAt(DateTime value) => setField<DateTime>('created_at', value);

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String? get name => getField<String>('name');
  set name(String? value) => setField<String>('name', value);

  String? get userId => getField<String>('user_id');
  set userId(String? value) => setField<String>('user_id', value);

  int? get isDeleted => getField<int>('is_deleted');
  set isDeleted(int? value) => setField<int>('is_deleted', value);
}
