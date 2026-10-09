import 'dart:convert';

import 'package:flutter/material.dart';

import '/backend/schema/structs/index.dart';

import '/backend/supabase/supabase.dart';
import '/backend/sqlite/queries/sqlite_row.dart';
import '/backend/sqlite/queries/read.dart';
import '../../flutter_flow/place.dart';
import '../../flutter_flow/uploaded_file.dart';

/// SERIALIZATION HELPERS

String dateTimeToString(DateTime dateTime) =>
    '${dateTime.isUtc ? 'u' : 'l'}${dateTime.millisecondsSinceEpoch}';

String dateTimeRangeToString(DateTimeRange dateTimeRange) {
  final start = dateTimeRange.start;
  final end = dateTimeRange.end;
  final startStr = '${start.isUtc ? 'u' : 'l'}${start.millisecondsSinceEpoch}';
  final endStr = '${end.isUtc ? 'u' : 'l'}${end.millisecondsSinceEpoch}';
  return '$startStr|$endStr';
}

String placeToString(FFPlace place) => jsonEncode({
      'latLng': place.latLng.serialize(),
      'name': place.name,
      'address': place.address,
      'city': place.city,
      'state': place.state,
      'country': place.country,
      'zipCode': place.zipCode,
    });

String uploadedFileToString(FFUploadedFile uploadedFile) =>
    uploadedFile.serialize();

String? serializeParam(
  dynamic param,
  ParamType paramType, {
  bool isList = false,
}) {
  try {
    if (param == null) {
      return null;
    }
    if (isList) {
      final serializedValues = (param as Iterable)
          .map((p) => serializeParam(p, paramType, isList: false))
          .where((p) => p != null)
          .map((p) => p!)
          .toList();
      return json.encode(serializedValues);
    }
    String? data;
    switch (paramType) {
      case ParamType.int:
        data = param.toString();
      case ParamType.double:
        data = param.toString();
      case ParamType.String:
        data = param;
      case ParamType.bool:
        data = param ? 'true' : 'false';
      case ParamType.DateTime:
        data = dateTimeToString(param as DateTime);
      case ParamType.DateTimeRange:
        data = dateTimeRangeToString(param as DateTimeRange);
      case ParamType.LatLng:
        data = (param as LatLng).serialize();
      case ParamType.Color:
        data = (param as Color).toCssString();
      case ParamType.FFPlace:
        data = placeToString(param as FFPlace);
      case ParamType.FFUploadedFile:
        data = uploadedFileToString(param as FFUploadedFile);
      case ParamType.JSON:
        data = json.encode(param);

      case ParamType.DataStruct:
        data = param is BaseStruct ? param.serialize() : null;

      case ParamType.SupabaseRow:
        return json.encode((param as SupabaseDataRow).data);

      case ParamType.SqliteRow:
        return json.encode((param as SqliteRow).data);

      default:
        data = null;
    }
    return data;
  } catch (e) {
    print('Error serializing parameter: $e');
    return null;
  }
}

/// END SERIALIZATION HELPERS

/// DESERIALIZATION HELPERS

DateTime? dateTimeFromString(String? dateTimeStr) {
  if (dateTimeStr == null || dateTimeStr.isEmpty) {
    return null;
  }
  final hasPrefix = dateTimeStr.startsWith('u') || dateTimeStr.startsWith('l');
  final milliseconds = int.tryParse(
    hasPrefix ? dateTimeStr.substring(1) : dateTimeStr,
  );
  return milliseconds != null
      ? DateTime.fromMillisecondsSinceEpoch(
          milliseconds,
          isUtc: hasPrefix ? dateTimeStr.startsWith('u') : false,
        )
      : null;
}

DateTimeRange? dateTimeRangeFromString(String dateTimeRangeStr) {
  final pieces = dateTimeRangeStr.split('|');
  if (pieces.length != 2) {
    return null;
  }
  DateTime? parseDateTime(String value) {
    final hasPrefix = value.startsWith('u') || value.startsWith('l');
    final milliseconds = int.tryParse(hasPrefix ? value.substring(1) : value);
    return milliseconds != null
        ? DateTime.fromMillisecondsSinceEpoch(
            milliseconds,
            isUtc: hasPrefix ? value.startsWith('u') : false,
          )
        : null;
  }

  final start = parseDateTime(pieces.first);
  final end = parseDateTime(pieces.last);
  if (start == null || end == null) {
    return null;
  }
  return DateTimeRange(
    start: start,
    end: end,
  );
}

LatLng? latLngFromString(String? latLngStr) {
  final pieces = latLngStr?.split(',');
  if (pieces == null || pieces.length != 2) {
    return null;
  }
  return LatLng(
    double.parse(pieces.first.trim()),
    double.parse(pieces.last.trim()),
  );
}

FFPlace placeFromString(String placeStr) {
  final serializedData = jsonDecode(placeStr) as Map<String, dynamic>;
  final data = {
    'latLng': serializedData.containsKey('latLng')
        ? latLngFromString(serializedData['latLng'] as String)
        : const LatLng(0.0, 0.0),
    'name': serializedData['name'] ?? '',
    'address': serializedData['address'] ?? '',
    'city': serializedData['city'] ?? '',
    'state': serializedData['state'] ?? '',
    'country': serializedData['country'] ?? '',
    'zipCode': serializedData['zipCode'] ?? '',
  };
  return FFPlace(
    latLng: data['latLng'] as LatLng,
    name: data['name'] as String,
    address: data['address'] as String,
    city: data['city'] as String,
    state: data['state'] as String,
    country: data['country'] as String,
    zipCode: data['zipCode'] as String,
  );
}

FFUploadedFile uploadedFileFromString(String uploadedFileStr) =>
    FFUploadedFile.deserialize(uploadedFileStr);

enum ParamType {
  int,
  double,
  String,
  bool,
  DateTime,
  DateTimeRange,
  LatLng,
  Color,
  FFPlace,
  FFUploadedFile,
  JSON,

  DataStruct,
  SupabaseRow,
  SqliteRow,
  CustomClass,
  CustomEnum,
}

dynamic deserializeParam<T>(
  String? param,
  ParamType paramType,
  bool isList, {
  StructBuilder<T>? structBuilder,
}) {
  try {
    if (param == null) {
      return null;
    }
    if (isList) {
      final paramValues = json.decode(param);
      if (paramValues is! Iterable || paramValues.isEmpty) {
        return null;
      }
      return paramValues
          .where((p) => p is String)
          .map((p) => p as String)
          .map((p) => deserializeParam<T>(
                p,
                paramType,
                false,
                structBuilder: structBuilder,
              ))
          .where((p) => p != null)
          .map((p) => p! as T)
          .toList();
    }
    switch (paramType) {
      case ParamType.int:
        return int.tryParse(param);
      case ParamType.double:
        return double.tryParse(param);
      case ParamType.String:
        return param;
      case ParamType.bool:
        return param == 'true';
      case ParamType.DateTime:
        return dateTimeFromString(param);
      case ParamType.DateTimeRange:
        return dateTimeRangeFromString(param);
      case ParamType.LatLng:
        return latLngFromString(param);
      case ParamType.Color:
        return fromCssColor(param);
      case ParamType.FFPlace:
        return placeFromString(param);
      case ParamType.FFUploadedFile:
        return uploadedFileFromString(param);
      case ParamType.JSON:
        return json.decode(param);

      case ParamType.SupabaseRow:
        final data = json.decode(param) as Map<String, dynamic>;
        switch (T) {
          case ListsRow:
            return ListsRow(data);
          case WorkoutExerciseRow:
            return WorkoutExerciseRow(data);
          case ExerciseRow:
            return ExerciseRow(data);
          case PrimaryMuscleGroupRow:
            return PrimaryMuscleGroupRow(data);
          case ExercicesSimpViewRow:
            return ExercicesSimpViewRow(data);
          case ExerciseSetsRow:
            return ExerciseSetsRow(data);
          case CatalogDefaultExerciseRow:
            return CatalogDefaultExerciseRow(data);
          case MuscleGroupRow:
            return MuscleGroupRow(data);
          case UserRecentWorkoutsRow:
            return UserRecentWorkoutsRow(data);
          case SetLogRow:
            return SetLogRow(data);
          case WorkoutLogRow:
            return WorkoutLogRow(data);
          case WorkoutRow:
            return WorkoutRow(data);
          case WorkoutTemplateRow:
            return WorkoutTemplateRow(data);
          case CatalogExerciseMuscleGroupRow:
            return CatalogExerciseMuscleGroupRow(data);
          case VExerciseWithMusclesRow:
            return VExerciseWithMusclesRow(data);
          case ExerciseMuscleGroupRow:
            return ExerciseMuscleGroupRow(data);
          case UsersRow:
            return UsersRow(data);
          default:
            return null;
        }

      case ParamType.DataStruct:
        final data = json.decode(param) as Map<String, dynamic>? ?? {};
        return structBuilder != null ? structBuilder(data) : null;

      case ParamType.SqliteRow:
        final data = json.decode(param) as Map<String, dynamic>;
        switch (T) {
          case GetdirtyworkoutsRow:
            return GetdirtyworkoutsRow(data);
          case GetAllExercisesRow:
            return GetAllExercisesRow(data);
          case UserRow:
            return UserRow(data);
          case GetExercisesForWorkoutRow:
            return GetExercisesForWorkoutRow(data);
          case GetExercisesSimpRow:
            return GetExercisesSimpRow(data);
          case Exercise2Row:
            return Exercise2Row(data);
          case SmartWorkoutRow:
            return SmartWorkoutRow(data);
          case WorkoutSummaryRow:
            return WorkoutSummaryRow(data);
          case GetLatestWorkoutSummaryRow:
            return GetLatestWorkoutSummaryRow(data);
          case GetSetLogsRow:
            return GetSetLogsRow(data);
          case WorkoutsummaryRow:
            return WorkoutsummaryRow(data);
          case SetlogsimpselectRow:
            return SetlogsimpselectRow(data);
          case GetLatestWorkoutBasicRow:
            return GetLatestWorkoutBasicRow(data);
          case SmartWorkout1Row:
            return SmartWorkout1Row(data);
          case GetWorkoutTemplateRow:
            return GetWorkoutTemplateRow(data);
          case GetworkoutExerciseRow:
            return GetworkoutExerciseRow(data);
          case PreviosSetRow:
            return PreviosSetRow(data);
          case WorkoutSummaryByIdRow:
            return WorkoutSummaryByIdRow(data);
          case WorkoutLogSummaryByIdRow:
            return WorkoutLogSummaryByIdRow(data);
          case WorkoutLogExercisesInfoByIdRow:
            return WorkoutLogExercisesInfoByIdRow(data);
          case HistoryRow:
            return HistoryRow(data);
          case GetExerciseMuscleListRow:
            return GetExerciseMuscleListRow(data);
          case GetDropSetsRow:
            return GetDropSetsRow(data);
          case GetprimaryMuscleGroupRow:
            return GetprimaryMuscleGroupRow(data);
          case Last7DaysStatsRow:
            return Last7DaysStatsRow(data);
          case LatestWorkoutHomeRow:
            return LatestWorkoutHomeRow(data);
          case HistoryWorkoutListEXRow:
            return HistoryWorkoutListEXRow(data);
          case MuscleGroupSammaryRow:
            return MuscleGroupSammaryRow(data);
          case PieGraphRow:
            return PieGraphRow(data);
          case WorkoutCountRow:
            return WorkoutCountRow(data);
          case TopMuscleRow:
            return TopMuscleRow(data);
          case ExerciseSessionComparisomRow:
            return ExerciseSessionComparisomRow(data);
          case ExercisePrsRow:
            return ExercisePrsRow(data);
          case Rm1Row:
            return Rm1Row(data);
          case ExerciseStatsRow:
            return ExerciseStatsRow(data);
          case ExerciseLineGraphRow:
            return ExerciseLineGraphRow(data);
          case SmartReplaceRow:
            return SmartReplaceRow(data);
          case VolumeOverviewRow:
            return VolumeOverviewRow(data);
          case TestRow:
            return TestRow(data);
          case MostTimesExerciseRow:
            return MostTimesExerciseRow(data);
          case MostImprovedExerciseRow:
            return MostImprovedExerciseRow(data);
          case TotalExercisesForTimeRow:
            return TotalExercisesForTimeRow(data);
          case TopVolumeExerciseRow:
            return TopVolumeExerciseRow(data);
          case ExercisePerfprmanceRow:
            return ExercisePerfprmanceRow(data);
          case ByMuscleKpiRow:
            return ByMuscleKpiRow(data);
          case LastTrainedMuscleRow:
            return LastTrainedMuscleRow(data);
          case VolumeByMuscleRow:
            return VolumeByMuscleRow(data);
          case ExerciseByMuscleRow:
            return ExerciseByMuscleRow(data);
          case SubMuscleDistributionRow:
            return SubMuscleDistributionRow(data);
          case History1Row:
            return History1Row(data);
          case GetAllSetsRow:
            return GetAllSetsRow(data);
          case WorkoutComparisonRow:
            return WorkoutComparisonRow(data);
          case CompareMuscelsRow:
            return CompareMuscelsRow(data);
          case ExercisesComparisonRow:
            return ExercisesComparisonRow(data);
          case ExercisesForEditRow:
            return ExercisesForEditRow(data);
          case GetMusclesRow:
            return GetMusclesRow(data);
          case CorrectedGetExerciceSimpRow:
            return CorrectedGetExerciceSimpRow(data);
          case CorrectedPreviosSetRow:
            return CorrectedPreviosSetRow(data);
          case CorrectedLatestWorkoutHomeRow:
            return CorrectedLatestWorkoutHomeRow(data);
          case GetWorkoutLogRow:
            return GetWorkoutLogRow(data);
          case VolumeOnlyRow:
            return VolumeOnlyRow(data);
          case ExercisesAndDurationRow:
            return ExercisesAndDurationRow(data);
          case GetExercisesMetadataRowRow:
            return GetExercisesMetadataRowRow(data);
          case UnamedWorkoutsRow:
            return UnamedWorkoutsRow(data);
          case VolumeOverviewWithRangeRow:
            return VolumeOverviewWithRangeRow(data);
          case GetExerciseSetsForWorkoutRow:
            return GetExerciseSetsForWorkoutRow(data);
          case WorkoutCountSimpleRow:
            return WorkoutCountSimpleRow(data);
          case VolumeByTimeRow:
            return VolumeByTimeRow(data);
          case VolumeForMuscleTimeRow:
            return VolumeForMuscleTimeRow(data);
          case SetsForMuscleByTimeRow:
            return SetsForMuscleByTimeRow(data);
          case MusclePctChangeRow:
            return MusclePctChangeRow(data);
          case GetRecentExercisesRow:
            return GetRecentExercisesRow(data);
          case GetUserExercisesRow:
            return GetUserExercisesRow(data);
          case GetSubMuscelsRow:
            return GetSubMuscelsRow(data);
          case ExercisePrsTimedRow:
            return ExercisePrsTimedRow(data);
          case TimedExerciseLineGraphRow:
            return TimedExerciseLineGraphRow(data);
          case TimeBasedExerciseAnalyticsRow:
            return TimeBasedExerciseAnalyticsRow(data);
          case ExercisePrsBodyweightRow:
            return ExercisePrsBodyweightRow(data);
          case ExerciseBodyweightLineGraphRow:
            return ExerciseBodyweightLineGraphRow(data);
          case BodyweightExerciseAnalyticsRow:
            return BodyweightExerciseAnalyticsRow(data);
          case SubMuscelsRow:
            return SubMuscelsRow(data);
          case DynamicvolumeRow:
            return DynamicvolumeRow(data);
          case GetPrimaryMuscelsRow:
            return GetPrimaryMuscelsRow(data);
          case HasExerciseDataRow:
            return HasExerciseDataRow(data);
          case ExercisePrsAssistedRow:
            return ExercisePrsAssistedRow(data);
          case ExerciseLineGraphAssistedRow:
            return ExerciseLineGraphAssistedRow(data);
          case AssistedAnalyticsRow:
            return AssistedAnalyticsRow(data);
          case WorkoutNumRow:
            return WorkoutNumRow(data);
          case WorkoutsForRoutineRow:
            return WorkoutsForRoutineRow(data);
          case GetUserExerciseRow:
            return GetUserExerciseRow(data);
          case GetWorklogsCountRow:
            return GetWorklogsCountRow(data);
          case GetMuscleRow:
            return GetMuscleRow(data);
          case GetExerciseRow:
            return GetExerciseRow(data);
          case GetSetanalysisRow:
            return GetSetanalysisRow(data);
          case WorkoutHomeRow:
            return WorkoutHomeRow(data);
          case GetUserRow:
            return GetUserRow(data);
          case GetAiexercisesRow:
            return GetAiexercisesRow(data);
          case WorkoutHeroStatRow:
            return WorkoutHeroStatRow(data);
          case WorkoutBreakdownSetsRow:
            return WorkoutBreakdownSetsRow(data);
          case WeekWorkoutDaysRow:
            return WeekWorkoutDaysRow(data);
          default:
            return null;
        }

      default:
        return null;
    }
  } catch (e) {
    print('Error deserializing parameter: $e');
    return null;
  }
}
