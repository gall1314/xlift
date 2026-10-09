import '../database.dart';

class ListsTable extends SupabaseTable<ListsRow> {
  @override
  String get tableName => 'lists';

  @override
  ListsRow createRow(Map<String, dynamic> data) => ListsRow(data);
}

class ListsRow extends SupabaseDataRow {
  ListsRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => ListsTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  DateTime get createdAt => getField<DateTime>('created_at')!;
  set createdAt(DateTime value) => setField<DateTime>('created_at', value);

  String get name => getField<String>('name')!;
  set name(String value) => setField<String>('name', value);

  String get ownerId => getField<String>('owner_id')!;
  set ownerId(String value) => setField<String>('owner_id', value);
}
