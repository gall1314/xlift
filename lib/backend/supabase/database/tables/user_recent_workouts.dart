import '../database.dart';

class UserRecentWorkoutsTable extends SupabaseTable<UserRecentWorkoutsRow> {
  @override
  String get tableName => 'user_recent_workouts';

  @override
  UserRecentWorkoutsRow createRow(Map<String, dynamic> data) =>
      UserRecentWorkoutsRow(data);
}

class UserRecentWorkoutsRow extends SupabaseDataRow {
  UserRecentWorkoutsRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => UserRecentWorkoutsTable();

  String? get userId => getField<String>('user_id');
  set userId(String? value) => setField<String>('user_id', value);

  String? get workoutId => getField<String>('workout_id');
  set workoutId(String? value) => setField<String>('workout_id', value);

  String? get workoutName => getField<String>('workout_name');
  set workoutName(String? value) => setField<String>('workout_name', value);

  int? get exerciseCount => getField<int>('exercise_count');
  set exerciseCount(int? value) => setField<int>('exercise_count', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);
}
