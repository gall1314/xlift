import '../database.dart';

class UsersTable extends SupabaseTable<UsersRow> {
  @override
  String get tableName => 'users';

  @override
  UsersRow createRow(Map<String, dynamic> data) => UsersRow(data);
}

class UsersRow extends SupabaseDataRow {
  UsersRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => UsersTable();

  DateTime get createdAt => getField<DateTime>('created_at')!;
  set createdAt(DateTime value) => setField<DateTime>('created_at', value);

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String? get name => getField<String>('name');
  set name(String? value) => setField<String>('name', value);

  String? get email => getField<String>('email');
  set email(String? value) => setField<String>('email', value);

  String? get profileImageUrl => getField<String>('profile_image_url');
  set profileImageUrl(String? value) =>
      setField<String>('profile_image_url', value);

  String? get username => getField<String>('username');
  set username(String? value) => setField<String>('username', value);

  bool? get isKg => getField<bool>('is_kg');
  set isKg(bool? value) => setField<bool>('is_kg', value);

  double? get weight => getField<double>('weight');
  set weight(double? value) => setField<double>('weight', value);

  double? get height => getField<double>('height');
  set height(double? value) => setField<double>('height', value);

  String? get sex => getField<String>('sex');
  set sex(String? value) => setField<String>('sex', value);

  DateTime? get dateOfBirth => getField<DateTime>('date_of_birth');
  set dateOfBirth(DateTime? value) =>
      setField<DateTime>('date_of_birth', value);

  int? get heightIsCm => getField<int>('height_is_cm');
  set heightIsCm(int? value) => setField<int>('height_is_cm', value);

  int? get bodyWeightIsKg => getField<int>('body_weight_is_kg');
  set bodyWeightIsKg(int? value) => setField<int>('body_weight_is_kg', value);
}
