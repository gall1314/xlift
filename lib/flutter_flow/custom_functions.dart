import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'lat_lng.dart';
import 'place.dart';
import 'uploaded_file.dart';
import '/backend/schema/structs/index.dart';
import '/backend/supabase/supabase.dart';
import '/backend/sqlite/sqlite_manager.dart';
import '/auth/supabase_auth/auth_util.dart';

bool? shouldShowExercise(
  String itemName,
  String query,
  String id,
  List<dynamic> selectedList,
  String selectedMuscleGroup,
  String? primaryMuscle1,
  String? primaryMuscle2,
  String? subMuscle1,
  String? subMuscle2,
  String? subMuscle3,
  String selectedSubMuscle,
) {
  {
    final matchesQuery =
        itemName.toLowerCase().contains(query.trim().toLowerCase());

    final alreadySelected = selectedList.any(
      (e) => e['id'].toString() == id.toString(),
    );

    final muscleToCompare = selectedMuscleGroup.toLowerCase();
    final subToCompare = (selectedSubMuscle ?? '').toLowerCase();

    final matchesMuscleGroup = selectedMuscleGroup == 'All' ||
        (primaryMuscle1?.toLowerCase() ?? '') == muscleToCompare ||
        (primaryMuscle2?.toLowerCase() ?? '') == muscleToCompare ||
        (subMuscle1?.toLowerCase() ?? '') == muscleToCompare ||
        (subMuscle2?.toLowerCase() ?? '') == muscleToCompare ||
        (subMuscle3?.toLowerCase() ?? '') == muscleToCompare;

    final matchesSubMuscle = selectedSubMuscle == null ||
        selectedSubMuscle == 'All' ||
        selectedSubMuscle.trim() == '' ||
        (subMuscle1?.toLowerCase() ?? '') == subToCompare ||
        (subMuscle2?.toLowerCase() ?? '') == subToCompare ||
        (subMuscle3?.toLowerCase() ?? '') == subToCompare;

    return matchesQuery &&
        !alreadySelected &&
        matchesMuscleGroup &&
        matchesSubMuscle;
  }
}

bool shouldShowExerciseForPopup(
  String itemName,
  String? query,
  int id,
  List<dynamic> exerciseSets,
  String selectedMuscleGroup,
  String? selectedSubMuscle,
  String primaryMuscle1,
  String? primaryMuscle2,
  String? subMuscle1,
  String? subMuscle2,
  String? subMuscle3,
  String equipment,
  String exerciseType,
  String selectedEquipment,
  String selectedExerciseType,
) {
  {
    try {
      String _s(String? s) => (s ?? '').toLowerCase().trim();

      bool _isAllOrEmpty(String? v) {
        final x = _s(v);
        return x.isEmpty || x == 'all' || x == 'הכל' || x == '*';
      }

      int? _toInt(dynamic v) {
        if (v is int) return v;
        if (v is num) return v.toInt();
        if (v is String) return int.tryParse(v);
        return null;
      }

      // תומך גם ב־CSV/List
      bool _matchToken(dynamic value, String? selected) {
        if (_isAllOrEmpty(selected)) return true;

        final sel = _s(selected);
        List<String> tokens = [];

        if (value is List) {
          tokens = value
              .map((e) => _s(e?.toString()))
              .where((e) => e.isNotEmpty)
              .toList();
        } else if (value is String) {
          tokens = value
              .split(RegExp(r'[,\|/]'))
              .map((e) => _s(e))
              .where((e) => e.isNotEmpty)
              .toList();
        } else {
          final v = _s(value?.toString());
          if (v.isNotEmpty) tokens = [v];
        }

        return tokens.contains(sel);
      }

      void _collectIds(dynamic node, Set<int> out) {
        if (node == null) return;

        if (node is List) {
          for (final it in node) {
            _collectIds(it, out);
          }
          return;
        }

        if (node is Map) {
          for (final k in ['exerciseId', 'exercise_id', 'exerciseID']) {
            if (node.containsKey(k)) {
              final v = _toInt(node[k]);
              if (v != null) out.add(v);
            }
          }

          final ex = node['exercise'];
          if (ex is Map) {
            final v = _toInt(ex['id']);
            if (v != null) out.add(v);
          }

          for (final v in node.values) {
            if (v is List || v is Map) {
              _collectIds(v, out);
            }
          }
          return;
        }
      }

      final existingIds = <int>{};
      _collectIds(exerciseSets, existingIds);

      // 1) text search
      if (query != null && query.trim().isNotEmpty) {
        final hay = _s(itemName);
        final q = _s(query);
        if (!hay.contains(q)) return false;
      }

      // 2) hide if already in exerciseSets
      final idInt = _toInt(id);
      if (idInt != null && existingIds.contains(idInt)) return false;

      // 3) primary muscle filter
      final muscleToCompare = selectedMuscleGroup;
      final matchesMuscleGroup = _isAllOrEmpty(muscleToCompare) ||
          _s(primaryMuscle1) == _s(muscleToCompare) ||
          _s(primaryMuscle2) == _s(muscleToCompare);
      if (!matchesMuscleGroup) return false;

      // 4) sub-muscle filter
      final subToCompare = selectedSubMuscle;
      final matchesSubMuscle = _isAllOrEmpty(subToCompare) ||
          _s(subMuscle1) == _s(subToCompare) ||
          _s(subMuscle2) == _s(subToCompare) ||
          _s(subMuscle3) == _s(subToCompare);
      if (!matchesSubMuscle) return false;

      // 5) equipment filter
      if (!_matchToken(equipment, selectedEquipment)) return false;

      // 6) exerciseType filter
      if (!_matchToken(exerciseType, selectedExerciseType)) return false;

      return true;
    } catch (e, _) {
      // ברירת מחדל: אם משהו נשבר בלוגיקה – לא נסתיר כלום
      return true;
    }
  }
}

bool isExerciseSelected(
  List<dynamic> selectedList,
  String exerciseId,
) {
  {
    if (selectedList == null || selectedList.isEmpty || exerciseId == null) {
      return false;
    }
    final target = exerciseId.toString();

    for (final item in selectedList) {
      if (item == null) continue;

      if (item is Map) {
        final id = item['id'] ?? item['exercise_id'] ?? item['exerciseId'];
        if (id != null && id.toString() == target) return true;
      } else {
        // במקרה שהרשימה היא של מזהים בלבד (int/String)
        if (item.toString() == target) return true;
      }
    }
    return false;
  }
}

bool? getShowWeight(
  List<dynamic>? showWeightStatus,
  String? exerciseId,
  bool? isBodyweight,
) {
  {
    final entry = showWeightStatus?.firstWhere(
      (e) => e['exercise_id'] == exerciseId,
      orElse: () => null,
    );

    if (entry == null) {
      return false;
    }

    return entry['show_weight'] == true;
  }
}

String formatLegendLabelWithPercentage(
  double setCount,
  int totalSets,
) {
  {
    if (totalSets == 0) {
      return '0%';
    }

    final percent = ((setCount / totalSets) * 100).round();
    return '$percent%';
  }
}

bool shouldShowWorkoutPartial(
  String workoutName,
  String query,
  String createdAtIso,
  String selectedRange,
  String? selectedMuscle,
  String calculatedMainMuscles,
) {
  {
    final nameMatch =
        workoutName.toLowerCase().contains(query.trim().toLowerCase());

    final date = DateTime.tryParse(createdAtIso);
    if (date == null) return false;

    final now = DateTime.now();
    bool dateMatch;

    switch (selectedRange) {
      case 'Last 7 days':
        dateMatch = date.isAfter(now.subtract(Duration(days: 7)));
        break;
      case 'Last 30 days':
        dateMatch = date.isAfter(now.subtract(Duration(days: 30)));
        break;
      case 'Last 90 days':
        dateMatch = date.isAfter(now.subtract(Duration(days: 90)));
        break;
      default:
        dateMatch = true;
    }

    bool muscleMatch;
    if (selectedMuscle == null || selectedMuscle == 'All') {
      muscleMatch = true;
    } else {
      muscleMatch = calculatedMainMuscles
              ?.toLowerCase()
              .contains(selectedMuscle.toLowerCase()) ??
          false;
    }

    return nameMatch && dateMatch && muscleMatch;
  }
}

int? getDurationFromTextFields(
  String minutesTens,
  String minutesUnits,
  String secondsTens,
  String secondsUnits,
) {
  {
    final minutes = (int.tryParse(minutesTens) ?? 0) * 10 +
        (int.tryParse(minutesUnits) ?? 0);
    final seconds = (int.tryParse(secondsTens) ?? 0) * 10 +
        (int.tryParse(secondsUnits) ?? 0);
    final totalMillis = (minutes * 60 + seconds) * 1000;

    return totalMillis > 0 ? totalMillis : null;
  }
}

bool isSetDone(
  int exerciseId,
  int setNumber,
  List<dynamic> loggedSets,
) {
  {
    final match = loggedSets.firstWhere(
      (set) =>
          set['exercise_id'] == exerciseId && set['set_number'] == setNumber,
      orElse: () => null,
    );

    if (match == null) return false;
    return match['done'] == true;
  }
}

bool shouldShowWeightField(
  bool isBodyweight,
  bool isTimerBased,
  bool getShowWeight,
  bool isSetDone,
) {
  {
    // ✅ קודם כל: אם סומן ✓ → לא מציגים
    if (isSetDone) return false;

    // ✅ אם לחצו Add Weight → מציגים תמיד
    if (getShowWeight) return true;

    // ✅ ברירת מחדל: מציגים רק אם זה לא זמן ולא משקל גוף
    if (!isBodyweight && !isTimerBased) return true;

    // ❌ כל מצב אחר – מוסתר
    return false;
  }
}

String? formatDurationMs(int ms) {
  {
    if (ms == null || ms <= 0) {
      return "00:00";
    }

    final totalSeconds = (ms / 1000).floor();
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');

    return "$minutes:$seconds";
  }
}

String? formatDurationFromDouble(double ms) {
  {
    if (ms <= 0) {
      return "00:00";
    }

    final totalMs = ms.floor();
    final totalSeconds = totalMs ~/ 1000;
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');

    return "$minutes:$seconds";
  }
}

double normalizeScore(double score) {
  return score / 10.0;
}

List<dynamic> newCustomFunctionOffline(
  int exerciseId,
  List<dynamic> exerciseSets,
) {
  {
    final match = exerciseSets.firstWhere(
      (e) => e['exerciseId'] == exerciseId,
      orElse: () => null,
    );

    if (match == null) return [];

    return match['sets'] ?? [];
  }
}

List<dynamic> generateRestTimeOptions() {
  {
    final List<Map<String, dynamic>> times = [];

    for (int seconds = 10; seconds <= 480; seconds += 10) {
      final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
      final secs = (seconds % 60).toString().padLeft(2, '0');
      times.add({
        'label': '$minutes:$secs',
        'ms': seconds * 1000,
      });
    }

    return times;
  }
}

int getRestDurationForExercise(
  dynamic restDurations,
  int exerciseId,
) {
  {
    final key = exerciseId.toString();

    if (restDurations is Map<String, dynamic>) {
      final value = restDurations[key];

      if (value is int) {
        return value;
      }

      // ננסה להמיר אם נשלח כ־String בטעות
      if (value is String) {
        final parsed = int.tryParse(value);
        if (parsed != null) {
          return parsed;
        }
      }
    }

    return 90000; // ברירת מחדל: 1:30 דקה
  }
}

String formatExerciseRestTime(
  dynamic exerciseRestTimes,
  int exerciseId,
) {
  {
    final rawValue = exerciseRestTimes['$exerciseId'];

    // אם אין ערך -> ברירת מחדל 1:30 (90 שניות)
    final timeMs = rawValue ?? 90000;

    // אם הערך הוא 0 -> מחזירים Off
    if (timeMs == 0) {
      return 'Off';
    }

    final totalSeconds = (timeMs / 1000).round();
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');

    return '$minutes:$seconds';
  }
}

dynamic getHintFromPreviousSet(
  List<dynamic> loggedSets,
  int exerciseId,
  int currentSetNumber,
  String fieldName,
) {
  {
    if (!['reps', 'weight'].contains(fieldName)) return '0';

    // סנן את הסטים של אותו תרגיל
    final setsForExercise =
        loggedSets.where((s) => s['exerciseId'] == exerciseId).toList();

    // מיין לפי מספר סט
    setsForExercise.sort(
      (a, b) => (a['setNumber'] ?? 0).compareTo(b['setNumber'] ?? 0),
    );

    // חפש את הסט האחרון לפני הסט הנוכחי שיש בו ערך תקין
    for (int i = setsForExercise.length - 1; i >= 0; i--) {
      final set = setsForExercise[i];
      final setNum = set['setNumber'];

      if (setNum < currentSetNumber && set[fieldName] != null) {
        final value = set[fieldName];

        if (value.toString().isNotEmpty) {
          if (value is num && value % 1 == 0) {
            return value.toInt().toString(); // מספר שלם
          }
          return value.toString(); // מספר עשרוני
        }
      }
    }

    // ❗ אם לא נמצא שום ערך → החזר "0"
    return '0';
  }
}

bool shouldShowDeleteSetButton(
  List<dynamic> exerciseSets,
  int exerciseId,
) {
  {
    final exercise = exerciseSets.firstWhere(
      (s) => s['exerciseId'] == exerciseId,
      orElse: () => null,
    );

    if (exercise == null) return false;

    final sets = exercise['sets'] as List<dynamic>?;

    return sets != null && sets.length > 1;
  }
}

bool shouldShowWeightFieldOffline(
  int exerciseId,
  int setNumber,
  List<dynamic> loggedSets,
  List<dynamic> exerciseSets,
  bool isTimed,
) {
  {
    int _toInt(dynamic v) {
      if (v is int) return v;
      if (v is double) return v.round();
      if (v is String) return int.tryParse(v) ?? 0;
      return 0;
    }

    bool _toBool(dynamic v) {
      if (v is bool) return v;
      if (v is num) return v != 0;
      if (v is String) {
        final t = v.toLowerCase();
        return t == 'true' || t == '1';
      }
      return false;
    }

    Map<String, dynamic>? _asMap(dynamic v) {
      if (v is Map) {
        try {
          return Map<String, dynamic>.from(v);
        } catch (_) {}
      }
      return null;
    }

    Map<String, dynamic>? _firstMapWhere(
      List<dynamic> list,
      bool Function(Map<String, dynamic>) test,
    ) {
      for (final item in list) {
        final m = _asMap(item);
        if (m != null && test(m)) return m;
      }
      return null;
    }

    // ---------- weighted from exerciseSets template ----------
    // isDone is NOT part of visibility anymore: the WeightField stays
    // mounted when the set is done (it locks itself via its isDone
    // param), so its typed text survives done/undone without a
    // dispose/recreate cycle.
    final exMatch = _firstMapWhere(
      exerciseSets,
      (e) => _toInt(e['exerciseId'] ?? e['exercise_id']) == exerciseId,
    );

    bool weighted = false;
    if (exMatch != null) {
      final sets =
          (exMatch['sets'] is List) ? (exMatch['sets'] as List) : const [];
      final setTpl = _firstMapWhere(
        sets,
        (s) => _toInt(s['setNumber'] ?? s['set_number']) == setNumber,
      );
      if (setTpl != null) {
        weighted = _toBool(setTpl['weighted'] ?? setTpl['showWeightField']);
      }
    }

    // Show the weight field for any weighted, non-timed set - done or not.
    return !isTimed && weighted;
  }
}

bool isSetDoneOffline(
  List<dynamic> loggedSets,
  int exerciseId,
  int setNumber,
) {
  {
    return loggedSets.any((s) =>
        s['exerciseId'] == exerciseId &&
        s['setNumber'] == setNumber &&
        s['isDone'] == true);
  }
}

String getLoggedValue(
  List<dynamic> loggedSets,
  int exerciseId,
  int setNumber,
  String fieldName,
) {
  {
    final set = loggedSets.firstWhere(
      (s) => s['exerciseId'] == exerciseId && s['setNumber'] == setNumber,
      orElse: () => null,
    );

    if (set != null && set[fieldName] != null) {
      final value = set[fieldName];
      if (value is double && value % 1 == 0) {
        return value.toInt().toString(); // 25.0 ➜ '25'
      }
      return value.toString(); // משאיר כמו שהוא
    }

    return '';
  }
}

List<dynamic> updateTimerModeForSet(
  int exerciseId,
  int setNumber,
  int newMode,
  List<dynamic> exerciseSets,
) {
  {
    final List<Map<String, dynamic>> updatedSets = [];

    for (final item in exerciseSets) {
      if (item is! Map<String, dynamic>) continue;

      final id = item['exerciseId'];
      final setsRaw = item['sets'];
      final sets =
          setsRaw is List ? List<Map<String, dynamic>>.from(setsRaw) : [];

      if (id == exerciseId && sets.isNotEmpty) {
        final updatedInnerSets = sets.map((set) {
          final sNum = set['setNumber'];
          if (sNum == setNumber) {
            return {
              'setNumber': sNum,
              'timerMode': newMode,
              'showWeightField': set['showWeightField'] ?? true,
            };
          }
          return {
            'setNumber': set['setNumber'],
            'timerMode': set['timerMode'],
            'showWeightField': set['showWeightField'] ?? true,
          };
        }).toList();

        updatedSets.add({
          'exerciseId': id,
          'sets': updatedInnerSets,
        });
      } else {
        // גם אם לא מעדכן כלום – שומר על המבנה התקני
        updatedSets.add({
          'exerciseId': id,
          'sets': sets
              .map((set) => {
                    'setNumber': set['setNumber'],
                    'timerMode': set['timerMode'],
                    'showWeightField': set['showWeightField'] ?? true,
                  })
              .toList(),
        });
      }
    }

    return updatedSets;
  }
}

double? getFieldWithFallback(
  double? currentValue,
  List<dynamic> loggedSets,
  int exerciseId,
  int setNumber,
) {
  {
    // -----------------------------------------
    // 1️⃣ מה שהמשתמש כתב עכשיו
    // -----------------------------------------
    if (currentValue != null) return currentValue;

    // -----------------------------------------
    // helper parse
    // -----------------------------------------
    double? toDouble(dynamic v) {
      if (v == null) return null;
      if (v is double) return v;
      if (v is int) return v.toDouble();
      return double.tryParse(v.toString().trim());
    }

    // -----------------------------------------
    // 2️⃣ fallback — loggedSets בלבד
    // -----------------------------------------
    final loggedSorted = loggedSets
        .where((s) => s is Map && s['exerciseId'] == exerciseId)
        .toList()
      ..sort((a, b) => (a['setNumber'] ?? 0).compareTo(b['setNumber'] ?? 0));

    for (int i = loggedSorted.length - 1; i >= 0; i--) {
      final row = loggedSorted[i];
      final sn = row['setNumber'] ?? 0;

      if (sn < setNumber && row['weight'] != null) {
        final parsed = toDouble(row['weight']);
        if (parsed != null) return parsed;
      }
    }

    // -----------------------------------------
    // 3️⃣ אין כלום
    // -----------------------------------------
    return null;
  }
}

int? getRepsWithFallback(
  int? currentReps,
  List<dynamic> loggedSets,
  int exerciseId,
  int setNumber,
  List<dynamic> exerciseSets,
) {
  {
    // 1. What the user typed right now
    if (currentReps != null) return currentReps;

    // Helper parse
    int? toInt(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      if (v is double) return v.toInt();
      if (v is String) return int.tryParse(v.trim());
      return null;
    }

    // 2. Fallback - last performed set (loggedSets)
    final loggedSorted = loggedSets
        .where((s) => s is Map && s['exerciseId'] == exerciseId)
        .toList()
      ..sort((a, b) => (a['setNumber'] ?? 0).compareTo(b['setNumber'] ?? 0));

    for (int i = loggedSorted.length - 1; i >= 0; i--) {
      final row = loggedSorted[i];
      final sn = row['setNumber'] ?? 0;

      if (sn < setNumber && row['reps'] != null) {
        final parsed = toInt(row['reps']);
        if (parsed != null) return parsed;
      }
    }

    // 3. Last fallback - target reps from the template
    for (final item in exerciseSets) {
      if (item is! Map) continue;
      if (item['exerciseId'] != exerciseId) continue;

      final sets = item['sets'];
      if (sets is List) {
        // Target of this specific set number
        for (final s in sets) {
          if (s is Map && s['setNumber'] == setNumber) {
            final parsed = toInt(s['targetReps']);
            if (parsed != null) return parsed;
          }
        }
        // No target for this set - take the first available target
        for (final s in sets) {
          if (s is Map) {
            final parsed = toInt(s['targetReps']);
            if (parsed != null) return parsed;
          }
        }
      }

      break;
    }

    // 4. Nothing found
    return null;
  }
}

String? getFormattedDurationWithFallback(
  List<dynamic> loggedSets,
  int exerciseId,
  int setNumber,
) {
  {
    int? durationMs;

    // נסה קודם כל את הסט הנוכחי
    final current = loggedSets.firstWhere(
      (s) =>
          s['exerciseId'] == exerciseId &&
          s['setNumber'] == setNumber &&
          s.containsKey('durationMs'),
      orElse: () => null,
    );
    if (current != null) {
      durationMs = current['durationMs'];
    }

    // אם אין, ננסה מסט קודם
    if (durationMs == null) {
      for (int i = setNumber - 1; i >= 1; i--) {
        final previous = loggedSets.firstWhere(
          (s) =>
              s['exerciseId'] == exerciseId &&
              s['setNumber'] == i &&
              s.containsKey('durationMs'),
          orElse: () => null,
        );
        if (previous != null) {
          durationMs = previous['durationMs'];
          break;
        }
      }
    }

    // אם עדיין אין – נחזיר ריק
    if (durationMs == null) return '';

    final totalSeconds = (durationMs / 1000).round();
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;

    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}

String formatPreviousSet(
  int? reps,
  double? weight,
  int? durationSeconds,
  bool useKg,
) {
  {
    // זמן (תומך גם במילישניות וגם בשניות)
    if (durationSeconds != null && durationSeconds > 0) {
      final secs = durationSeconds >= 1000
          ? (durationSeconds / 1000).round()
          : durationSeconds;
      final m = (secs ~/ 60).toString().padLeft(2, '0');
      final s = (secs % 60).toString().padLeft(2, '0');
      return "$m:$s";
    }

    // משקל + חזרות
    if ((weight != null && weight > 0) && (reps != null && reps > 0)) {
      final unit = useKg ? "kg" : "lb";
      final w = (weight % 1 == 0)
          ? weight.toInt().toString()
          : weight.toStringAsFixed(1).replaceAll(RegExp(r'\.?0+$'), "");
      return "$w $unit × $reps";
    }

    // רק חזרות (משקל גוף/אין משקל)
    if (reps != null && reps > 0) {
      return reps.toString();
    }

    // רק משקל (נדיר, אבל נסבירי)
    if (weight != null && weight > 0) {
      final unit = useKg ? "kg" : "lb";
      final w = (weight % 1 == 0)
          ? weight.toInt().toString()
          : weight.toStringAsFixed(1).replaceAll(RegExp(r'\.?0+$'), "");
      return "$w $unit";
    }

    return "-";
  }
}

bool canCompleteSetFromState(
  List<dynamic> loggedSets,
  int exerciseId,
  int setNumber,
  int? durationSecondsCandidate,
  List<dynamic> dropSets,
  List<dynamic> exerciseSets,
  bool allowsBodyweight,
  bool isTimedExercise,
) {
  {
    try {
      // ---------- helpers ----------
      int asInt(dynamic v) {
        if (v == null) return 0;
        if (v is int) return v;
        if (v is num) return v.toInt();
        return int.tryParse(v.toString()) ?? 0;
      }

      double asDouble(dynamic v) {
        if (v == null) return 0;
        if (v is num) return v.toDouble();
        return double.tryParse(v.toString()) ?? 0;
      }

      bool truthy(dynamic v) {
        if (v == null) return false;
        if (v is bool) return v;
        if (v is num) return v != 0;
        final s = v.toString().trim().toLowerCase();
        return s == 'true' || s == '1';
      }

      // =========================================================
      // 1. Resolve template (weighted / reps / duration)
      // =========================================================
      int templateWeighted = 0;
      int templateTargetReps = 0;
      int templateDurationSeconds = 0;
      bool templateFound = false;

      for (final e in exerciseSets) {
        if (e is! Map || asInt(e['exerciseId']) != exerciseId) continue;
        final sets = e['sets'];
        if (sets is! List) continue;

        for (final s in sets) {
          if (s is Map && asInt(s['setNumber']) == setNumber) {
            templateWeighted = asInt(s['weighted']);
            templateTargetReps = asInt(s['targetReps']);
            templateDurationSeconds = asInt(s['durationSeconds']);
            templateFound = true;
            break;
          }
        }

        // Fallback: this set number isn't in the template (user added
        // extra sets mid-workout). Inherit from the template's first
        // set that has values - same behavior as the hint function.
        if (!templateFound) {
          for (final s in sets) {
            if (s is! Map) continue;
            templateWeighted = asInt(s['weighted']);
            if (asInt(s['targetReps']) > 0) {
              templateTargetReps = asInt(s['targetReps']);
            }
            if (asInt(s['durationSeconds']) > 0) {
              templateDurationSeconds = asInt(s['durationSeconds']);
            }
            if (templateTargetReps > 0) break;
          }
        }

        break;
      }

      // =========================================================
      // 2. Timed exercise
      // =========================================================
      // Time accumulated right now (timer / input field) that is NOT
      // yet written to loggedSets. Previously ignored - that was the
      // bug: a plank with a running timer had no durationMs in
      // loggedSets yet, so the check failed.
      final int candidate = durationSecondsCandidate ?? 0;

      // Don't trust the isTimedExercise argument alone - a wrong/null
      // binding upstream would silently block timed exercises (plank).
      // Derive it from the data as well: candidate time present, template
      // has a duration, or any non-drop log for this exercise carries
      // durationMs.
      final bool effectiveTimed = isTimedExercise ||
          candidate > 0 ||
          templateDurationSeconds > 0 ||
          loggedSets.any(
            (l) =>
                l is Map &&
                asInt(l['exerciseId']) == exerciseId &&
                !truthy(l['isDropSet']) &&
                asInt(l['durationMs']) > 0,
          );

      if (effectiveTimed) {
        // 2a. Live time not yet logged -> good to save.
        if (candidate > 0) return true;

        // 2b. Template prescribes a duration -> good to save.
        if (templateDurationSeconds > 0) return true;

        // 2c. Already-logged time for THIS set.
        return loggedSets.any(
          (l) =>
              l is Map &&
              asInt(l['exerciseId']) == exerciseId &&
              asInt(l['setNumber']) == setNumber &&
              !truthy(l['isDropSet']) &&
              asInt(l['durationMs']) > 0,
        );
      }

      // =========================================================
      // 3. Weight requirement
      // =========================================================
      final bool requiresWeight =
          templateWeighted == 1 && allowsBodyweight == false;

      // =========================================================
      // 4. Logged values for THIS set (informational only)
      // =========================================================
      final currentLogged = loggedSets.where(
        (l) =>
            l is Map &&
            asInt(l['exerciseId']) == exerciseId &&
            asInt(l['setNumber']) == setNumber &&
            !truthy(l['isDropSet']) &&
            (asInt(l['reps']) > 0 ||
                asDouble(l['weight']) > 0 ||
                asInt(l['durationMs']) > 0),
      );

      final bool hasLoggedReps = currentLogged.any((l) => asInt(l['reps']) > 0);
      final bool hasLoggedWeight =
          currentLogged.any((l) => asDouble(l['weight']) > 0);

      // Note: two early-return checks that blocked inheritance were
      // removed earlier - inheritance (step 5) handles those cases.

      // =========================================================
      // 5. Inheritance / template fallback
      // =========================================================
      final bool hasPrevReps = loggedSets.any(
        (l) =>
            l is Map &&
            asInt(l['exerciseId']) == exerciseId &&
            asInt(l['setNumber']) < setNumber &&
            !truthy(l['isDropSet']) &&
            asInt(l['reps']) > 0,
      );

      final bool hasPrevWeight = loggedSets.any(
        (l) =>
            l is Map &&
            asInt(l['exerciseId']) == exerciseId &&
            asInt(l['setNumber']) < setNumber &&
            !truthy(l['isDropSet']) &&
            asDouble(l['weight']) > 0,
      );

      final bool hasReps =
          hasLoggedReps || hasPrevReps || templateTargetReps > 0;

      final bool hasWeight =
          hasLoggedWeight || hasPrevWeight || templateWeighted == 0;

      if (!hasReps) return false;
      if (requiresWeight && !hasWeight) return false;

      // =========================================================
      // 6. Drop sets
      // =========================================================
      final plannedDrops = dropSets.where(
        (d) =>
            d is Map &&
            asInt(d['exerciseId']) == exerciseId &&
            asInt(d['parentSetNumber']) == setNumber,
      );

      for (final d in plannedDrops) {
        final int order = asInt(d['dropOrder']);

        final logged = loggedSets.firstWhere(
          (l) =>
              l is Map &&
              asInt(l['exerciseId']) == exerciseId &&
              asInt(l['setNumber']) == setNumber &&
              truthy(l['isDropSet']) &&
              asInt(l['dropOrder']) == order,
          orElse: () => null,
        );

        final int reps = logged != null ? asInt(logged['reps']) : 0;
        final double weight = logged != null ? asDouble(logged['weight']) : 0;

        if (reps <= 0) return false;
        if (requiresWeight && weight <= 0) return false;
      }

      return true;
    } catch (_) {
      return false;
    }
  }
}

List<dynamic> getDropRowsForSet(
  List<dynamic> dropSets,
  int exerciseId,
  int parentSetNumber,
) {
  {
    final rows = dropSets
        .where((r) =>
            r['exerciseId'] == exerciseId &&
            r['parentSetNumber'] == parentSetNumber)
        .map((e) => Map<String, dynamic>.from(e))
        .toList();

    rows.sort(
        (a, b) => (a['dropOrder'] as int).compareTo(b['dropOrder'] as int));

    // הוספת שדה label אוטומטי לכל פריט
    for (var row in rows) {
      final order = row['dropOrder'] ?? 0;
      row['label'] = 'Drop $order';
    }

    return rows;
  }
}

int? getDropHint(
  List<dynamic> loggedSets,
  List<dynamic> dropSets,
  int exerciseId,
  int parentSetNumber,
  String dropLabel,
) {
  {
    // ---------- ladder ----------
    int ladderPercent(int order) {
      if (order == 1) return 80;
      if (order == 2) return 70;
      if (order == 3) return 60;
      return 55;
    }

    // ---------- helpers ----------
    int? parseOrder(String? label) {
      if (label == null) return null;
      final m = RegExp(r'(\d+)').firstMatch(label);
      if (m == null) return null;
      return int.tryParse(m.group(1)!);
    }

    double? toDouble(dynamic v) {
      if (v is num) return v.toDouble();
      return null;
    }

    // ---------- parent weight ----------
    double? getParentWeight() {
      // 1) exact parent set
      for (final s in loggedSets) {
        if (s is! Map) continue;
        if (s['exerciseId'] != exerciseId) continue;
        if (s['setNumber'] != parentSetNumber) continue;
        if (s['isDrop'] == true || s['isDropSet'] == 1) continue;

        final w = toDouble(s['weight']);
        if (w != null && w > 0) return w;
      }

      // 2) last previous regular set
      double? best;
      int bestSet = -1;

      for (final s in loggedSets) {
        if (s is! Map) continue;
        if (s['exerciseId'] != exerciseId) continue;
        if (s['isDrop'] == true || s['isDropSet'] == 1) continue;

        final n = s['setNumber'];
        if (n is! int || n >= parentSetNumber) continue;

        final w = toDouble(s['weight']);
        if (w == null || w <= 0) continue;

        if (n > bestSet) {
          bestSet = n;
          best = w;
        }
      }

      return best;
    }

    // ---------- drop order ----------
    final orderFromLabel = parseOrder(dropLabel);
    final targetOrder = orderFromLabel ?? 1;

    // ---------- 1️⃣ explicit drop weight (logged) ----------
    for (final s in loggedSets) {
      if (s is! Map) continue;
      if (s['exerciseId'] != exerciseId) continue;
      if (s['setNumber'] != parentSetNumber) continue;
      if (s['isDrop'] != true && s['isDropSet'] != 1) continue;
      if (s['dropOrder'] != targetOrder) continue;

      final w = toDouble(s['weight']);
      if (w != null && w > 0) {
        return w.toInt();
      }
    }

    // ---------- 2️⃣ explicit drop weight (planned / state) ----------
    for (final d in dropSets) {
      if (d is! Map) continue;
      if (d['exerciseId'] != exerciseId) continue;
      if (d['parentSetNumber'] != parentSetNumber) continue;
      if (d['dropOrder'] != targetOrder) continue;

      final w = toDouble(d['weight']);
      if (w != null && w > 0) {
        return w.toInt();
      }
    }

    // ---------- 3️⃣ fallback: ALWAYS from parent ----------
    final parent = getParentWeight();
    if (parent == null || parent <= 0) return 0;

    final pct = ladderPercent(targetOrder);
    final raw = parent * (pct / 100.0);

    if (raw <= 0) return 0;

    // ---------- snap down ----------
    int snapDown(double v) {
      if (v <= 10.0) {
        final r = v.floor();
        return r > 0 ? r : 1;
      } else {
        final even = ((v / 2).floor()) * 2;
        return even > 0 ? even : 2;
      }
    }

    return snapDown(raw);
  }
}

Color getSetBackgroundColor(
  int setNumber,
  bool isDarkMode,
) {
  if (isDarkMode) {
    // DARK MODE COLORS
    if (setNumber % 2 == 0) {
      return const Color(0xFF1F2933); // זוגי - כהה יותר
    } else {
      return const Color(0xFF242F3D); // אי זוגי - קצת יותר בהיר
    }
  } else {
    // LIGHT MODE (כמו שהיה)
    if (setNumber % 2 == 0) {
      return const Color(0xFFF3F4F6);
    } else {
      return const Color(0xFFF9FAFB);
    }
  }
}

bool canAddNextDropSet(
  List<dynamic> loggedSets,
  int exerciseId,
  int baseSetNumber,
  bool allowsBodyweight,
) {
  {
    int _asInt(dynamic v) {
      if (v == null) return 0;
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse('$v') ?? 0;
    }

    double? _asDoubleOrNull(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      return double.tryParse('$v');
    }

    final related = loggedSets
        .where((r) =>
            r is Map &&
            _asInt(r['exerciseId']) == exerciseId &&
            _asInt(r['setNumber']) == baseSetNumber)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();

    if (related.isEmpty) return false;

    final parent = related.firstWhere(
      (r) => _asInt(r['isDropSet']) == 0,
      orElse: () => <String, dynamic>{},
    );

    if (parent.isEmpty) return false;
    if ((parent['isDone'] as bool?) == true) return false;

    final drops = related.where((r) => _asInt(r['isDropSet']) == 1).toList();

    if (drops.isEmpty) return true;

    drops.sort(
      (a, b) => _asInt(a['dropOrder']).compareTo(_asInt(b['dropOrder'])),
    );

    final lastDrop = drops.last;

    // תמיד דורשים חזרות
    if (_asInt(lastDrop['reps']) <= 0) return false;

    // דורשים משקל רק אם לא מאפשר bodyweight
    if (!allowsBodyweight) {
      final w = _asDoubleOrNull(lastDrop['weight']);
      if (w == null || w == 0) return false;
    }

    return true;
  }
}

bool canShowDeleteDropButton(
  List<dynamic> dropSets,
  int exerciseId,
  int parentSetNumber,
) {
  {
    final count = dropSets
        .where((r) =>
            r is Map &&
            r['exerciseId'] == exerciseId &&
            r['parentSetNumber'] == parentSetNumber)
        .length;

    return count > 1; // מציג כפתור מחיקה רק כשיש 2+ דרופים
  }
}

List<dynamic> formatWarmupSets(
  List<dynamic> warmupList,
  int exerciseId,
) {
  {
    List<Map<String, dynamic>> _toMapList(dynamic src) {
      if (src is! List) return <Map<String, dynamic>>[];
      return src
          .where((e) => e is Map)
          .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    }

    int _asInt(dynamic v, [int def = 0]) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v) ?? def;
      return def;
    }

    double _asDouble(dynamic v, [double def = 0.0]) {
      if (v is double) return v;
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v) ?? def;
      return def;
    }

    final list = _toMapList(warmupList);
    if (list.isEmpty) return [];

    final entry = list.firstWhere(
      (e) => _asInt(e['exerciseId']) == exerciseId,
      orElse: () => <String, dynamic>{}, // טיפוסי
    );
    final sets = _toMapList(entry['sets']);

    for (var i = 0; i < sets.length; i++) {
      final s = sets[i];

      // מספור מסודר לתצוגה
      s['setNumber'] = i + 1;

      // reps כנומרי לשימוש לוגי
      s['reps'] = _asInt(s['reps']);

      // repsText לטקסט/הינט בטבלה
      s['repsText'] = (s['repsText']?.toString().trim().isNotEmpty ?? false)
          ? s['repsText'].toString()
          : s['reps'].toString();

      // percent כ-double
      s['percent'] = _asDouble(s['percent']);

      // weight נשאר String?/null לתצוגה
      final w = s['weight'];
      s['weight'] =
          (w == null || w.toString().trim().isEmpty) ? null : w.toString();

      // דיפולט ל-isDone
      s['isDone'] = s['isDone'] ?? false;
    }

    return sets;
  }
}

double? suggestBumpedTarget(
  double? lastWeight,
  String equipment,
  bool isKg,
) {
  {
    // אין היסטוריה → אין הצעה
    if (lastWeight == null || lastWeight <= 0) return null;

    // עיגול ריאלי לפי ציוד ויחידות
    double roundForEquipment(double w, String eq, bool isKgUnits) {
      final t = eq.toLowerCase();
      if (t == 'dumbbell') {
        if (isKgUnits) {
          final step = (w < 10) ? 1.0 : 2.0;
          return ((w / step).roundToDouble() * step);
        } else {
          final step = (w < 25) ? 2.5 : 5.0;
          return ((w / step).roundToDouble() * step);
        }
      }
      // barbell / smith / machine
      return isKgUnits
          ? ((w / 2.5).roundToDouble() * 2.5)
          : ((w / 5.0).roundToDouble() * 5.0);
    }

    final t = equipment.toLowerCase();

    // חישוב הבאמפ הבסיסי
    double bump;
    if (t == 'dumbbell') {
      bump =
          isKg ? (lastWeight < 10 ? 1.0 : 2.0) : (lastWeight < 25 ? 2.5 : 5.0);
    } else {
      // barbell / smith / machine
      bump = isKg ? 2.5 : 5.0;
    }

    // מועמד + עיגול
    double candidate = lastWeight + bump;
    double suggested = roundForEquipment(candidate, equipment, isKg);

    // מינימום לברבל/סמית' (20kg / 45lb)
    if (t == 'barbell' || t == 'smith') {
      final minV = isKg ? 20.0 : 45.0;
      if (suggested < minV) suggested = minV;
    }

    return suggested;
  }
}

double? adjustWeight(
  double? currentWeight,
  String equipment,
  bool isKg,
  bool isIncrement,
) {
  {
    // --- נורמליזציה בסיסית ---
    final t = (equipment ?? '').trim().toLowerCase();

    // רשימות דאמבלים (משקל כולל לשתי משקולות)
    const dumbbellKg = <double>[
      4,
      5,
      6,
      7,
      8,
      9,
      10,
      12.5,
      14,
      16,
      18,
      20,
      22,
      24,
      26,
      28,
      30,
      32,
      34,
      36,
      38,
      40
    ];
    const dumbbellLb = <double>[
      8,
      10,
      12,
      14,
      16,
      18,
      20,
      25,
      30,
      35,
      40,
      45,
      50,
      55,
      60,
      65,
      70,
      75,
      80
    ];

    double round2(double v) => double.parse(v.toStringAsFixed(2));

    double nextFromList(double? curr, List<double> values, bool inc) {
      if (curr == null || curr == 0) return values.first;
      if (inc) {
        for (final v in values) if (v > curr) return v;
        return values.last;
      } else {
        for (int i = values.length - 1; i >= 0; i--)
          if (values[i] < curr) return values[i];
        return values.first;
      }
    }

    // --- 1) Dumbbell ---
    final isDumbbell = t == 'dumbbell';
    if (isDumbbell) {
      final list = isKg ? dumbbellKg : dumbbellLb;
      return round2(nextFromList(currentWeight, list, isIncrement));
    }

    // --- 2) Barbell/Smith (בדיוק!) ---
    final isBarLike = (t == 'barbell') || (t == 'smith machine');

    // מינימום וצעד לפי קטגוריה
    final double minWeight =
        isBarLike ? (isKg ? 20.0 : 45.0) : (isKg ? 5.0 : 10.0);
    final double step = isKg ? 2.5 : 5.0;

    // אם אין משקל קודם → תחילתי לפי הקטגוריה
    if (currentWeight == null || currentWeight == 0) return minWeight;

    // חישוב צעד למעלה/למטה + שמירה על גבולות
    double newW = isIncrement ? currentWeight + step : currentWeight - step;

    // עיגול למדרגת המשקולות (לבחירה, אפשר להסיר אם לא צריך)
    double roundToStep(double w, double s) => (w / s).roundToDouble() * s;
    newW = roundToStep(newW, step);

    if (newW < minWeight) newW = minWeight;
    return round2(newW);
  }
}

bool showWarmupCheckForSet(
  List<dynamic> warmupState,
  int exerciseId,
  int setNumber,
) {
  {
    int lastWarmupNumber = 0;

    for (final item in warmupState) {
      if (item is! Map) continue;

      // מחפשים רק סטים ששייכים לאותו תרגיל
      if (item['exerciseId'] == exerciseId) {
        final isWarmup = (item['isWarmup'] == true) ||
            (item['type']?.toString()?.toLowerCase() == 'warmup') ||
            (item['phase']?.toString()?.toLowerCase() == 'warmup');

        if (isWarmup) {
          final n = (item['setNumber'] is num)
              ? (item['setNumber'] as num).toInt()
              : 0;
          if (n > lastWarmupNumber) lastWarmupNumber = n;
        }
      }
    }

    if (lastWarmupNumber <= 0) return false;
    return setNumber == lastWarmupNumber;
  }
}

List<dynamic> parseSteps(String stepByStepText) {
  {
    if (stepByStepText.trim().isEmpty) return const [];

    try {
      final parsed = json.decode(stepByStepText);

      if (parsed is List) {
        return parsed.map((e) {
          if (e is Map) {
            return {
              'step': e['step'] ?? 0,
              'text': e['text']?.toString() ?? '',
            };
          } else if (e is String) {
            return {'step': 1, 'text': e};
          } else {
            return {'step': 1, 'text': e.toString()};
          }
        }).toList();
      } else if (parsed is Map) {
        return [
          {
            'step': parsed['step'] ?? 0,
            'text': parsed['text']?.toString() ?? '',
          }
        ];
      } else if (parsed is String) {
        return [
          {'step': 1, 'text': parsed}
        ];
      }
    } catch (_) {
      // אם לא JSON תקין – מחזיר פריט אחד מהטקסט הגולמי
      return [
        {'step': 1, 'text': stepByStepText}
      ];
    }

    return const [];
  }
}

List<String> parseFormTips(String formTipsText) {
  {
    if (formTipsText.trim().isEmpty) return const [];

    try {
      final parsed = json.decode(formTipsText);

      if (parsed is List) {
        return parsed.map((e) {
          if (e is String) return e;
          if (e is Map && e.containsKey('tip')) return e['tip'].toString();
          if (e is Map && e.containsKey('text')) return e['text'].toString();
          return e.toString();
        }).toList();
      }

      if (parsed is String) {
        return [parsed];
      }

      return [];
    } catch (_) {
      // אם לא JSON – נחזיר אותו כטיפ יחיד
      return [formTipsText];
    }
  }
}

String formatDropSetShort(
  int reps,
  double? weight,
  bool useKg,
) {
  {
    bool hasReps = reps != null && reps > 0;
    bool hasWeight = weight != null && weight! > 0;
    String unit = useKg ? 'Kg' : 'Lb';

    String fmtW(double w) {
      // שלם בלי נקודה; אחרת ספרה אחת וניקוי אפסים מיותרים
      return (w % 1 == 0)
          ? w.toInt().toString()
          : w.toStringAsFixed(1).replaceAll(RegExp(r'\.?0+$'), '');
    }

    if (hasReps && hasWeight) return '${reps!} × ${fmtW(weight!)} $unit';
    if (hasReps) return reps!.toString();
    if (hasWeight) return '${fmtW(weight!)} $unit';
    return '-';
  }
}

String buildSetErrorMessage(
  List<dynamic> loggedSets,
  List<dynamic> dropSets,
  int exerciseId,
  int setNumber,
  int? durationSecondsCandidate,
  bool isTimedExercise,
  bool allowsBodyweight,
  List<dynamic> exerciseSets,
) {
  {
    const String defaultError =
        'Cannot complete set – required data is missing or invalid.';

    try {
      // ================= helpers =================
      int asInt(dynamic v) {
        if (v == null) return 0;
        if (v is int) return v;
        if (v is num) return v.toInt();
        return int.tryParse(v.toString()) ?? 0;
      }

      double asDouble(dynamic v) {
        if (v == null) return 0;
        if (v is num) return v.toDouble();
        return double.tryParse(v.toString()) ?? 0;
      }

      bool truthy(dynamic v) {
        if (v == null) return false;
        if (v is bool) return v;
        if (v is num) return v != 0;
        final s = v.toString().toLowerCase();
        return s == 'true' || s == '1';
      }

      // =========================================================
      // 0️⃣ Resolve template
      // =========================================================
      int templateWeighted = 0;
      int templateTargetReps = 0;
      int templateDurationSeconds = 0;

      for (final e in exerciseSets) {
        if (e is! Map) continue;
        if (asInt(e['exerciseId']) != exerciseId) continue;

        final sets = e['sets'];
        if (sets is! List) continue;

        for (final s in sets) {
          if (s is! Map) continue;
          if (asInt(s['setNumber']) != setNumber) continue;

          templateWeighted = asInt(s['weighted']);
          templateTargetReps = asInt(s['targetReps']);
          templateDurationSeconds = asInt(s['durationSeconds']);
          break;
        }
      }

      // ירושת targetReps
      if (!isTimedExercise && templateTargetReps <= 0) {
        for (int i = setNumber - 1; i >= 1; i--) {
          for (final e in exerciseSets) {
            if (e is! Map) continue;
            if (asInt(e['exerciseId']) != exerciseId) continue;

            final sets = e['sets'];
            if (sets is! List) continue;

            for (final s in sets) {
              if (s is! Map) continue;
              if (asInt(s['setNumber']) == i && asInt(s['targetReps']) > 0) {
                templateTargetReps = asInt(s['targetReps']);
                break;
              }
            }
            if (templateTargetReps > 0) break;
          }
          if (templateTargetReps > 0) break;
        }
      }

      final bool requiresWeight =
          templateWeighted == 1 && allowsBodyweight == false;

      // =========================================================
      // 1️⃣ Drop sets
      // =========================================================
      for (final d in dropSets) {
        if (d is! Map) continue;
        if (asInt(d['exerciseId']) != exerciseId) continue;
        if (asInt(d['parentSetNumber']) != setNumber) continue;

        final order = asInt(d['dropOrder']);
        final targetReps = asInt(d['reps']);

        Map? logged;
        for (final l in loggedSets) {
          if (l is! Map) continue;
          if (asInt(l['exerciseId']) != exerciseId) continue;
          if (asInt(l['setNumber']) != setNumber) continue;
          if (!truthy(l['isDropSet'])) continue;
          if (asInt(l['dropOrder']) != order) continue;
          logged = l;
          break;
        }

        final reps = logged != null ? asInt(logged['reps']) : targetReps;
        final weight =
            logged != null ? asDouble(logged['weight']) : asDouble(d['weight']);

        if (reps <= 0) {
          return 'Cannot complete set – reps must be greater than 0 in drop set $order.';
        }

        if (requiresWeight && weight <= 0) {
          return 'Cannot complete set – weight must be greater than 0 in drop set $order.';
        }
      }

      // =========================================================
      // 2️⃣ Base set
      // =========================================================
      Map? base;
      for (final l in loggedSets) {
        if (l is! Map) continue;
        if (asInt(l['exerciseId']) != exerciseId) continue;
        if (asInt(l['setNumber']) != setNumber) continue;
        if (truthy(l['isDropSet'])) continue;
        base = l;
        break;
      }

      final repsNow = base != null ? asInt(base['reps']) : 0;
      final weightNow = base != null ? asDouble(base['weight']) : 0;
      final durNow = base != null ? asInt(base['durationSeconds']) : 0;

      // =========================================================
      // ⏱️ Timed
      // =========================================================
      if (isTimedExercise) {
        if (durNow <= 0 &&
            templateDurationSeconds <= 0 &&
            (durationSecondsCandidate ?? 0) <= 0) {
          return 'Cannot complete set – duration must be greater than 0.';
        }
        return '';
      }

      // =========================================================
      // 🔢 Reps
      // =========================================================
      if (repsNow <= 0 && templateTargetReps <= 0) {
        return 'Cannot complete set – reps must be greater than 0.';
      }

      // =========================================================
      // ⚖️ Weight
      // =========================================================
      if (requiresWeight && weightNow <= 0) {
        return 'Cannot complete set – weight must be greater than 0.';
      }

      // =========================================================
      // ✅ OK
      // =========================================================
      return '';
    } catch (e) {
      // 🔥 שריון סופי – אין מסך אפור
      return defaultError;
    }
  }
}

bool isLastWarmupSet(
  List<dynamic> warmupList,
  int exerciseId,
  int setNumber,
) {
  {
    // מחפש את הכניסה עבור התרגיל
    final entry =
        warmupList.map((e) => Map<String, dynamic>.from(e)).firstWhere(
              (e) => e['exerciseId'] == exerciseId,
              orElse: () => {},
            );

    if (entry.isEmpty || entry['sets'] == null) return false;

    final sets = List<Map<String, dynamic>>.from(entry['sets']);
    final lastSetNumber = sets.length;

    return setNumber == lastSetNumber;
  }
}

Color getWarmupBackgroundColorFromState(
  int warmupIndex,
  int exerciseId,
  List<dynamic> wormupList,
) {
  // אותם צבעים כמו בסט רגיל
  const Color cA = Color(0xFFF3F4F6); // כהה מעט
  const Color cB = Color(0xFFF9FAFB); // בהיר מעט

// ----- helpers -----
  int? _toInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v);
    return null;
  }

  bool _isForExercise(dynamic item, int exerciseId) {
    if (item is! Map) return false;

    // ישיר: exerciseId / exercise_id / exerciseID
    for (final k in ['exerciseId', 'exercise_id', 'exerciseID']) {
      if (item.containsKey(k)) {
        final id = _toInt(item[k]);
        if (id != null && id == exerciseId) return true;
      }
    }
    // מקונן: {"exercise": {"id": 123}}
    final ex = item['exercise'];
    if (ex is Map) {
      final id = _toInt(ex['id']);
      if (id != null && id == exerciseId) return true;
    }
    return false;
  }

// כמה סטים חימום עבור התרגיל הזה
  final int warmupCount =
      wormupList.where((w) => _isForExercise(w, exerciseId)).length;

// אם אין חימום — ברירת מחדל
  if (warmupCount <= 0) {
    return cA;
  }

// נרמול אינדקס (הפרמטרים הם final, לכן עובדים עם משתנה מקומי)
  int idx = warmupIndex;
  if (idx < 1) idx = 1;
  if (idx > warmupCount) idx = warmupCount;

// מטרה: הסט האחרון בחימום תמיד יהיה cA,
// כדי שהסט הרגיל הראשון (שאצלך cB) לא יתנגש בצבע.
  final bool startWithA = (warmupCount % 2 == 1); // אי-זוגי -> מתחילים ב-A
  final bool isOdd = (idx % 2 == 1);

  return startWithA
      ? (isOdd ? cA : cB) // רצף: A, B, A, B...
      : (isOdd ? cB : cA); // רצף: B, A, B, A...
}

String formatDouble(double value) {
  {
    if (value % 1 == 0) {
      // שלם לגמרי – מציג בלי .0
      return value.toInt().toString();
    } else {
      // יש חלק עשרוני – נשמור עליו
      return value.toString();
    }
  }
}

String relativeTimeFromLocalString(String createdAt) {
  {
    if (createdAt.trim().isEmpty) return '-';

    DateTime dt;
    try {
      dt = DateFormat('yyyy-MM-dd HH:mm:ss').parseStrict(createdAt).toLocal();
    } catch (_) {
      return createdAt; // fallback אם לא הצליח לפרש
    }

    final DateTime current = DateTime.now();
    final diff = current.difference(dt);

    if (diff.inMinutes < 60) {
      return 'Less than an hour ago';
    } else if (diff.inHours < 24) {
      final h = diff.inHours;
      return '$h ${h == 1 ? 'hour' : 'hours'} ago';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      final d = diff.inDays;
      return '$d ${d == 1 ? 'day' : 'days'} ago';
    } else {
      return DateFormat('MMM d, yyyy').format(dt);
    }
  }
}

List<dynamic> getRawVolumeDataFromRows(
  List<VolumeOverviewRow> data,
  String rangeType,
) {
  {
    final fmt = DateFormat('yyyy-MM-dd HH:mm:ss');
    final now = DateTime.now();

    int daysFor(String rt) {
      switch (rt.trim()) {
        case 'Last 7 Days':
          return 7;
        case 'Last 30 Days':
          return 30;
        case 'Last 90 Days':
          return 90;
        case 'All':
        default:
          return 10000; // בלי הגבלה מעשית
      }
    }

    bool withinRange(DateTime d) {
      final maxDays = daysFor(rangeType);
      if (maxDays >= 10000) return true;
      return now.difference(d).inDays <= maxDays;
    }

    final points = <Map<String, dynamic>>[];

    for (final row in data) {
      final createdAtStr = row.data['createdAt'] as String?;
      final volNum = row.data['volume'] as num?;
      if (createdAtStr == null || volNum == null) continue;

      DateTime dt;
      try {
        dt = fmt.parseStrict(createdAtStr).toLocal();
      } catch (_) {
        continue; // דילוג על שורה לא תקינה
      }

      if (!withinRange(dt)) continue;

      points.add({
        // ציר X מספרי (מילישניות מאז 1970) – עובד מצוין בגרפים
        'x': dt.millisecondsSinceEpoch.toDouble(),
        // ציר Y = הווליום
        'y': volNum.toDouble(),
        // תווית נוחה לציר/tooltip
        'date_label': DateFormat('MMM d').format(dt),
      });
    }

    // לשמור על סדר כרונולוגי
    points.sort((a, b) => (a['x'] as double).compareTo(b['x'] as double));
    return points;
  }
}

double calcProgressRatio(
  int setsForMuscle,
  int totalSetsInWorkout,
) {
  {
    if (totalSetsInWorkout <= 0) {
      return 0.0;
    }
    return setsForMuscle / totalSetsInWorkout;
  }
}

int countWorkoutsForRange2(
  List<WorkoutCountRow> workouts,
  String timeRange,
) {
  {
    DateTime? _parseLocal(String? s) {
      if (s == null) return null;
      final v = s.trim();
      if (v.isEmpty) return null;
      // תומך גם ב-"YYYY-MM-DD HH:MM:SS" וגם ב-ISO עם 'T'/'Z'
      return DateTime.tryParse(v) ??
          DateTime.tryParse(v.replaceFirst(' ', 'T'));
    }

    if (timeRange == 'All') return workouts.length;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // from כולל, to בלעדי
    late DateTime from;
    final DateTime to = today.add(const Duration(days: 1));

    switch (timeRange) {
      case 'Last 7 Days':
        from = today.subtract(const Duration(days: 6)); // כולל היום
        break;
      case 'Last 30 Days':
        from = today.subtract(const Duration(days: 29));
        break;
      case 'Last 90 Days':
        from = today.subtract(const Duration(days: 89));
        break;
      default:
        // אם נשלח ערך לא צפוי — נספור הכל
        return workouts.length;
    }

    int count = 0;
    for (final row in workouts) {
      final createdAtStr = row.data['createdAt']?.toString();
      final dt = _parseLocal(createdAtStr);
      if (dt == null) continue;
      if (!dt.isBefore(from) && dt.isBefore(to)) count++;
    }
    return count;
  }
}

int totalVolumeForRange(
  List<WorkoutCountRow> workouts,
  String timeRange,
) {
  {
    DateTime? _parseLocal(String? s) {
      if (s == null) return null;
      final v = s.trim();
      if (v.isEmpty) return null;
      // תומך גם ב-"YYYY-MM-DD HH:MM:SS" וגם ב-ISO עם 'T'/'Z'
      return DateTime.tryParse(v) ??
          DateTime.tryParse(v.replaceFirst(' ', 'T'));
    }

    int _toInt(dynamic v) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v) ?? 0;
      return 0;
    }

    if (timeRange == 'All') {
      int sum = 0;
      for (final r in workouts) {
        sum += _toInt(r.data['volume']);
      }
      return sum;
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // from כולל, to בלעדי
    late DateTime from;
    final DateTime to = today.add(const Duration(days: 1));

    switch (timeRange) {
      case 'Last 7 Days':
        from = today.subtract(const Duration(days: 6));
        break;
      case 'Last 30 Days':
        from = today.subtract(const Duration(days: 29));
        break;
      case 'Last 90 Days':
        from = today.subtract(const Duration(days: 89));
        break;
      default:
        // אם התקבל ערך לא צפוי — נסכם הכל
        int sum = 0;
        for (final r in workouts) {
          sum += _toInt(r.data['volume']);
        }
        return sum;
    }

    int sum = 0;
    for (final r in workouts) {
      final createdAtStr = r.data['createdAt']?.toString();
      final dt = _parseLocal(createdAtStr);
      if (dt == null) continue;
      if (!dt.isBefore(from) && dt.isBefore(to)) {
        sum += _toInt(r.data['volume']);
      }
    }
    return sum;
  }
}

List<dynamic> buildExerciseTableFromSets(List<dynamic> exerciseSets) {
// Return: JSON (isList=true)
  {
    if (exerciseSets == null) return [];

    final rows = <Map<String, dynamic>>[];

    for (var i = 0; i < exerciseSets.length; i++) {
      final item = Map<String, dynamic>.from(exerciseSets[i] ?? {});
      final exId = item['exerciseId'];
      if (exId == null) continue;

      final ord = (item['orderIndex'] ?? (i + 1)) as int;
      final setsRaw = item['sets'];
      final sets = (setsRaw is List)
          ? List<Map<String, dynamic>>.from(setsRaw)
          : <Map<String, dynamic>>[];

      // חישובי עזר קלים לשורה
      final totalSets = sets.length;
      var completed = 0;
      for (final s in sets) {
        final m = Map<String, dynamic>.from(s ?? {});
        if ((m['isChecked'] ?? false) == true) completed++;
      }
      final isCompleted = totalSets > 0 && completed == totalSets;

      rows.add({
        'exerciseId': exId,
        'orderIndex': ord,
        'totalSets': totalSets,
        'completedSets': completed,
        'isCompleted': isCompleted,
      });
    }

    rows.sort(
        (a, b) => (a['orderIndex'] as int).compareTo(b['orderIndex'] as int));
    return rows;
  }
}

String formatNiceDate(String timeStamp) {
  {
    DateTime? _parseToLocal(String? input) {
      if (input == null) return null;
      var s = input.trim();
      if (s.isEmpty) return null;

      // מספר מילישניות (epoch)
      final onlyDigits = RegExp(r'^\d+$');
      if (onlyDigits.hasMatch(s)) {
        final ms = int.tryParse(s);
        if (ms != null) {
          return DateTime.fromMillisecondsSinceEpoch(ms).toLocal();
        }
      }

      // SQLite "YYYY-MM-DD HH:MM(:SS)" -> ISO
      final sqliteRe = RegExp(r'^(\d{4}-\d{2}-\d{2}) (\d{2}:\d{2}(:\d{2})?)$');
      if (sqliteRe.hasMatch(s)) s = s.replaceFirst(' ', 'T');

      // parse רגיל
      try {
        return DateTime.parse(s).toLocal();
      } catch (_) {
        // ניסיון ידני אחרון
        final m = RegExp(
          r'^(\d{4})-(\d{2})-(\d{2})[ T](\d{2}):(\d{2})(?::(\d{2}))?$',
        ).firstMatch(s);
        if (m != null) {
          return DateTime(
            int.parse(m.group(1)!),
            int.parse(m.group(2)!),
            int.parse(m.group(3)!),
            int.parse(m.group(4)!),
            int.parse(m.group(5)!),
            int.parse(m.group(6) ?? '0'),
          ).toLocal();
        }
      }
      return null;
    }

    final dt = _parseToLocal(timeStamp);
    if (dt == null) return '';

    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inSeconds < 45) return 'a moment ago';
    if (diff.inMinutes < 1) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';

    final isSameDay =
        now.year == dt.year && now.month == dt.month && now.day == dt.day;
    if (isSameDay) return 'Today ${DateFormat('HH:mm').format(dt)}';

    final yest = now.subtract(const Duration(days: 1));
    final isYesterday =
        yest.year == dt.year && yest.month == dt.month && yest.day == dt.day;
    if (isYesterday) return 'Yesterday ${DateFormat('HH:mm').format(dt)}';

    final sameYear = now.year == dt.year;
    final pattern = sameYear ? 'EEE, MMM d • HH:mm' : 'EEE, MMM d, y • HH:mm';
    try {
      return DateFormat(pattern).format(dt);
    } catch (_) {
      return dt.toLocal().toString();
    }
  }
}

String formatCompactNumber(double? value) {
  // Compact number: 950 -> "950", 1_240 -> "1.2K", 2_500_000 -> "2.5M"
  {
    // אם אין ערך → מקף
    if (value == null) return '-';
    if (value.isNaN || value.isInfinite) return '-';

    final bool isNeg = value < 0;
    double n = value.abs();

    // < 1000: מציגים מספר שלם
    if (n < 1000) {
      final s = n.round().toString();
      return '${isNeg ? '-' : ''}$s';
    }

    // בחירת סיומת וחלוקה
    String suffix;
    double div;
    if (n >= 1e9) {
      suffix = 'B';
      div = 1e9;
    } else if (n >= 1e6) {
      suffix = 'M';
      div = 1e6;
    } else {
      suffix = 'K';
      div = 1e3;
    }

    double scaled = n / div;

    // שומר ספרה עשרונית אחת רק כשצריך; מעל 10 ללא עשרוני
    String out;
    if (scaled >= 10) {
      out = scaled.round().toString();
    } else {
      final rounded1 = (scaled * 10).round() / 10.0;
      out = rounded1.toStringAsFixed(1);
      if (out.endsWith('.0')) out = out.substring(0, out.length - 2);
    }

    return '${isNeg ? '-' : ''}$out$suffix';
  }
}

String? formatDurationSmart(int millis) {
  {
    if (millis == null || millis <= 0) return '0m';

    final d = Duration(milliseconds: millis);
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    final seconds = d.inSeconds.remainder(60);

    if (hours >= 1) {
      // Classic HH:MM
      return '$hours:${minutes.toString().padLeft(2, '0')}';
    } else if (d.inMinutes >= 1) {
      return '${d.inMinutes}m';
    } else {
      return '${seconds}s';
    }
  }
}

bool isExerciseSuperset(
  List<dynamic> exerciseSets,
  int exerciseId,
) {
  {
    int? toIntId(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v.trim());
      return null;
    }

    for (final item in exerciseSets) {
      if (item is! Map) continue;

      final id = toIntId(item['exerciseId'] ?? item['exercise_id']);
      if (id != exerciseId) continue;

      final isSup = item['isSuperset'];
      if (isSup == true || isSup == 1) return true;
      if (item['supersetSeq'] != null) return true;
      return false;
    }

    return false;
  }
}

bool shouldStartRestTimer(
  List<dynamic> exerciseSets,
  int exerciseId,
  bool restTimeEnabled,
) {
  {
    // אם הטיימר מבוטל ברמת הקומפוננטה – לא מפעילים בכל מקרה
    if (restTimeEnabled != true) return false;

    // חיפוש התרגיל ברשימה
    Map<String, dynamic>? item;
    for (final it in exerciseSets) {
      final m = Map<String, dynamic>.from(it as Map);
      final id = m['exerciseId'] ?? m['id'];
      if (id == exerciseId) {
        item = m;
        break;
      }
    }
    if (item == null) return true; // לא נמצא? לא חוסמים טיימר

    final bool isSuperset = item['isSuperset'] == true;

    // המרה בטוחה ל-int (אם נשמר כמחרוזת/דינמי)
    int? seq;
    final seqRaw = item['supersetSeq'];
    if (seqRaw is int) {
      seq = seqRaw;
    } else if (seqRaw is String) {
      seq = int.tryParse(seqRaw);
    }

    // אם זה סופר-סט והתור הוא הראשון → לא מפעילים
    final bool isFirstInSuperset = isSuperset && (seq == 1);
    if (isFirstInSuperset) return false;

    // אחרת מפעילים
    return true;
  }
}

bool shouldShowWorkoutSimple(
  String workoutName,
  String? query,
  String selectedMuscle,
  String musclesJoined,
) {
  {
    // Normalization
    String norm(String? s) =>
        (s ?? '').toLowerCase().trim().replaceAll(RegExp(r'\s+'), ' ');

    final name = norm(workoutName);
    final q = norm(query);
    final muscle = norm(selectedMuscle);
    final muscles = norm(musclesJoined);

    // 1) התאמה לשם (אם החיפוש ריק – תמיד עובר)
    final bool nameMatch = q.isEmpty ? true : name.contains(q);

    // 2) התאמה לשריר
    // אם לא נבחר שריר / "all" -> עובר.
    bool muscleMatch = true;
    if (muscle.isNotEmpty && muscle != 'all') {
      // בדיקת תת־מחרוזת בתוך טקסט השרירים המחוברים (רגיש חלקית)
      muscleMatch = muscles.contains(muscle);
    }

    return nameMatch && muscleMatch;
  }
}

bool shouldDisableFinishButton(List<dynamic> loggedSets) {
// Return type: bool
  {
    if (loggedSets == null || loggedSets.isEmpty) return true;

    for (final s in loggedSets) {
      if (s is Map && (s['isDone'] == true)) {
        return false; // יש לפחות סט אחד שסומן, לא לדיסאבל
      }
    }
    return true; // אף סט לא מסומן -> לכפתור להיות Disabled
  }
}

String tickClock(String current) {
  {
    int h = 0, m = 0, s = 0;

    final parts = (current.trim()).split(':');
    if (parts.length == 2) {
      m = int.tryParse(parts[0]) ?? 0;
      s = int.tryParse(parts[1]) ?? 0;
    } else if (parts.length == 3) {
      h = int.tryParse(parts[0]) ?? 0;
      m = int.tryParse(parts[1]) ?? 0;
      s = int.tryParse(parts[2]) ?? 0;
    } else {
      // fallback from anything invalid
      h = 0;
      m = 0;
      s = 0;
    }

    int total = (h * 3600) + (m * 60) + s + 1;
    if (total < 0) total = 0;

    final nh = total ~/ 3600;
    final rem = total % 3600;
    final nm = rem ~/ 60;
    final ns = rem % 60;

    // mm:ss until an hour, then h:mm:ss
    return nh > 0
        ? '$nh:${nm.toString().padLeft(2, '0')}:${ns.toString().padLeft(2, '0')}'
        : '${nm.toString().padLeft(2, '0')}:${ns.toString().padLeft(2, '0')}';
  }
}

int clockTextToMillis(String text) {
  {
    if (text.isEmpty) return 0;

    // Keep only digits and colons
    final cleaned = text.trim().replaceAll(RegExp(r'[^0-9:]'), '');
    if (cleaned.isEmpty) return 0;

    final parts = cleaned.split(':');

    int h = 0, m = 0, s = 0;
    if (parts.length == 2) {
      m = int.tryParse(parts[0]) ?? 0;
      s = int.tryParse(parts[1]) ?? 0;
    } else if (parts.length == 3) {
      h = int.tryParse(parts[0]) ?? 0;
      m = int.tryParse(parts[1]) ?? 0;
      s = int.tryParse(parts[2]) ?? 0;
    } else if (parts.length == 1) {
      // Fallback: treat as seconds only
      s = int.tryParse(parts[0]) ?? 0;
    } else {
      return 0;
    }

    final totalSeconds = (h * 3600) + (m * 60) + s;
    return totalSeconds < 0 ? 0 : totalSeconds * 1000;
  }
}

int getRestSecondsForExercise(
  dynamic restDurations,
  int exerciseId,
) {
  {
    final key = exerciseId.toString();

    if (restDurations is Map<String, dynamic>) {
      final value = restDurations[key];

      if (value is int) {
        return (value / 1000).ceil(); // המרה ממילישניות לשניות
      }

      if (value is String) {
        final parsed = int.tryParse(value);
        if (parsed != null) {
          return (parsed / 1000).ceil();
        }
      }
    }

    // ברירת מחדל: 90000 מ״ש = 90 שניות
    return 90;
  }
}

int msToSeconds(int milliseconds) {
  {
    return (milliseconds / 1000).floor();
  }
}

bool showPlusButton(
  int exerciseId,
  int setNumber,
  List<dynamic> loggedSets,
  List<dynamic> exerciseSets,
  bool isTimed,
) {
  {
    // ---------- helpers ----------
    int _toInt(dynamic v) {
      if (v is int) return v;
      if (v is double) return v.round();
      if (v is String) return int.tryParse(v) ?? 0;
      return 0;
    }

    bool _toBool(dynamic v) {
      if (v is bool) return v;
      if (v is num) return v != 0;
      if (v is String) {
        final t = v.toLowerCase();
        return t == 'true' || t == '1';
      }
      return false;
    }

    Map<String, dynamic>? _asMap(dynamic v) {
      if (v is Map) {
        try {
          return Map<String, dynamic>.from(v);
        } catch (_) {}
      }
      return null;
    }

    Map<String, dynamic>? _firstMapWhere(
      List<dynamic> list,
      bool Function(Map<String, dynamic>) test,
    ) {
      for (final item in list) {
        final m = _asMap(item);
        if (m != null && test(m)) return m;
      }
      return null;
    }

    // נוודא ש-loggedSets לא יהיה null
    final ls = loggedSets ?? const <dynamic>[];

    // --- isDone מתוך loggedSets (בטוח) ---
    final logMatch = _firstMapWhere(
      ls,
      (m) =>
          _toInt(m['exerciseId'] ?? m['exercise_id']) == exerciseId &&
          _toInt(m['setNumber'] ?? m['set_number']) == setNumber,
    );
    final isDone = _toBool(logMatch?['isDone'] ?? logMatch?['done']);

    // --- weighted מתוך exerciseSets (בטוח; עם תאימות ל-showWeightField) ---
    final exMatch = _firstMapWhere(
      exerciseSets,
      (e) => _toInt(e['exerciseId'] ?? e['exercise_id']) == exerciseId,
    );

    bool weighted = false; // ברירת מחדל
    if (exMatch != null) {
      final sets =
          (exMatch['sets'] is List) ? (exMatch['sets'] as List) : const [];
      final setTpl = _firstMapWhere(
        sets,
        (s) => _toInt(s['setNumber'] ?? s['set_number']) == setNumber,
      );
      if (setTpl != null) {
        // primary: weighted ; fallback: showWeightField (תאימות לאחור)
        weighted = _toBool(setTpl['weighted'] ?? setTpl['showWeightField']);
      }
    }

    // פלוס מוצג רק אם: הסט לא Done, לא Timed (חיצוני), ולא weighted
    return !isDone && !isTimed && !weighted;
  }
}

List<dynamic> getSetsForEditWorkout(
  int exerciseId,
  List<dynamic> exerciseSets,
) {
  {
    /// מחזירה את רשימת הסטים של תרגיל מסוים מתוך exerciseSets
    /// כולל הערכים מהאימון (reps, weight, duration וכו')

    final match = exerciseSets.firstWhere(
      (e) => e['exerciseId'] == exerciseId,
      orElse: () => null,
    );

    if (match == null) return [];

    // מחזיר את כל הסטים כמו שנשמרו ב-initializeExerciseSetsFromGetAllSets
    return List<Map<String, dynamic>>.from(match['sets'] ?? []);
  }
}

bool shouldShowExercise2(
  String? query,
  String exerciseName,
) {
  final q = (query ?? '').toString().trim().toLowerCase();
  if (q.isEmpty) return true; // בלי חיפוש – מציגים הכל

  final name = (exerciseName ?? '').toString().trim().toLowerCase();
  if (name.isEmpty) return false; // אין שם תרגיל – לא מציגים

  return name.contains(q); // התאמה חלקית לא רגיש לאותיות
}

/// Calculates the angle in degrees between three landmarks
double angle(
  LandmarkStruct a,
  LandmarkStruct b,
  LandmarkStruct c,
) {
  //  Calculate vector BA
  final ba = [a.xValue - b.xValue, a.yValue - b.yValue];
  // Calculate vector BC
  final bc = [c.xValue - b.xValue, c.yValue - b.yValue];
  // Calculate denominator for cosine
  final den = (math.sqrt(ba[0] * ba[0] + ba[1] * ba[1]) *
          math.sqrt(bc[0] * bc[0] + bc[1] * bc[1])) +
      1e-9;
  // Calculate cosine of the angle
  final cos = ((ba[0] * bc[0] + ba[1] * bc[1]) / den).clamp(-1.0, 1.0);
  // Return angle in degrees
  return math.acos(cos) * 180.0 / math.pi;
}

/// Calculates exponential moving average
double? ema(
  double? prev,
  double next,
  double a,
) {
  if (prev == null) return next;
  return a * next + (1 - a) * prev;
}

/// Calculates Euclidean distance between two landmarks
double? dist(
  LandmarkStruct a,
  LandmarkStruct b,
) {
  return math.sqrt(
      math.pow(a.xValue - b.xValue, 2) + math.pow(a.yValue - b.yValue, 2));
}

double workoutProgress(
  List<dynamic> exerciseSets,
  List<dynamic> loggedSets,
) {
  {
    // --- helper ---
    bool _truthy(dynamic v) {
      if (v == null) return false;
      if (v is bool) return v;
      if (v is num) return v != 0;
      final s = v.toString().toLowerCase();
      return s == 'true' || s == '1';
    }

    // --- build DONE set: (exerciseId, setNumber) ---
    final doneSetKeys = <String>{};

    for (final row in loggedSets) {
      if (row is! Map) continue;

      final isDone = _truthy(row['isDone'] ?? row['isChecked']);
      if (!isDone) continue;

      final exId = row['exerciseId'];
      final sn = row['setNumber'];

      if (exId != null && sn != null) {
        doneSetKeys.add('$exId#$sn');
      }
    }

    // --- count total + done from TEMPLATE ---
    int totalSets = 0;
    int doneSets = 0;

    for (final ex in exerciseSets) {
      if (ex is! Map || ex['sets'] is! List) continue;

      final exerciseId = ex['exerciseId'];
      final sets = ex['sets'] as List;

      for (final s in sets) {
        if (s is! Map) continue;

        final sn = s['setNumber'];
        if (exerciseId == null || sn == null) continue;

        totalSets++;

        final key = '$exerciseId#$sn';
        if (doneSetKeys.contains(key)) {
          doneSets++;
        }
      }
    }

    if (totalSets == 0) return 0.0;
    return (doneSets / totalSets).clamp(0.0, 1.0);
  }
}

bool exerciseHasLoggedValuesFlat(
  List<dynamic> flatSets,
  int exerciseId,
) {
  {
    for (final s in flatSets) {
      if (s is! Map) continue;

      final exId = s['exerciseId'] ?? s['exercise_id'] ?? s['id'];
      final id = (exId is int) ? exId : int.tryParse(exId?.toString() ?? '');

      if (id != exerciseId) continue;

      final reps = (s['reps'] is int)
          ? s['reps'] as int
          : int.tryParse('${s['reps']}') ?? 0;
      final durationMs = (s['durationMs'] is int)
          ? s['durationMs'] as int
          : int.tryParse('${s['durationMs']}') ?? 0;
      final weighted = (s['weighted'] == true);
      final weight = (weighted && s['weight'] != null)
          ? (s['weight'] is num
              ? (s['weight'] as num).toDouble()
              : double.tryParse('${s['weight']}') ?? 0.0)
          : 0.0;

      // יש ערכים אם אחד מהשדות חיובי
      if (reps > 0 || durationMs > 0 || weight > 0.0) {
        return true;
      }
    }

    return false;
  }
}

List<int> getExerciseOrderIds(List<dynamic> exerciseSets) {
  {
    final ids = <int>[];

    for (final e in exerciseSets) {
      if (e is! Map) continue;

      final exId = e['exerciseId'] ?? e['exercise_id'] ?? e['id'];
      int? id;
      if (exId is int) {
        id = exId;
      } else if (exId is String && exId.trim().isNotEmpty) {
        id = int.tryParse(exId.trim());
      }

      if (id != null && !ids.contains(id)) {
        ids.add(id);
      }
    }

    return ids;
  }
}

List<int> reorderByIndex(
  List<int> order,
  int oldIndex,
  int newIndex,
) {
  {
    final o = List<int>.from(order);
    if (newIndex > oldIndex) newIndex -= 1; // כלל Flutter
    final item = o.removeAt(oldIndex);
    o.insert(newIndex, item);
    return o;
  }
}

List<ListsRow> supabaseRowsToList(List<dynamic> supabaseRows) {
  return supabaseRows.map((r) => ListsRow(r)).toList();
}

List<dynamic> buildChartDataForRange(
  List<VolumeOverviewRow> rawRows,
  String rangeLabel,
) {
  {
    final now = DateTime.now();
    DateTime? start;

    // Range filter
    switch (rangeLabel) {
      case 'Last 7 Days':
        start = now.subtract(const Duration(days: 7));
        break;
      case 'Last 30 Days':
        start = now.subtract(const Duration(days: 30));
        break;
      case 'Last 90 Days':
        start = now.subtract(const Duration(days: 90));
        break;
      case 'All':
      default:
        start = null;
    }

    final filtered = <Map<String, dynamic>>[];

    for (final row in rawRows) {
      final dateStr = (row.workoutDate ?? '').toString();
      if (dateStr.isEmpty) continue;

      // Parse the date
      DateTime? d = DateTime.tryParse(dateStr);

      // Fix for "YYYY-MM-DD HH:mm:ss"
      if (d == null && dateStr.contains(' ')) {
        final cleaned = dateStr.replaceAll(' ', 'T');
        d = DateTime.tryParse(cleaned);
      }

      // Fallback for plain YYYY-MM-DD
      d ??= DateTime.tryParse('${dateStr}T00:00:00');

      if (d == null) continue;

      // Range filtering
      if (start != null && d.isBefore(start)) continue;

      // Volume
      final vol = row.workoutVolume;
      final volNum =
          vol is num ? vol.toDouble() : double.tryParse(vol.toString()) ?? 0.0;

      // NORMALIZED DATE KEY (YYYY-MM-DD)
      final dateKey = '${d.year.toString().padLeft(4, '0')}-'
          '${d.month.toString().padLeft(2, '0')}-'
          '${d.day.toString().padLeft(2, '0')}';

      filtered.add({
        'date': dateKey,
        'volume': volNum,
      });
    }

    // Group by normalized date
    final byDate = <String, double>{};
    for (final it in filtered) {
      final k = it['date'] as String;
      final v = (it['volume'] as num).toDouble();
      byDate[k] = (byDate[k] ?? 0.0) + v;
    }

    // Sort & return
    final out = byDate.entries
        .map((e) => {
              'date': e.key,
              'volume': double.parse(e.value.toStringAsFixed(1)),
            })
        .toList()
      ..sort((a, b) => (a['date'] as String).compareTo(b['date'] as String));

    return out;
  }
}

bool shouldShowTemplate(
  String dropdownValue,
  String mainMuscles,
) {
  {
    final filter = dropdownValue.trim().toLowerCase();
    final muscles = mainMuscles.trim();

    // תמיד להציג אימון פול-באדי
    if (muscles.toLowerCase() == 'full body') {
      return true;
    }

    // בלי סינון או "All" -> מציגים הכל
    if (filter.isEmpty || filter == 'all') {
      return true;
    }

    // אין מידע על שרירים -> לא מציגים
    if (muscles.isEmpty) {
      return false;
    }

    // מפרקים את המחרוזת של השרירים לכינויים בודדים (פסיקים / סלש / פייפ)
    final tokens = muscles
        .split(RegExp(r'[,\|/]+'))
        .map((s) => s.trim().toLowerCase())
        .where((s) => s.isNotEmpty)
        .toList();

    // התאמה מדויקת לפי טוקן (כדי ש"core" לא יתפוס "forearms")
    return tokens.contains(filter);
  }
}

String correctedFormatPreviousSet(
  int? reps,
  double? weight,
  int? durationSeconds,
  bool useKg,
) {
  {
    // Duration formatting (already in seconds from SQL)
    if (durationSeconds != null && durationSeconds > 0) {
      final m = (durationSeconds ~/ 60).toString().padLeft(2, '0');
      final s = (durationSeconds % 60).toString().padLeft(2, '0');
      return "$m:$s";
    }

    // Weight + Reps
    if (weight != null && weight > 0 && reps != null && reps > 0) {
      final unit = useKg ? "kg" : "lb";
      final w = (weight % 1 == 0)
          ? weight.toInt().toString()
          : weight.toStringAsFixed(1).replaceAll(RegExp(r'\.?0+$'), '');
      return "$w $unit × $reps";
    }

    // Reps only (bodyweight exercises)
    if (reps != null && reps > 0) {
      return "$reps reps";
    }

    // Weight only (rare case)
    if (weight != null && weight > 0) {
      final unit = useKg ? "kg" : "lb";
      final w = (weight % 1 == 0)
          ? weight.toInt().toString()
          : weight.toStringAsFixed(1).replaceAll(RegExp(r'\.?0+$'), '');
      return "$w $unit";
    }

    // No previous data
    return "-";
  }
}

List<WorkoutRow> supabaseRowsToWorkout(List<dynamic> supabaseRows) {
  return supabaseRows.map((r) => WorkoutRow(r)).toList();
}

List<dynamic> toggleExerciseSelection(
  List<dynamic>? selected,
  int exerciseId,
  String exerciseName,
) {
  {
    // רשימה ריקה אם null
    final List<Map<String, dynamic>> updated = (selected ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();

    // בודק אם התרגיל כבר קיים ברשימה
    final existsIndex = updated.indexWhere(
      (e) => e['exerciseId'] == exerciseId,
    );

    if (existsIndex >= 0) {
      // קיים → מוחקים
      updated.removeAt(existsIndex);
    } else {
      // לא קיים → מוסיפים עם ID + NAME
      updated.add({
        'exerciseId': exerciseId,
        'exerciseName': exerciseName,
      });
    }

    return updated;
  }
}

bool isExerciseSelected2(
  List<dynamic>? selected,
  int exerciseId,
) {
  {
    // אם null → מתייחסים כרשימה ריקה
    final list = selected ?? [];

    for (final item in list) {
      if (item is Map &&
          (item['exerciseId'] == exerciseId ||
              item['exercise_id'] == exerciseId)) {
        return true;
      }
    }

    return false;
  }
}

List<dynamic> getSetCountForExercise(
  List<dynamic> exerciseSets,
  int exerciseId,
) {
  {
    final list = exerciseSets ?? [];

    for (final item in list) {
      // בודקים שזה Map ושיש בו exerciseId
      if (item is Map && item['exerciseId'] == exerciseId) {
        final sets = item['sets'];
        if (sets is List) {
          return sets;
        } else {
          return <dynamic>[];
        }
      }
    }

    // לא נמצא תרגיל
    return <dynamic>[];
  }
}

bool shouldShowExerciseByFilters(
  String itemName,
  String? query,
  String selectedMuscleGroup,
  String primaryMuscle1,
  String? primaryMuscle2,
  String subMuscle1,
  String? subMuscle2,
  String? subMuscle3,
  String selectedSubMuscle,
  bool aiOnly,
  int isAi,
) {
  {
    // ---- חיפוש לפי טקסט ----
    final normalizedQuery = (query ?? '').trim().toLowerCase();
    final matchesQuery = normalizedQuery.isEmpty
        ? true
        : itemName.toLowerCase().contains(normalizedQuery);

    // ---- שריר ראשי ----
    final muscleToCompare = selectedMuscleGroup.toLowerCase();

    final matchesMuscleGroup = selectedMuscleGroup == 'All' ||
        primaryMuscle1.toLowerCase() == muscleToCompare ||
        (primaryMuscle2?.toLowerCase() ?? '') == muscleToCompare ||
        subMuscle1.toLowerCase() == muscleToCompare ||
        (subMuscle2?.toLowerCase() ?? '') == muscleToCompare ||
        (subMuscle3?.toLowerCase() ?? '') == muscleToCompare;

    // ---- תת־שריר ----
    final subToCompare = selectedSubMuscle.toLowerCase();

    final matchesSubMuscle = selectedSubMuscle == 'All' ||
        subMuscle1.toLowerCase() == subToCompare ||
        (subMuscle2?.toLowerCase() ?? '') == subToCompare ||
        (subMuscle3?.toLowerCase() ?? '') == subToCompare;

    // ---- AI Filter ----
    final matchesAI = !aiOnly || isAi == 1;

    return matchesQuery && matchesMuscleGroup && matchesSubMuscle && matchesAI;
  }
}

bool shouldStartRestTimer2(
  dynamic exerciseRestTimes,
  int exerciseId,
  bool isAutoRestEnabled,
) {
  {
    // ⛔️ כיבוי גלובלי – override מוחלט
    if (!isAutoRestEnabled) return false;

    final key = exerciseId.toString();

    // אין הגדרה לתרגיל → לא להפעיל
    if (exerciseRestTimes == null ||
        exerciseRestTimes is! Map ||
        !exerciseRestTimes.containsKey(key)) {
      return false;
    }

    final value = exerciseRestTimes[key];

    // null / לא מספר → לא להפעיל
    if (value == null || value is! num) return false;

    // 0 = ביטול מנוחה לתרגיל
    return value != 0;
  }
}

bool shouldShowWeightFieldForCreation(
  bool isBodyweight,
  bool isTimed,
) {
  {
    // תרגילי משקל גוף לא מציגים משקל
    if (isBodyweight) return false;

    // תרגילים מבוססי זמן לא מציגים משקל
    if (isTimed) return false;

    // כל השאר כן מציגים משקל
    return true;
  }
}

List<dynamic> getSetsForExerciseCreation(
  List<dynamic> exerciseSets,
  int exerciseId,
) {
  {
    final list = exerciseSets ?? [];

    for (final item in list) {
      if (item is Map && item['exerciseId'] == exerciseId) {
        final sets = item['sets'];
        if (sets is List) {
          return sets;
        }
      }
    }

    // תרגיל לא נמצא או אין סטים
    return <dynamic>[];
  }
}

bool showPlusButtonForCreation(
  bool isBodyweight,
  bool addWeightOverride,
) {
  {
    // אם התרגיל לא Bodyweight – אין פלוס
    if (!isBodyweight) {
      return false;
    }

    // אם זה Bodyweight אבל המשתמש הגדיר שרוצה להוסיף משקל → אין פלוס
    if (addWeightOverride) {
      return false;
    }

    // תרגיל Bodyweight בלי override → פלוס מופיע
    return true;
  }
}

String generateUnnamedWorkoutName(int count) {
  {
    final next = (count ?? 0) + 1;
    return 'Unnamed Workout $next';
  }
}

dynamic getHintFromPreviousSetV2(
  List<dynamic> loggedSets,
  List<dynamic> exerciseSets,
  int exerciseId,
  int currentSetNumber,
  String fieldName,
) {
  {
    // תומך רק ב־reps / weight
    if (!['reps', 'weight'].contains(fieldName)) return '0';

    String formatNumber(dynamic v) {
      if (v == null) return '0';
      if (v is num) {
        return (v % 1 == 0) ? v.toInt().toString() : v.toString();
      }
      final parsed = double.tryParse(v.toString());
      if (parsed != null) {
        return (parsed % 1 == 0)
            ? parsed.toInt().toString()
            : parsed.toString();
      }
      return v.toString();
    }

    bool isDrop(dynamic s) {
      if (s is! Map) return false;
      final v = s['isDropSet'];
      if (v == null) return false;
      if (v is bool) return v;
      if (v is num) return v != 0;
      return v.toString().toLowerCase() == 'true';
    }

    // ------------------------------------------------
    // 1️⃣ TARGET – רק ל־REPS (לא ל־WEIGHT)
    // ------------------------------------------------
    if (fieldName == 'reps') {
      Map<String, dynamic>? currentTargetRow;

      final ex = exerciseSets.firstWhere(
        (e) => e['exerciseId'] == exerciseId,
        orElse: () => null,
      );

      if (ex != null && ex['sets'] is List) {
        currentTargetRow =
            (ex['sets'] as List).whereType<Map<String, dynamic>>().firstWhere(
                  (s) => s['setNumber'] == currentSetNumber,
                  orElse: () => {},
                );
      }

      if (currentTargetRow != null && currentTargetRow.isNotEmpty) {
        final targetReps = currentTargetRow['targetReps'];
        if (targetReps != null &&
            targetReps.toString().trim().isNotEmpty &&
            targetReps.toString() != '0') {
          return formatNumber(targetReps);
        }
      }
    }

    // ------------------------------------------------
    // 2️⃣ Logged sets (ל־reps ול־weight)
    // ------------------------------------------------
    final loggedForEx = loggedSets
        .where((s) => s is Map && s['exerciseId'] == exerciseId && !isDrop(s))
        .toList()
      ..sort((a, b) => (a['setNumber'] ?? 0).compareTo(b['setNumber'] ?? 0));

    for (int i = loggedForEx.length - 1; i >= 0; i--) {
      final row = loggedForEx[i];
      final sn = row['setNumber'] ?? 0;

      if (sn < currentSetNumber &&
          row[fieldName] != null &&
          row[fieldName].toString().trim().isNotEmpty &&
          row[fieldName].toString() != '0') {
        return formatNumber(row[fieldName]);
      }
    }

    // ------------------------------------------------
    // 3️⃣ fallback – רק ל־REPS (Target קודם)
    // ------------------------------------------------
    if (fieldName == 'reps') {
      final ex = exerciseSets.firstWhere(
        (e) => e['exerciseId'] == exerciseId,
        orElse: () => null,
      );

      if (ex != null && ex['sets'] is List) {
        final setsList =
            (ex['sets'] as List).whereType<Map<String, dynamic>>().toList();

        final prevTargets = setsList.where((s) {
          final sn = s['setNumber'] ?? 0;
          final val = s['targetReps'];
          return sn < currentSetNumber &&
              val != null &&
              val.toString().trim().isNotEmpty &&
              val.toString() != '0';
        }).toList();

        if (prevTargets.isNotEmpty) {
          return formatNumber(prevTargets.last['targetReps']);
        }
      }
    }

    // ------------------------------------------------
    // 4️⃣ default
    // ------------------------------------------------
    return '0';
  }
}

int getRestTimeForExercise(
  dynamic exerciseRestTimes,
  int exerciseId,
) {
  {
    if (exerciseRestTimes is Map) {
      final key = exerciseId.toString();
      final value = exerciseRestTimes[key];

      // החזרת הערך כמו שהוא – עם המרה בטוחה ל-int
      if (value is int) return value;
      if (value is double) return value.toInt();
      if (value is String) {
        final parsed = int.tryParse(value.trim());
        if (parsed != null) return parsed;
      }
    }

    return 0;
  }
}

int computeWeightedFlag(
  bool bodyweight,
  bool overrideBodyweight,
) {
  {
    // אם התרגיל *לא* משקל גוף → תמיד יש משקל
    if (!bodyweight) return 1;

    // תרגיל משקל גוף אבל המשתמש הכריח משקל
    if (overrideBodyweight) return 1;

    // תרגיל משקל גוף ואין override → אין משקל
    return 0;
  }
}

String getCreationHint(
  List<dynamic> flatSets,
  int exerciseId,
  int setNumber,
  bool isReps,
) {
  {
    // שם השדה לפי האם מחפשים חזרות או משקל
    final fieldName = isReps ? 'targetReps' : 'targetWeight';

    // סט 1 → תמיד 0
    if (setNumber <= 1) return "0";

    // כל הסטים של אותו תרגיל
    final setsForExercise = flatSets
        .where((s) => s['exerciseId'] == exerciseId)
        .map((s) => Map<String, dynamic>.from(s))
        .toList();

    // מיין לפי מספר סט
    setsForExercise.sort(
      (a, b) => (a['setNumber'] ?? 0).compareTo(b['setNumber'] ?? 0),
    );

    // חיפוש אחורה מהסט הנוכחי
    for (int i = setsForExercise.length - 1; i >= 0; i--) {
      final st = setsForExercise[i];

      if ((st['setNumber'] ?? 0) < setNumber) {
        final value = st[fieldName];

        if (value == null) continue;

        // ---------- מספר ----------
        if (value is num) {
          // אם זה שלם → בלי .0
          if (!isReps && value % 1 == 0) {
            return value.toInt().toString();
          }
          return value.toString();
        }

        // ---------- מחרוזת ----------
        final s = value.toString().trim();
        if (s.isNotEmpty) return s;
      }
    }

    // ברירת מחדל
    return "0";
  }
}

bool canMarkExerciseAsDone(
  List<dynamic> exerciseSets,
  List<dynamic> loggedSets,
  int exerciseId,
  bool allowsBodyweight,
  bool isTimedExercise,
) {
  {
    try {
      // ---------- helpers ----------
      int asInt(dynamic v) {
        if (v == null) return 0;
        if (v is int) return v;
        if (v is num) return v.toInt();
        return int.tryParse(v.toString()) ?? 0;
      }

      double asDouble(dynamic v) {
        if (v == null) return 0;
        if (v is num) return v.toDouble();
        return double.tryParse(v.toString()) ?? 0;
      }

      bool truthy(dynamic v) {
        if (v == null) return false;
        if (v is bool) return v;
        if (v is num) return v != 0;
        final s = v.toString().trim().toLowerCase();
        return s == 'true' || s == '1';
      }

      // ---------- fetch template ----------
      final tpl = exerciseSets.firstWhere(
        (e) => e is Map && e['exerciseId'] == exerciseId && e['sets'] is List,
        orElse: () => null,
      );
      if (tpl == null) return false;

      final templateSets = (tpl['sets'] as List)
          .whereType<Map>()
          .map((m) => Map<String, dynamic>.from(m))
          .toList()
        ..sort(
          (a, b) => asInt(a['setNumber']).compareTo(asInt(b['setNumber'])),
        );

      if (templateSets.isEmpty) return false;

      // ---------- helpers ----------
      Map<String, dynamic>? loggedForSet(int sn) {
        for (final it in loggedSets) {
          if (it is Map &&
              asInt(it['exerciseId']) == exerciseId &&
              asInt(it['setNumber']) == sn &&
              !truthy(it['isDropSet'])) {
            return Map<String, dynamic>.from(it);
          }
        }
        return null;
      }

      bool loggedHasValue(Map s) {
        final dur = asInt(s['durationSeconds']);
        final reps = asInt(s['reps']);
        final weight = asDouble(s['weight']);

        if (isTimedExercise) {
          return dur > 0;
        }
        if (allowsBodyweight) {
          return reps > 0;
        }
        return reps > 0 && weight > 0;
      }

      bool templateHasValue(Map s) {
        final td = asInt(s['targetDurationSeconds']);
        final tr = asInt(s['targetReps']);
        final tw = asDouble(s['targetWeight']);

        if (isTimedExercise) {
          return td > 0;
        }
        if (allowsBodyweight) {
          return tr > 0;
        }
        return tr > 0 && tw > 0;
      }

      bool hasValidLoggedBackward(int sn) {
        if (isTimedExercise) return false;

        for (final it in loggedSets) {
          if (it is Map &&
              asInt(it['exerciseId']) == exerciseId &&
              asInt(it['setNumber']) < sn &&
              !truthy(it['isDropSet']) &&
              loggedHasValue(it)) {
            return true;
          }
        }
        return false;
      }

      bool hasValidTemplateBackward(int sn) {
        if (isTimedExercise) return false;

        for (final s in templateSets) {
          final sNo = asInt(s['setNumber']);
          if (sNo >= sn) continue;
          if (templateHasValue(s)) return true;
        }
        return false;
      }

      // ---------- main loop ----------
      for (final tSet in templateSets) {
        final sn = asInt(tSet['setNumber']);

        final logged = loggedForSet(sn);

        if (isTimedExercise) {
          // 🕒 תרגיל זמן — חייב duration בלוגד של אותו סט
          if (logged == null || !loggedHasValue(logged)) {
            return false;
          }
          continue;
        }

        // 🏋️ תרגיל רגיל — היררכיה מלאה
        if (logged != null && loggedHasValue(logged)) continue;
        if (templateHasValue(tSet)) continue;
        if (hasValidLoggedBackward(sn)) continue;
        if (hasValidTemplateBackward(sn)) continue;

        return false;
      }

      return true;
    } catch (_) {
      return false;
    }
  }
}

int countWorkoutsByRange(
  List<WorkoutCountSimpleRow> rows,
  String rangeLabel,
) {
  {
    final now = DateTime.now();
    DateTime? from;

    // define starting point
    switch (rangeLabel) {
      case 'Last 7 Days':
        from = now.subtract(const Duration(days: 7));
        break;
      case 'Last 30 Days':
        from = now.subtract(const Duration(days: 30));
        break;
      case 'Last 90 Days':
        from = now.subtract(const Duration(days: 90));
        break;
      case 'All':
      default:
        from = null;
    }

    int count = 0;

    for (final row in rows) {
      final createdStr = row.createdAt; // <-- THIS IS THE FIX
      if (createdStr == null || createdStr.isEmpty) continue;

      final iso = createdStr.replaceAll(' ', 'T');
      final dt = DateTime.tryParse(iso);
      if (dt == null) continue;

      if (from != null && dt.isBefore(from)) {
        continue;
      }

      count++;
    }

    return count;
  }
}

bool shouldShowDropTable(
  int exerciseId,
  int setNumber,
  List<dynamic> dropSets,
) {
  {
    if (dropSets == null || dropSets.isEmpty) return false;

    for (final d in dropSets) {
      try {
        final exId = d['exerciseId'];
        final parent = d['parentSetNumber'];

        if (exId == exerciseId && parent == setNumber) {
          return true; // יש לפחות דרופסט אחד
        }
      } catch (_) {
        continue;
      }
    }

    return false;
  }
}

int getDropHintReps(
  List<dynamic> dropSets,
  int exerciseId,
  int parentSetNumber,
  int dropOrder,
) {
  {
    // 1) מנסים למצוא דרופסט קיים עם targetReps
    final match = dropSets.firstWhere(
      (d) =>
          d is Map &&
          d['exerciseId'] == exerciseId &&
          d['parentSetNumber'] == parentSetNumber &&
          d['dropOrder'] == dropOrder &&
          d['reps'] is int,
      orElse: () => null,
    );

    if (match != null) {
      return match['reps'] as int;
    }

    // 2) אין targetReps → מחזירים 0
    return 0;
  }
}

bool showRestForExercise(
  dynamic exerciseRestTimes,
  int exerciseId,
) {
  {
    if (exerciseRestTimes is! Map) return false;

    final key = exerciseId.toString();
    final value = exerciseRestTimes[key];

    if (value is int && value > 0) {
      return true;
    }

    return false;
  }
}

bool shouldShowMuscle(
  String muscleName,
  String query,
) {
  {
    // Normalize: lowercase, trim, collapse spaces
    String norm(String? s) =>
        (s ?? '').toLowerCase().trim().replaceAll(RegExp(r'\s+'), ' ');

    final name = norm(muscleName);
    final q = norm(query);

    // 1) אם החיפוש ריק → תמיד להראות
    if (q.isEmpty) return true;

    // 2) התאמה חלקית (contains)
    return name.contains(q);
  }
}

List<dynamic> addExerciseToSelected(
  List<dynamic>? selected,
  int exerciseId,
  String exerciseName,
) {
  {
    // ריק כברירת מחדל
    final List<Map<String, dynamic>> updated = (selected ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();

    updated.add({
      'exerciseId': exerciseId,
      'exerciseName': exerciseName,
    });

    return updated;
  }
}

bool shouldShowExerciseDuringWorkout(
  String itemName,
  String? query,
  String selectedMuscleGroup,
  String primaryMuscle1,
  String? primaryMuscle2,
  String subMuscle1,
  String? subMuscle2,
  String? subMuscle3,
  String selectedSubMuscle,
  int exerciseId,
  List<dynamic> exerciseSets,
  bool aiOnly,
  int isAi,
) {
  {
    // ---------- 1) האם התרגיל כבר קיים באימון? ----------
    final exists = exerciseSets.any((item) {
      if (item is! Map) return false;

      final Map<String, dynamic> m = Map<String, dynamic>.from(item);

      final dynamic rawId = m['exerciseId'];
      if (rawId == null) return false;

      return rawId.toString() == exerciseId.toString();
    });

    if (exists) return false;

    // ---------- 2) חיפוש טקסט ----------
    final q = (query ?? '').trim().toLowerCase();
    final matchesQuery = q.isEmpty || itemName.toLowerCase().contains(q);

    // ---------- 3) שריר ----------
    final m = selectedMuscleGroup.toLowerCase();
    final matchesMuscle = selectedMuscleGroup == 'All' ||
        primaryMuscle1.toLowerCase() == m ||
        (primaryMuscle2?.toLowerCase() ?? '') == m ||
        subMuscle1.toLowerCase() == m ||
        (subMuscle2?.toLowerCase() ?? '') == m ||
        (subMuscle3?.toLowerCase() ?? '') == m;

    // ---------- 4) תת־שריר ----------
    final sm = selectedSubMuscle.toLowerCase();
    final matchesSub = selectedSubMuscle == 'All' ||
        subMuscle1.toLowerCase() == sm ||
        (subMuscle2?.toLowerCase() ?? '') == sm ||
        (subMuscle3?.toLowerCase() ?? '') == sm;

    // ---------- 5) AI Filter ----------
    final matchesAI = !aiOnly || isAi == 1;

    return matchesQuery && matchesMuscle && matchesSub && matchesAI;
  }
}

bool? canSaveUserExercise(
  String? name,
  dynamic primaryMuscle,
  String? type,
) {
  {
    // Normalize values
    final String n = (name ?? '').trim();
    final String t = (type ?? '').trim().toLowerCase();

    // 1) שם ריק → לא תקין
    if (n.isEmpty) return false;

    // 2) שריר ראשי חייב להיות JSON לא ריק
    if (primaryMuscle == null) return false;
    if (primaryMuscle is Map && primaryMuscle.isEmpty) return false;

    // 3) סוג התרגיל לא יכול להיות "All"
    if (t == 'all' || t.isEmpty) return false;

    // הכל תקין
    return true;
  }
}

bool hasNameError(String? name) {
  {
    final value = (name ?? '').trim();

    // אם ריק → יש שגיאה
    if (value.isEmpty) {
      return true;
    }

    // אחרת → אין שגיאה
    return false;
  }
}

bool hasTypeError(String type) {
  {
    // אם המשתמש לא בחר באמת (נשאר על All)
    if (type == 'All') {
      return true;
    }

    // כל ערך אחר תקין
    return false;
  }
}

bool hasPrimaryMuscleError(bool hasPrimaryMuscleSelected) {
  {
    // אם לא נבחר שריר → שגיאה
    return hasPrimaryMuscleSelected == false;
  }
}

String getExerciseTypeLabel(
  bool isNullType,
  String type,
) {
  {
    // 🔑 עדיפות ראשונה: יש Type תקין → מציגים אותו
    if (type.isNotEmpty && type != 'All') {
      return type;
    }

    // אין Type תקין + ניסו לשמור → שגיאה
    if (isNullType == true) {
      return 'Please Select Exercise Type';
    }

    // ברירת מחדל
    return 'Select';
  }
}

String getPrimaryMuscleLabel(
  bool submitAttempted,
  bool hasPrimaryMuscle,
  String muscleName,
) {
  {
    if (hasPrimaryMuscle && muscleName != null && muscleName.isNotEmpty) {
      return muscleName;
    }

    // אין שריר + עוד לא ניסו לשמור
    if (!submitAttempted) {
      return 'Select';
    }

    // אין שריר + ניסו לשמור
    return 'Please Select Primary Muscle';
  }
}

bool shouldShowPrimaryMuscleError(
  bool submitAttempted,
  bool hasPrimaryMuscle,
  String? muscleName,
) {
  {
    if (!submitAttempted) return false;

    final hasName = (muscleName ?? '').trim().isNotEmpty;

    // שגיאה אם אין בחירה תקינה
    return !(hasPrimaryMuscle && hasName);
  }
}

bool shouldShowExerciseTypeErrorColor(
  bool isNullType,
  String? type,
) {
  {
    final hasValidType = type != null && type.isNotEmpty && type != 'All';

    // יש Type תקין → אף פעם לא שגיאה
    if (hasValidType) {
      return false;
    }

    // אין Type תקין + ניסו לשמור
    if (isNullType == true) {
      return true;
    }

    return false;
  }
}

String formatMillisToMMSS(double? millis) {
  {
    if (millis == null || millis.isNaN || millis <= 0) {
      return '00:00';
    }

    // 👇 מוודאים שזה int ולא double מוזר
    final int safeMillis = millis.toInt();

    // 👇 ממירים לשניות בצורה בטוחה
    final int totalSeconds = safeMillis ~/ 1000;

    // 👇 חישוב דקות ושניות
    final int minutes = totalSeconds ~/ 60;
    final int seconds = totalSeconds % 60;

    // 👇 פורמט תקין תמיד
    final String mm = minutes.toString().padLeft(2, '0');
    final String ss = seconds.toString().padLeft(2, '0');

    return '$mm:$ss';
  }
}

dynamic getInitialTimerValueForSet(
  List<dynamic> exerciseSets,
  int exerciseId,
  int setNumber,
) {
  {
    const int defaultDuration = 90000;

    for (final ex in exerciseSets) {
      final exMap = ex as Map<String, dynamic>;

      if (exMap['exerciseId'] != exerciseId) continue;

      final sets = exMap['sets'];
      if (sets is! List) break;

      for (final s in sets) {
        final setMap = s as Map<String, dynamic>;

        if (setMap['setNumber'] != setNumber) continue;

        final duration = setMap['durationSeconds'];

        if (duration is int && duration > 0) {
          return {
            'timerMode': 2,
            'durationSeconds': duration,
          };
        }
      }
    }

    return {
      'timerMode': 1,
      'durationSeconds': defaultDuration,
    };
  }
}

int newCustomFunction(int ms) {
  {
    if (ms == null || ms <= 0) return 0;
    return (ms / 1000).round();
  }
}

List<dynamic>? toggleExerciseSelectionMid(
  List<dynamic>? selected,
  int exerciseId,
  String exerciseName,
  bool isBodyweight,
) {
  {
    final List<Map<String, dynamic>> updated = (selected ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();

    final existsIndex =
        updated.indexWhere((e) => e['exerciseId'] == exerciseId);

    if (existsIndex >= 0) {
      // קיים → מוחקים
      updated.removeAt(existsIndex);
    } else {
      // לא קיים → מוסיפים עם metadata
      updated.add({
        'exerciseId': exerciseId,
        'exerciseName': exerciseName,
        'isBodyweight': isBodyweight,
      });
    }

    return updated;
  }
}

String formatWorkoutDateShort(String timeStamp) {
  {
    DateTime? dt;

    try {
      if (RegExp(r'^\d+$').hasMatch(timeStamp)) {
        dt = DateTime.fromMillisecondsSinceEpoch(
          int.parse(timeStamp),
        ).toLocal();
      } else {
        dt = DateTime.parse(timeStamp).toLocal();
      }
    } catch (_) {
      return '';
    }

    final now = DateTime.now();

    if (dt.year == now.year) {
      // השנה הנוכחית → Sat, Dec 28
      return DateFormat('EEE, MMM d').format(dt);
    } else {
      // שנה אחרת → Dec 23, 2024
      return DateFormat('MMM d, y').format(dt);
    }
  }
}

bool isMuscleSelected(
  List<dynamic>? selected,
  int muscleId,
) {
  {
    if (selected == null) return false;

    for (final item in selected) {
      if (item is Map && item['id'] == muscleId) {
        return true;
      }
    }

    return false;
  }
}

String getSecondaryMusclesLabel(List<dynamic> selected) {
  {
    if (selected == null || selected.isEmpty) {
      return 'Select';
    }

    final names = <String>[];

    for (final item in selected) {
      if (item is Map && item['name'] != null) {
        names.add(item['name'].toString());
      }
    }

    if (names.isEmpty) {
      return 'Select';
    }

    return names.join(', ');
  }
}

bool canShowMoveButton(
  List<dynamic> list,
  int index,
  bool isUp,
) {
  {
    if (list.isEmpty) return false;

    if (isUp) {
      // Show "move up" only if not first
      return index > 0;
    } else {
      // Show "move down" only if not last
      return index < list.length - 1;
    }
  }
}

dynamic getInitialValueFromTarget(
  List<dynamic> exerciseSets,
  int exerciseId,
  int setNumber,
  String fieldName,
) {
  {
    if (!['reps', 'weight'].contains(fieldName)) return null;

    final targetField = fieldName == 'reps' ? 'targetReps' : 'targetWeight';

    final ex = exerciseSets.firstWhere(
      (e) => e['exerciseId'] == exerciseId,
      orElse: () => null,
    );

    if (ex == null || ex['sets'] is! List) return null;

    final set =
        (ex['sets'] as List).whereType<Map<String, dynamic>>().firstWhere(
              (s) => s['setNumber'] == setNumber,
              orElse: () => {},
            );

    if (set.isEmpty) return null;

    final val = set[targetField];
    if (val == null) return null;

    // ===============================
    // 🧠 המרה חכמה
    // ===============================
    if (fieldName == 'weight') {
      // אם זה מספר
      if (val is num) {
        // אם שלם מתמטית → int
        if (val % 1 == 0) return val.toInt();
        // אחרת → double
        return val.toDouble();
      }

      // אם הגיע כסטרינג
      final parsed = double.tryParse(val.toString());
      if (parsed == null) return null;
      if (parsed % 1 == 0) return parsed.toInt();
      return parsed;
    }

    // reps – תמיד int
    if (fieldName == 'reps') {
      if (val is int) return val;
      if (val is num) return val.toInt();
      return int.tryParse(val.toString());
    }

    return null;
  }
}

List<int> extractExerciseIdsFromExerciseSets(List<dynamic> exerciseSets) {
  {
    final List<int> result = [];

    for (final item in exerciseSets) {
      final m = Map<String, dynamic>.from(item as Map);

      final exerciseId = m['exerciseId'];
      if (exerciseId is int) {
        result.add(exerciseId);
      }
    }

    return result;
  }
}

List<int> toggleExerciseId(
  List<int> selected,
  int exerciseId,
) {
  {
    // אם null → רשימה ריקה
    final List<int> updated = List<int>.from(selected ?? []);

    if (updated.contains(exerciseId)) {
      // קיים → להסיר
      updated.remove(exerciseId);
    } else {
      // לא קיים → להוסיף
      updated.add(exerciseId);
    }

    return updated;
  }
}

bool isExerciseSelectedById(
  List<int> selectedList,
  int exerciseId,
) {
  {
    if (selectedList == null || selectedList.isEmpty) {
      return false;
    }

    return selectedList.contains(exerciseId);
  }
}

String formatClockFromMs(String current) {
  int h = 0, m = 0, s = 0;

  final parts = current.trim().split(':');
  if (parts.length == 2) {
    m = int.tryParse(parts[0]) ?? 0;
    s = int.tryParse(parts[1]) ?? 0;
  } else if (parts.length == 3) {
    h = int.tryParse(parts[0]) ?? 0;
    m = int.tryParse(parts[1]) ?? 0;
    s = int.tryParse(parts[2]) ?? 0;
  }

  int total = (h * 3600) + (m * 60) + s;

  // countdown: subtract one second
  total = total - 1;
  if (total < 0) total = 0;

  final nh = total ~/ 3600;
  final rem = total % 3600;
  final nm = rem ~/ 60;
  final ns = rem % 60;

  return nh > 0
      ? '$nh:${nm.toString().padLeft(2, '0')}:${ns.toString().padLeft(2, '0')}'
      : '${nm.toString().padLeft(2, '0')}:${ns.toString().padLeft(2, '0')}';
}

String adjustClockByFiveSeconds(
  bool add,
  String current,
) {
  int h = 0, m = 0, s = 0;

  final parts = current.trim().split(':');
  if (parts.length == 2) {
    m = int.tryParse(parts[0]) ?? 0;
    s = int.tryParse(parts[1]) ?? 0;
  } else if (parts.length == 3) {
    h = int.tryParse(parts[0]) ?? 0;
    m = int.tryParse(parts[1]) ?? 0;
    s = int.tryParse(parts[2]) ?? 0;
  }

  int totalSeconds = (h * 3600) + (m * 60) + s;

  totalSeconds += add ? 5 : -5;
  if (totalSeconds < 0) totalSeconds = 0;

  final nh = totalSeconds ~/ 3600;
  final rem = totalSeconds % 3600;
  final nm = rem ~/ 60;
  final ns = rem % 60;

  return nh > 0
      ? '$nh:${nm.toString().padLeft(2, '0')}:${ns.toString().padLeft(2, '0')}'
      : '${nm.toString().padLeft(2, '0')}:${ns.toString().padLeft(2, '0')}';
}

int adjustMsByFiveSeconds(
  int currentMs,
  bool add,
) {
  int next = currentMs + (add ? 5000 : -5000);
  if (next < 0) next = 0;
  return next;
}

double calculateRestProgress(
  int initialMs,
  int currentMs,
) {
  if (initialMs <= 0) return 1.0;

  double progress = (initialMs - currentMs).toDouble() / initialMs.toDouble();

  if (progress < 0) return 0.0;
  if (progress > 1) return 1.0;

  return progress;
}

int? getDurationWithFallback(
  int? currentDurationSeconds,
  List<dynamic> loggedSets,
  int exerciseId,
  int setNumber,
  List<dynamic> exerciseSets,
) {
  // -------------------------
  // helper: parse int safely
  // -------------------------
  int? toInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is String) return int.tryParse(v.trim());
    return null;
  }

  // -----------------------------------------
  // 1️⃣ עדיפות ראשונה — מה שהמשתמש כתב
  // -----------------------------------------
  if (currentDurationSeconds != null && currentDurationSeconds > 0) {
    return currentDurationSeconds;
  }

  // -----------------------------------------
  // 2️⃣ בדיקה אם זה סט מתוך התוכנית
  // -----------------------------------------
  final ex = exerciseSets.firstWhere(
    (e) => e['exerciseId'] == exerciseId,
    orElse: () => null,
  );

  Map<String, dynamic>? currentTargetRow;

  if (ex != null && ex['sets'] is List) {
    currentTargetRow =
        (ex['sets'] as List).whereType<Map<String, dynamic>>().firstWhere(
              (s) => s['setNumber'] == setNumber,
              orElse: () => {},
            );
  }

  final bool isCurrentSetInProgram =
      currentTargetRow != null && currentTargetRow!.isNotEmpty;

  // -----------------------------------------------------
  // 2A️⃣ אם הסט בתוכנית → targetDurationSeconds
  // -----------------------------------------------------
  if (isCurrentSetInProgram) {
    final target = toInt(currentTargetRow!['targetDurationSeconds']);
    if (target != null && target > 0) return target;
  }

  // -----------------------------------------------------
  // 3️⃣ loggedSets — עדיפות על target של סטים קודמים
  // -----------------------------------------------------
  for (int i = setNumber - 1; i >= 1; i--) {
    final row = loggedSets.firstWhere(
      (s) =>
          s['exerciseId'] == exerciseId &&
          s['setNumber'] == i &&
          s['durationSeconds'] != null,
      orElse: () => null,
    );

    if (row != null) {
      final parsed = toInt(row['durationSeconds']);
      if (parsed != null && parsed > 0) return parsed;
    }
  }

  // ----------------------------------------------------------------
  // 4️⃣ fallback — רק אם הסט נמצא בתוכנית → target קודם
  // ----------------------------------------------------------------
  if (isCurrentSetInProgram && ex != null && ex['sets'] is List) {
    final setsList =
        (ex['sets'] as List).whereType<Map<String, dynamic>>().toList();

    for (int i = setNumber - 1; i >= 1; i--) {
      final prev = setsList.firstWhere(
        (s) => s['setNumber'] == i,
        orElse: () => {},
      );

      final prevParsed = toInt(prev['targetDurationSeconds']);
      if (prevParsed != null && prevParsed > 0) return prevParsed;
    }
  }

  // -----------------------------------------
  // 5️⃣ אם אין כלום → null
  // -----------------------------------------
  return null;
}

dynamic getInitialSetValue(
  List<dynamic> loggedSets,
  int exerciseId,
  int setNumber,
  String fieldName,
) {
  {
    try {
      for (final it in loggedSets) {
        if (it is Map &&
            it['exerciseId'].toString() == exerciseId.toString() &&
            it['setNumber'].toString() == setNumber.toString() &&
            (it['isDropSet'] == null || it['isDropSet'] == false)) {
          final value = it[fieldName];
          if (value == null) return null;

          // לא מחזירים 0 כ־initial
          if (value is num && value == 0) return null;
          if (value is String && value.trim().isEmpty) return null;

          // weight תמיד יוחזר כ-double, reps תמיד כ-int
          if (value is num) {
            if (fieldName == 'weight') {
              return value.toDouble();
            }
            // לכל שאר השדות (reps, durationMs וכו')
            return value.toInt();
          }

          return value;
        }
      }

      return null;
    } catch (_) {
      return null;
    }
  }
}

bool shouldShowRecentExercisesHeader(
  List<GetRecentExercisesRow>? exercisesList,
  String? query,
  String selectedMuscleGroup,
  String selectedSubMuscle,
  bool aiOnly,
) {
  {
    if (exercisesList == null || exercisesList.isEmpty) {
      return false;
    }

    for (final row in exercisesList) {
      if (shouldShowExerciseByFilters(
        row.exerciseName,
        query,
        selectedMuscleGroup,
        row.primaryMuscle1,
        row.primaryMuscle2,
        row.subMuscle1,
        row.subMuscle2,
        row.subMuscle3,
        selectedSubMuscle,
        aiOnly,
        row.aiFormAnalysis ?? 0, // 👈 זה התיקון
      )) {
        return true;
      }
    }

    return false;
  }
}

bool shouldShowUserExercisesHeader(
  List<GetUserExercisesRow>? exercisesList,
  String? query,
  String selectedMuscleGroup,
  String selectedSubMuscle,
  bool aiOnly,
) {
  {
    // ❌ אם מסננים רק AI → אין טעם להציג User Exercises
    if (aiOnly) {
      return false;
    }

    if (exercisesList == null || exercisesList.isEmpty) {
      return false;
    }

    for (final row in exercisesList) {
      final shouldShow = shouldShowExerciseByFilters(
        row.exerciseName,
        query,
        selectedMuscleGroup,
        row.primaryMuscle1,
        row.primaryMuscle2,
        row.subMuscle1,
        row.subMuscle2,
        row.subMuscle3,
        selectedSubMuscle,
        false, // 👈 חשוב! לא מפעילים AI filter פה
        0, // 👈 אין AI בתרגילי user
      );

      if (shouldShow) {
        return true;
      }
    }

    return false;
  }
}

bool? shouldShowWorkoutExercisesHeader(
  List<GetRecentExercisesRow>? exercisesList,
  String? query,
  String selectedMuscleGroup,
  String selectedSubMuscle,
  List<dynamic> exerciseSets,
  bool aiOnly,
) {
  {
    if (exercisesList == null || exercisesList.isEmpty) {
      return false;
    }

    for (final row in exercisesList) {
      final shouldShow = shouldShowExerciseDuringWorkout(
        row.exerciseName,
        query,
        selectedMuscleGroup,
        row.primaryMuscle1,
        row.primaryMuscle2,
        row.subMuscle1,
        row.subMuscle2,
        row.subMuscle3,
        selectedSubMuscle,
        row.exerciseId,
        exerciseSets,
        aiOnly,
        row.aiFormAnalysis ?? 0, // 👈 חשוב
      );

      if (shouldShow) {
        return true;
      }
    }

    return false;
  }
}

bool? shouldShowWorkoutExercisesHeaderU(
  List<GetUserExercisesRow>? exercisesList,
  String? query,
  String selectedMuscleGroup,
  String selectedSubMuscle,
  List<dynamic> exerciseSets,
  bool aiOnly,
) {
  {
    // ❌ אם מסננים רק AI → אין טעם להציג User Exercises
    if (aiOnly) {
      return false;
    }

    if (exercisesList == null || exercisesList.isEmpty) {
      return false;
    }

    for (final row in exercisesList) {
      final shouldShow = shouldShowExerciseDuringWorkout(
        row.exerciseName,
        query,
        selectedMuscleGroup,
        row.primaryMuscle1,
        row.primaryMuscle2,
        row.subMuscle1,
        row.subMuscle2,
        row.subMuscle3,
        selectedSubMuscle,
        row.exerciseId,
        exerciseSets,
        false, // 👈 לא מפעילים AI filter
        0, // 👈 אין AI בתרגילי user
      );

      if (shouldShow) {
        return true;
      }
    }

    return false;
  }
}

List<dynamic> removeById(
  List<dynamic> list,
  int? id,
) {
  {
    return list
        .where((e) => e['id'] != id)
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }
}

bool canAddMore(List<dynamic> selected) {
  {
    if (selected == null) return true;
    return selected.length < 3;
  }
}

String selectedCountText(List<dynamic> selected) {
  {
    final count = selected?.length ?? 0;
    return '$count / 3';
  }
}

dynamic getHintFromPreviousSetForCreation(
  List<dynamic> loggedSets,
  int exerciseId,
  int currentSetNumber,
  String fieldName,
) {
  {
    if (!['reps', 'weight'].contains(fieldName)) return '0';

    final valueField = fieldName == 'reps' ? 'targetReps' : 'targetWeight';

    String formatNumber(dynamic v) {
      if (v == null) return '0';
      if (v is num) {
        return (v % 1 == 0) ? v.toInt().toString() : v.toString();
      }
      final parsed = double.tryParse(v.toString());
      if (parsed != null) {
        return (parsed % 1 == 0)
            ? parsed.toInt().toString()
            : parsed.toString();
      }
      return v.toString();
    }

    // סינון רלוונטי
    final filtered = loggedSets.where((s) {
      final exId = s['exerciseId'];
      final sn = s['setNumber'];

      if (exId == null || sn == null) return false;

      final snInt = int.tryParse(sn.toString()) ?? 0;
      return exId == exerciseId && snInt < currentSetNumber;
    }).toList();

    // מיון לפי setNumber
    filtered.sort((a, b) {
      final aSn = int.tryParse(a['setNumber'].toString()) ?? 0;
      final bSn = int.tryParse(b['setNumber'].toString()) ?? 0;
      return aSn.compareTo(bSn);
    });

    // חיפוש מהסוף
    for (int i = filtered.length - 1; i >= 0; i--) {
      final val = filtered[i][valueField];
      if (val != null && val.toString().trim().isNotEmpty) {
        return formatNumber(val);
      }
    }

    return '0';
  }
}

bool isSaveWorkoutDisabled(
  String? workoutName,
  List<dynamic> exerciseSets,
) {
  {
    // ---- name check ----
    if (workoutName == null || workoutName.trim().isEmpty) {
      return true;
    }

    // ---- exercise seכts check ----
    if (exerciseSets == null || exerciseSets.isEmpty) {
      return true;
    }

    // ---- at least one real set ----
    bool hasAnySet = false;

    for (final ex in exerciseSets) {
      if (ex is! Map) continue;

      final sets = ex['sets'];
      if (sets is List && sets.isNotEmpty) {
        hasAnySet = true;
        break;
      }
    }

    return !hasAnySet;
  }
}

bool isExerciseSetsEmpty(List<dynamic> exerciseSets) {
  {
    if (exerciseSets == null || exerciseSets.isEmpty) {
      return true;
    }

    for (final ex in exerciseSets) {
      if (ex is! Map) continue;

      final sets = ex['sets'];
      if (sets is List && sets.isNotEmpty) {
        return false; // יש לפחות סט אחד
      }
    }

    return true; // לא נמצא אף סט
  }
}

bool shouldShowWorkoutNameError(
  bool showNameError,
  String? workoutName,
) {
  {
    if (!showNameError) {
      return false;
    }

    if (workoutName == null || workoutName.trim().isEmpty) {
      return true;
    }

    return false;
  }
}

bool hasExerciseSelectionChanged(
  List<dynamic>? original,
  List<dynamic>? current,
) {
  {
    final originalIds = (original ?? []).map((e) => e['exerciseId']).toSet();

    final currentIds = (current ?? []).map((e) => e['exerciseId']).toSet();

    return originalIds.length != currentIds.length ||
        !originalIds.containsAll(currentIds);
  }
}

String getExerciseSelectionCtaText(
  List<dynamic>? original,
  List<dynamic>? current,
) {
  {
    final originalIds = (original ?? []).map((e) => e['exerciseId']).toSet();

    final currentIds = (current ?? []).map((e) => e['exerciseId']).toSet();

    final added = currentIds.difference(originalIds).length;
    final removed = originalIds.difference(currentIds).length;

    if (added == 0 && removed == 0) {
      return ''; // אין שינוי → אין כפתור
    }

    if (added > 0 && removed == 0) {
      return 'Add $added exercise${added > 1 ? 's' : ''}';
    }

    if (removed > 0 && added == 0) {
      return 'Remove $removed exercise${removed > 1 ? 's' : ''}';
    }

    return 'Save changes';
  }
}

bool shouldShowExerciseSelectionCta(
  List<dynamic>? exerciseSets,
  List<int>? selectedExerciseIds,
) {
  {
    final currentIds = (exerciseSets ?? [])
        .map((e) => e['exerciseId'])
        .whereType<int>()
        .toSet();

    final selectedIds = (selectedExerciseIds ?? []).toSet();

    // שינוי אם הסטים שונים
    return currentIds.length != selectedIds.length ||
        !currentIds.containsAll(selectedIds);
  }
}

String? getEditWorkoutExerciseCtaText(
  List<dynamic>? exerciseSets,
  List<int>? selectedExerciseIds,
) {
  {
    final originalIds = (exerciseSets ?? [])
        .map((e) => e['exerciseId'])
        .whereType<int>()
        .toSet();

    final currentIds = (selectedExerciseIds ?? []).toSet();

    final added = currentIds.difference(originalIds).length;
    final removed = originalIds.difference(currentIds).length;

    if (added > 0 && removed == 0) {
      return 'Add $added exercise${added > 1 ? 's' : ''}';
    }

    if (removed > 0 && added == 0) {
      return 'Remove $removed exercise${removed > 1 ? 's' : ''}';
    }

    if (added > 0 && removed > 0) {
      return 'Save changes';
    }

    return '';
  }
}

dynamic getInitialLoggedSetValue(
  List<dynamic> loggedSets,
  int exerciseId,
  int setNumber,
  String field,
) {
  {
    if (loggedSets.isEmpty) return null;

    for (final s in loggedSets) {
      if (s is! Map) continue;

      final m = Map<String, dynamic>.from(s);

      if (m['exerciseId'] == exerciseId && m['setNumber'] == setNumber) {
        dynamic value;

        // 🔁 מיפוי שדות לוגיים → שדות אמיתיים
        if (field == 'reps') {
          value = m['targetReps'];
        } else {
          value = m[field];
        }

        if (value is num) {
          if (value % 1 == 0) return value.toInt();
          return value;
        }

        return value;
      }
    }

    return null;
  }
}

int calculateWorkoutVolumeInt(
  List<dynamic> savedSets,
  List<dynamic> exerciseSets,
) {
  {
    double total = 0.0;

    // ---------- build assisted map ----------
    final Map<int, bool> assistedByExerciseId = {};

    for (final ex in exerciseSets) {
      if (ex is Map) {
        final m = Map<String, dynamic>.from(ex);
        final exId = m['exerciseId'];
        final isAssisted = m['isAssisted'];

        if (exId is int) {
          assistedByExerciseId[exId] = (isAssisted is bool && isAssisted) ||
              (isAssisted is num && isAssisted != 0);
        }
      }
    }

    // ---------- calculate volume ----------
    for (final raw in savedSets) {
      final m = Map<String, dynamic>.from(raw as Map);

      final reps = m['reps'];
      final weight = m['weight'];
      final exerciseId = m['exerciseId'];

      // אם אין exerciseId – לא סופרים
      if (exerciseId is! int) continue;

      // ❗ תרגיל אסיסטד → מדלגים
      if (assistedByExerciseId[exerciseId] == true) {
        continue;
      }

      if (reps is num && reps > 0 && weight is num && weight > 0) {
        total += reps * weight;
      }
    }

    return total.round(); // אינטגר
  }
}

DateTime? isoStringToDateTime(String? isoString) {
  {
    if (isoString == null || isoString.isEmpty) return null;

    try {
      return DateTime.parse(isoString);
    } catch (_) {
      return null;
    }
  }
}

String? dateTimeToIsoDate(DateTime date) {
  {
    if (date == null) return null;

    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');

    return '$y-$m-$d';
  }
}

double? resolveDropSetWeight(
  List<dynamic> loggedSets,
  List<dynamic> dropSets,
  int exerciseId,
  int parentSetNumber,
  String dropLabel,
  double currentWeight,
) {
  {
    // 0️⃣ אם יש משקל נוכחי – משתמשים בו כמו שהוא
    if (currentWeight != null && currentWeight > 0) {
      return currentWeight;
    }

    // --- מדרגות מהאב: D1=80%, D2=70%, D3=60%, D4+=55 ---
    int ladderPercent(int order) {
      if (order == 1) return 80;
      if (order == 2) return 70;
      if (order == 3) return 60;
      return 55;
    }

    // ---------- parent weight ----------
    double? getParentWeight() {
      final same = loggedSets.firstWhere(
        (s) =>
            s is Map &&
            s['exerciseId'] == exerciseId &&
            s['setNumber'] == parentSetNumber &&
            s['isDrop'] != true &&
            s['weight'] is num,
        orElse: () => null,
      );

      if (same != null) {
        return (same['weight'] as num).toDouble();
      }

      double? best;
      int bestSet = -1;

      for (final s in loggedSets) {
        if (s is! Map) continue;
        if (s['exerciseId'] != exerciseId) continue;
        if (s['isDrop'] == true) continue;

        final n = s['setNumber'];
        if (n is! int || n >= parentSetNumber) continue;

        final w = s['weight'];
        if (w is! num) continue;

        if (n > bestSet) {
          bestSet = n;
          best = w.toDouble();
        }
      }

      return best;
    }

    // ---------- drops for this parent ----------
    final drops = dropSets
        .where((r) =>
            r is Map &&
            r['exerciseId'] == exerciseId &&
            r['parentSetNumber'] == parentSetNumber)
        .map((e) => Map<String, dynamic>.from(e))
        .toList()
      ..sort(
        (a, b) => (a['dropOrder'] as int).compareTo(b['dropOrder'] as int),
      );

    // ---------- order from label ----------
    int? parseOrder(String? label) {
      if (label == null) return null;
      final m = RegExp(r'(\d+)').firstMatch(label);
      if (m == null) return null;
      return int.tryParse(m.group(1)!);
    }

    final orderFromLabel = parseOrder(dropLabel);
    final targetOrder = orderFromLabel ?? (drops.length + 1);

    // ---------- 1️⃣ logged drop ----------
    final loggedDrop = loggedSets.firstWhere(
      (s) =>
          s is Map &&
          s['exerciseId'] == exerciseId &&
          s['setNumber'] == parentSetNumber &&
          s['isDrop'] == true &&
          s['dropOrder'] == targetOrder &&
          s['weight'] is num,
      orElse: () => null,
    );

    if (loggedDrop != null) {
      return (loggedDrop['weight'] as num).toDouble();
    }

    // ---------- 2️⃣ planned drop ----------
    final plannedDrop = drops.firstWhere(
      (s) => s['dropOrder'] == targetOrder && s['weight'] is num,
      orElse: () => {},
    );

    if (plannedDrop.isNotEmpty) {
      return (plannedDrop['weight'] as num).toDouble();
    }

    // ---------- 3️⃣ fallback ----------
    double? raw;

    final prevDrop = drops.firstWhere(
      (d) => d['dropOrder'] == (targetOrder - 1) && d['weight'] is num,
      orElse: () => {},
    );

    if (prevDrop.isNotEmpty) {
      raw = (prevDrop['weight'] as num).toDouble() * 0.8;
    } else {
      final parent = getParentWeight();
      if (parent == null) return null;
      final pct = ladderPercent(targetOrder);
      raw = parent * (pct / 100.0);
    }

    if (raw == null || raw <= 0) return null;

    // ---------- snap ----------
    double snapDown(double v) {
      if (v <= 10.0) {
        final r = v.floorToDouble();
        return r > 0 ? r : 1.0;
      } else {
        final even = ((v / 2).floor()) * 2;
        return even > 0 ? even.toDouble() : 2.0;
      }
    }

    return snapDown(raw);
  }
}

String formatHeightText(
  double? storedHeight,
  bool storedIsCm,
  double? tempHeight,
  bool tempIsCm,
  bool pageIsCm,
) {
  {
    // ---------- no value ----------
    if ((tempHeight == null || tempHeight <= 0) &&
        (storedHeight == null || storedHeight <= 0)) {
      return 'Select';
    }

    final bool hasTemp = tempHeight != null && tempHeight! > 0;
    final double value = hasTemp ? tempHeight! : storedHeight!;
    final bool useCm = hasTemp ? pageIsCm : storedIsCm;

    if (useCm) {
      // value הוא ס"מ
      if (value % 1 == 0) return '${value.toInt()} cm';
      return '${value.toStringAsFixed(1)} cm';
    } else {
      // value הוא total inches
      final int totalInches = value.round();
      final int ft = totalInches ~/ 12;
      final int inch = totalInches % 12;

      if (inch == 0) return '$ft ft';
      return '$ft ft $inch in';
    }
  }
}

String formatWeightText(
  double? storedWeight,
  bool storedIsKg,
  double? tempWeight,
  bool tempIsKg,
  bool pageIsKg,
) {
  {
    // ---------- helper ----------
    String formatNumber(double v) {
      if (v % 1 == 0) {
        return v.toInt().toString();
      }
      return v.toStringAsFixed(1);
    }

    // ---------- no value ----------
    if ((tempWeight == null || tempWeight <= 0) &&
        (storedWeight == null || storedWeight <= 0)) {
      return 'Select';
    }

    // ---------- decide value ----------
    final bool hasTemp = tempWeight != null && tempWeight! > 0;
    final double value = hasTemp ? tempWeight! : storedWeight!;

    // ---------- decide unit ----------
    final bool useKg = hasTemp ? pageIsKg : storedIsKg;

    // ---------- format ----------
    final unit = useKg ? 'kg' : 'lb';
    return '${formatNumber(value)} $unit';
  }
}

String formatBirthdayText(
  String? storedBirthday,
  String? tempBirthday,
) {
  {
    // ---------- helper: parse ISO / sqlite / epoch ----------
    DateTime? parseToLocal(String? input) {
      if (input == null) return null;
      var s = input.trim();
      if (s.isEmpty) return null;

      // epoch milliseconds
      final onlyDigits = RegExp(r'^\d+$');
      if (onlyDigits.hasMatch(s)) {
        final ms = int.tryParse(s);
        if (ms != null) {
          return DateTime.fromMillisecondsSinceEpoch(ms).toLocal();
        }
      }

      // SQLite "YYYY-MM-DD HH:MM(:SS)" → ISO
      final sqliteRe = RegExp(r'^(\d{4}-\d{2}-\d{2}) (\d{2}:\d{2}(:\d{2})?)$');
      if (sqliteRe.hasMatch(s)) {
        s = s.replaceFirst(' ', 'T');
      }

      try {
        return DateTime.parse(s).toLocal();
      } catch (_) {
        return null;
      }
    }

    // ---------- decide which value to show ----------
    final String? source =
        (tempBirthday != null && tempBirthday.trim().isNotEmpty)
            ? tempBirthday
            : (storedBirthday != null && storedBirthday.trim().isNotEmpty)
                ? storedBirthday
                : null;

    if (source == null) return 'Select';

    final dt = parseToLocal(source);
    if (dt == null) return 'Select';

    // ---------- format birthday nicely ----------
    try {
      return DateFormat('dd MMM yyyy').format(dt);
    } catch (_) {
      return 'Select';
    }
  }
}

String formatSexText(
  String? storedSex,
  String? tempSex,
) {
  {
    final temp = tempSex?.trim();
    if (temp != null && temp.isNotEmpty) {
      return temp;
    }

    final stored = storedSex?.trim();
    if (stored != null && stored.isNotEmpty) {
      return stored;
    }

    return 'Select';
  }
}

DateTime getInitialBirthdayForPicker(
  String? storedIso,
  String? tempIso,
) {
  {
    DateTime? parse(String? input) {
      if (input == null) return null;
      final s = input.trim();
      if (s.isEmpty) return null;

      try {
        return DateTime.parse(s);
      } catch (_) {
        return null;
      }
    }

    // 1️⃣ עדיפות לערך זמני
    final tempDate = parse(tempIso);
    if (tempDate != null) {
      return tempDate;
    }

    // 2️⃣ אחרת – ערך מהדאטה
    final storedDate = parse(storedIso);
    if (storedDate != null) {
      return storedDate;
    }

    // 3️⃣ ברירת מחדל – גיל מינימלי (13)
    final now = DateTime.now();
    return DateTime(
      now.year - 13,
      now.month,
      now.day,
    );
  }
}

dynamic getInitialHeightForPicker(
  double? storedHeight,
  bool storedIsCm,
  double? tempHeight,
  bool tempIsCm,
) {
  {
    // ---------- case 1: temp value wins ----------
    if (tempHeight != null) {
      return {
        'height': tempHeight,
        'isCm': tempIsCm,
      };
    }

    // ---------- case 2: stored value ----------
    if (storedHeight != null) {
      return {
        'height': storedHeight,
        'isCm': storedIsCm,
      };
    }

    // ---------- case 3: no data -> minimum ----------
    final double minHeight = tempIsCm ? 120.0 : 48.0;

    return {
      'height': minHeight,
      'isCm': tempIsCm,
    };
  }
}

String getInitialBirthdayStringForPicker(
  String? tempBirthday,
  String? storedBirthday,
) {
  {
    if (tempBirthday != null && tempBirthday.trim().isNotEmpty) {
      return tempBirthday.trim();
    }

    if (storedBirthday != null && storedBirthday.trim().isNotEmpty) {
      return storedBirthday.trim();
    }

    // ברירת מחדל – גיל מינימלי (בערך 13)
    return '2011-01-01';
  }
}

String getInitialSexForPicker(
  String? tempSex,
  String? storedSex,
) {
  {
    if (tempSex != null && tempSex.trim().isNotEmpty) {
      return tempSex.trim();
    }

    if (storedSex != null && storedSex.trim().isNotEmpty) {
      return storedSex.trim();
    }

    return 'Not set';
  }
}

dynamic getInitialWeightPickerValue(
  double? storedWeight,
  bool storedIsKg,
  double? tempWeight,
  bool tempIsKg,
) {
  {
    // --- case 1: temp value has priority ---
    if (tempWeight != null && tempWeight > 0) {
      return {
        'weight': tempWeight,
        'isKg': tempIsKg,
      };
    }

    // --- case 2: fallback to stored data ---
    if (storedWeight != null && storedWeight > 0) {
      return {
        'weight': storedWeight,
        'isKg': storedIsKg,
      };
    }

    // --- case 3: default minimal value ---
    return {
      'weight': tempIsKg ? 30.0 : 66.0, // 30kg ≈ 66lbs
      'isKg': tempIsKg,
    };
  }
}

dynamic getInitialValueForSetField(
  List<dynamic> loggedSets,
  List<dynamic> exerciseSets,
  int exerciseId,
  int setNumber,
  String fieldName,
) {
  {
    try {
      if (!['reps', 'weight'].contains(fieldName)) return null;

      // ---------- 1️⃣ PRIORITY: loggedSets ----------
      for (final it in loggedSets) {
        if (it is! Map) continue;

        if (it['exerciseId']?.toString() != exerciseId.toString()) continue;
        if (it['setNumber']?.toString() != setNumber.toString()) continue;
        if (it['isDropSet'] == true || it['isDropSet'] == 1) continue;

        final lookupField = fieldName == 'reps' ? 'targetReps' : 'targetWeight';

        final value = it[lookupField];
        if (value == null) continue;

        if (value is num) {
          if (value == 0) continue;
          return value % 1 == 0 ? value.toInt() : value.toDouble();
        }

        if (value is String && value.trim().isNotEmpty) {
          return value;
        }
      }

      // ---------- 2️⃣ FALLBACK: exerciseSets ----------
      for (final ex in exerciseSets) {
        if (ex is! Map) continue;
        if (ex['exerciseId']?.toString() != exerciseId.toString()) continue;

        final sets = ex['sets'];
        if (sets is! List) continue;

        for (final s in sets) {
          if (s is! Map) continue;
          if (s['setNumber']?.toString() != setNumber.toString()) continue;

          final targetField =
              fieldName == 'reps' ? 'targetReps' : 'targetWeight';

          final targetValue = s[targetField];
          if (targetValue == null) continue;

          if (targetValue is num) {
            if (targetValue == 0) continue;
            return targetValue % 1 == 0
                ? targetValue.toInt()
                : targetValue.toDouble();
          }

          if (targetValue is String && targetValue.trim().isNotEmpty) {
            return targetValue;
          }
        }
      }

      return null;
    } catch (_) {
      return null;
    }
  }
}

double intToDouble(int value) {
  {
    return value.toDouble();
  }
}

dynamic getInitialValueForDropSetField(
  List<dynamic> loggedSets,
  List<dynamic> dropSets,
  int exerciseId,
  int parentSetNumber,
  int? dropOrder,
  String fieldName,
) {
  {
    try {
      if (!['reps', 'weight'].contains(fieldName)) return null;

      // ==================================================
      // 1️⃣ PRIORITY: loggedSets (ערך בפועל)
      // ==================================================
      for (final it in loggedSets) {
        if (it is! Map) continue;

        if (it['exerciseId']?.toString() != exerciseId.toString()) continue;
        if (it['setNumber']?.toString() != parentSetNumber.toString()) continue;
        if (!(it['isDropSet'] == true || it['isDropSet'] == 1)) continue;
        if (it['dropOrder']?.toString() != dropOrder.toString()) continue;

        final value = it[fieldName];
        if (value == null) break;

        if (value is num) {
          if (value == 0) break;
          return value % 1 == 0 ? value.toInt() : value.toDouble();
        }

        if (value is String && value.trim().isNotEmpty) {
          return value;
        }

        break;
      }

      // ==================================================
      // 2️⃣ FALLBACK: dropSets (תכנון / DB)
      // ==================================================
      for (final d in dropSets) {
        if (d is! Map) continue;

        if (d['exerciseId']?.toString() != exerciseId.toString()) continue;
        if (d['parentSetNumber']?.toString() != parentSetNumber.toString())
          continue;
        if (d['dropOrder']?.toString() != dropOrder.toString()) continue;

        final value = d[fieldName];
        if (value == null) return null;

        if (value is num) {
          if (value == 0) return null;
          return value % 1 == 0 ? value.toInt() : value.toDouble();
        }

        if (value is String && value.trim().isNotEmpty) {
          return value;
        }

        return null;
      }

      // ==================================================
      // 3️⃣ NOTHING
      // ==================================================
      return null;
    } catch (_) {
      return null;
    }
  }
}

int? resolveDurationSecondsForLoggedSet(
  int? componentDurationSeconds,
  List<dynamic> exerciseSets,
  int exerciseId,
  int setNumber,
) {
  {
    int asInt(dynamic v) {
      if (v == null) return 0;
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse(v.toString()) ?? 0;
    }

    // 1️⃣ ערך מהקומפוננט מנצח
    if ((componentDurationSeconds ?? 0) > 0) {
      return componentDurationSeconds;
    }

    // 2️⃣ fallback – מה־exerciseSets
    for (final e in exerciseSets) {
      if (e is! Map) continue;
      if (asInt(e['exerciseId']) != exerciseId) continue;

      final sets = e['sets'];
      if (sets is! List) continue;

      for (final s in sets) {
        if (s is! Map) continue;
        if (asInt(s['setNumber']) != setNumber) continue;

        final dur = asInt(s['durationSeconds']);
        if (dur > 0) return dur;
      }
    }

    // 3️⃣ אין ערך
    return null;
  }
}

int? resolveSetDurationMs(
  int? currentDurationMs,
  List<dynamic> exerciseSets,
  int exerciseId,
  int setNumber,
  List<dynamic> loggedSets,
) {
  {
    int asInt(dynamic v) {
      if (v == null) return 0;
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse(v.toString()) ?? 0;
    }

    // 1️⃣ Candidate מה־UI מנצח
    if ((currentDurationMs ?? 0) > 0) {
      return currentDurationMs;
    }

    // 2️⃣ Logged set (מה שכבר אושר)
    for (final l in loggedSets) {
      if (l is! Map) continue;
      if (asInt(l['exerciseId']) != exerciseId) continue;
      if (asInt(l['setNumber']) != setNumber) continue;
      if (asInt(l['durationSeconds']) > 0) {
        return asInt(l['durationSeconds']);
      }
    }

    // 3️⃣ Template (exerciseSets)
    for (final e in exerciseSets) {
      if (e is! Map) continue;
      if (asInt(e['exerciseId']) != exerciseId) continue;

      final sets = e['sets'];
      if (sets is! List) continue;

      for (final s in sets) {
        if (s is! Map) continue;
        if (asInt(s['setNumber']) != setNumber) continue;

        final dur = asInt(s['durationSeconds']);
        if (dur > 0) return dur;
      }
    }

    // 4️⃣ אין ערך
    return null;
  }
}

List<dynamic> toggleExerciseSelectionWithBodyweightFlag(
  List<dynamic>? selected,
  int exerciseId,
  String exerciseName,
  int isBodyweight,
) {
  {
    // רשימה ריקה אם null
    final List<Map<String, dynamic>> updated = (selected ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();

    // בודק אם התרגיל כבר קיים ברשימה
    final existsIndex = updated.indexWhere(
      (e) => e['exerciseId'] == exerciseId,
    );

    if (existsIndex >= 0) {
      // קיים → מוחקים
      updated.removeAt(existsIndex);
    } else {
      // לא קיים → מוסיפים
      updated.add({
        'exerciseId': exerciseId,
        'exerciseName': exerciseName,
        'isBodyweight': isBodyweight == 1 ? 1 : 0, // 🔒 תמיד int
      });
    }

    return updated;
  }
}

bool showPlusWeightButton(
  int isBodyweight,
  List<dynamic> exerciseSets,
  int exerciseId,
  int setNumber,
) {
  {
    if (isBodyweight != 1) return false;

    Map<String, dynamic>? ex;

    for (final e in exerciseSets) {
      if (e is Map && e['exerciseId'] == exerciseId) {
        ex = Map<String, dynamic>.from(e);
        break;
      }
    }

    if (ex == null) return false;

    final sets = ex['sets'];
    if (sets is! List) return false;

    Map<String, dynamic>? set;

    for (final s in sets) {
      if (s is Map && s['setNumber'] == setNumber) {
        set = Map<String, dynamic>.from(s);
        break;
      }
    }

    if (set == null) return false;

    final raw = set['weighted'];
    int weighted;

    if (raw is int) {
      weighted = raw;
    } else if (raw is bool) {
      weighted = raw ? 1 : 0;
    } else {
      weighted = 0;
    }

    return weighted == 0;
  }
}

String? getWorkoutIdForDay(
  List<dynamic> weeklySchedule,
  int dayIndex,
) {
  {
    for (final item in weeklySchedule) {
      if (item is! Map) continue;

      if (item['dayIndex'] == dayIndex) {
        return item['workoutId'];
      }
    }

    return null;
  }
}

bool hasWorkoutOnDay(
  List<dynamic> week,
  int dayIndex,
) {
  {
    if (week == null || week.isEmpty) return false;
    if (dayIndex < 0 || dayIndex >= week.length) return false;

    final day = week[dayIndex];
    if (day is! Map<String, dynamic>) return false;

    if (!day.containsKey('workoutId')) return false;

    final workoutId = day['workoutId'];

    // reject null, empty, or non-string ids
    if (workoutId == null) return false;
    if (workoutId is! String) return false;
    if (workoutId.trim().isEmpty) return false;

    return true;
  }
}

bool isSetLoading(
  List<dynamic> analysisList,
  int exerciseId,
  int setNumber,
) {
  {
    if (analysisList == null) return false;
    if (analysisList is! List) return false;

    for (final item in analysisList) {
      if (item is! Map) continue;

      if (item['exerciseId'] != exerciseId) continue;

      final sets = item['sets'];
      if (sets is! List) return false;

      for (final s in sets) {
        if (s is! Map) continue;

        if (s['setNumber'] == setNumber) {
          return s['isProcessing'] == true;
        }
      }
    }

    return false;
  }
}

dynamic getSetAnalysisField(
  List<dynamic> analysisList,
  int exerciseId,
  int setNumber,
  String fieldKey,
) {
  {
    try {
      for (final exercise in analysisList) {
        if (exercise is! Map) continue;
        if (exercise['exerciseId'] != exerciseId) continue;

        final sets = exercise['sets'];
        if (sets is! List) continue;

        for (final s in sets) {
          if (s is! Map) continue;
          if (s['setNumber'] != setNumber) continue;

          final analysis = s['analysis'];
          if (analysis is! Map) return null;

          // הנתונים עטופים ב-"result" — ככה הם מגיעים מהשרת
          final data =
              analysis['result'] is Map ? analysis['result'] as Map : analysis;

          return data[fieldKey];
        }
      }
    } catch (e) {
      print("getSetAnalysisField error: $e");
    }
    return null;
  }
}

bool isSetAnalysisDone(
  List<dynamic> analysisList,
  int exerciseId,
  int setNumber,
) {
  {
    if (analysisList is! List) return false;

    for (final item in analysisList) {
      if (item['exerciseId'] != exerciseId) continue;

      final sets = item['sets'];
      if (sets is! List) continue;

      for (final s in sets) {
        if (s['setNumber'] != setNumber) continue;

        return (s['analysisDone'] == true) && (s['isProcessing'] != true);
      }
    }

    return false;
  }
}

bool shouldShowCameraButton(
  List<dynamic> analysisList,
  int exerciseId,
  int setNumber,
  int analysisCount,
  bool isPremium,
  List<dynamic> loggedSets,
) {
  {
    // --- Quota gate (free users) ---
    const int freeMonthlyLimit = 5;
    if (!isPremium && analysisCount >= freeMonthlyLimit) {
      return false;
    }

    // --- Done gate: a logged set never shows the camera ---
    int? toInt(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v.trim());
      return null;
    }

    for (final s in loggedSets) {
      if (s is! Map) continue;
      final exId = toInt(s['exerciseId']) ?? toInt(s['exercise_id']);
      final sn = toInt(s['setNumber']) ?? toInt(s['set_number']);
      if (exId == exerciseId && sn == setNumber) {
        return false;
      }
    }

    // --- Per-set state (existing logic) ---
    if (analysisList.isEmpty) return true;

    for (final item in analysisList) {
      if (item is! Map) continue;

      if (item['exerciseId'] != exerciseId) continue;

      final sets = item['sets'];
      if (sets is! List) return true;

      for (final s in sets) {
        if (s is! Map) continue;

        if (s['setNumber'] == setNumber) {
          final isProcessing = s['isProcessing'] == true;
          final analysisDone = s['analysisDone'] == true;
          final hasError = s['hasError'] == true;

          // אם אחד מהם true → לא להראות מצלמה
          if (isProcessing || analysisDone || hasError) {
            return false;
          }

          return true;
        }
      }
    }

    return true;
  }
}

bool? hasAnalyzedVideo(
  List<dynamic>? analysisList,
  int exerciseId,
  int setNumber,
) {
  {
    if (analysisList == null) return false;

    final exercise = analysisList.firstWhere(
      (e) => e['exerciseId'] == exerciseId,
      orElse: () => null,
    );

    if (exercise == null) return false;

    final sets = exercise['sets'] as List<dynamic>?;
    if (sets == null) return false;

    final set = sets.firstWhere(
      (s) => s['setNumber'] == setNumber,
      orElse: () => null,
    );

    if (set == null) return false;

    final videoUrl = set['analyzedVideoUrl'];

    return videoUrl != null && videoUrl.toString().isNotEmpty;
  }
}

String getAnalyzedVideoUrl(
  List<dynamic> analysisList,
  int exerciseId,
  int setNumber,
) {
  {
    final exerciseIndex =
        analysisList.indexWhere((e) => e['exerciseId'] == exerciseId);

    if (exerciseIndex == -1) return "";

    final exercise = analysisList[exerciseIndex] as Map<String, dynamic>;

    final sets = (exercise['sets'] as List<dynamic>? ?? []);

    final setIndex = sets.indexWhere((s) => s['setNumber'] == setNumber);

    if (setIndex == -1) return "";

    final set = sets[setIndex] as Map<String, dynamic>;

    final videoUrl = set['analyzedVideoUrl'];

    return (videoUrl != null && videoUrl.toString().isNotEmpty)
        ? videoUrl.toString()
        : "";
  }
}

bool shouldShowErrorButton(
  List<dynamic> analysisList,
  int exerciseId,
  int setNumber,
) {
  {
    for (final item in analysisList) {
      if (item is! Map) continue;

      if (item['exerciseId'] != exerciseId) continue;

      final sets = item['sets'];
      if (sets is! List) return false;

      for (final s in sets) {
        if (s is! Map) continue;

        if (s['setNumber'] == setNumber) {
          return s['hasError'] == true;
        }
      }
    }

    // Not found - no error button.
    return false;
  }
}

String getGoodFormMessage() {
  {
    return "Great form! Keep it up 💪";
  }
}

int getSetTechniqueScore(
  List<dynamic> analysisList,
  int exerciseId,
  int setNumber,
) {
  {
    try {
      for (final exercise in analysisList) {
        if (exercise is! Map) continue;
        if (exercise['exerciseId'] != exerciseId) continue;

        final sets = exercise['sets'];
        if (sets is! List) continue;

        for (final s in sets) {
          if (s is! Map) continue;
          if (s['setNumber'] != setNumber) continue;

          final analysis = s['analysis'];
          if (analysis is! Map) return 0;

          final data =
              analysis['result'] is Map ? analysis['result'] as Map : analysis;

          final score = data['technique_score'];

          if (score is int) return score;
          if (score is double) return score.round();
          if (score is String) {
            return int.tryParse(score) ?? double.tryParse(score)?.round() ?? 0;
          }

          return 0;
        }
      }
    } catch (e) {
      print("getSetTechniqueScore error: $e");
    }

    return 0;
  }
}

String getGreeting(String username) {
  {
    final hour = DateTime.now().hour;

    if (hour >= 5 && hour < 12) {
      return 'Good morning, $username — ready to train?';
    } else if (hour >= 12 && hour < 17) {
      return 'Good afternoon, $username — time to get moving';
    } else if (hour >= 17 && hour < 21) {
      return 'Good evening, $username — evening sessions hit different';
    } else {
      return 'Up late, $username? Rest is part of the grind';
    }
  }
}

bool isExerciseComplete(
  List<dynamic> completedExercises,
  int exerciseId,
) {
  {
    final entry = completedExercises.firstWhere(
      (e) => e['exerciseId'] == exerciseId,
      orElse: () => null,
    );
    return entry?['isComplete'] == true;
  }
}

String calculateElapsedTimeFormatted(
  DateTime startTime,
  DateTime currentTime,
) {
  {
    final diff = currentTime.difference(startTime);

    int totalSeconds = diff.inSeconds;
    if (totalSeconds < 0) totalSeconds = 0;

    final h = totalSeconds ~/ 3600;
    final m = (totalSeconds % 3600) ~/ 60;
    final s = totalSeconds % 60;

    if (h > 0) {
      return '${h}h ${m}m ${s}s';
    } else if (m > 0) {
      return '${m}m ${s}s';
    } else {
      return '${s}s';
    }
  }
}

String? exerciseImagePath(String? exerciseName) {
  {
    return 'assets/images/size_800x450.jpg';
  }
}

String exerciseImageName(String exerciseName) {
  {
    return exerciseName.replaceAll(' ', '_');
  }
}

int calculateElapsedMillis(
  DateTime startTime,
  DateTime currentTime,
) {
  {
    final diff = currentTime.difference(startTime);

    int millis = diff.inMilliseconds;
    if (millis < 0) millis = 0;

    return millis;
  }
}

dynamic getSetByExerciseAndNumber(
  List<dynamic> sets,
  int exerciseId,
  int setNumber,
) {
  {
    try {
      // הרשימה היא רשימה של exercises (לא sets ישירות).
      // כל exercise מכיל exerciseId ורשימת sets בתוכו.
      for (final exercise in sets) {
        if (exercise == null) continue;
        if (exercise['exerciseId'] != exerciseId) continue;

        final innerSets = exercise['sets'] as List?;
        if (innerSets == null) continue;

        for (final s in innerSets) {
          if (s == null) continue;
          if (s['setNumber'] == setNumber) {
            return s;
          }
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}

String getSetVideoPath(
  List<dynamic> analysisList,
  int exerciseId,
  int setNumber,
) {
  {
    if (analysisList == null || analysisList.isEmpty) return '';

    try {
      for (final exercise in analysisList) {
        if (exercise == null) continue;
        if (exercise is! Map) continue;
        if (exercise['exerciseId'] != exerciseId) continue;

        final innerSets = exercise['sets'] as List?;
        if (innerSets == null) continue;

        for (final s in innerSets) {
          if (s == null) continue;
          if (s is! Map) continue;
          if (s['setNumber'] != setNumber) continue;

          final analysis = s['analysis'];
          if (analysis == null) return '';
          if (analysis is! Map) return '';

          // Prefer _source_video_uri (used by the player widget). Fall
          // back to video_path if that's the only one present.
          final uri = analysis['_source_video_uri'] as String?;
          if (uri != null && uri.isNotEmpty) return uri;

          final vp = analysis['video_path'] as String?;
          if (vp != null && vp.isNotEmpty) return vp;

          return '';
        }
      }
    } catch (_) {
      return '';
    }

    return '';
  }
}

List<String> toggleMuscle(
  List<String> currentList,
  String muscle,
) {
  {
    // Work on a copy so we never mutate the original state list directly.
    final List<String> updated = List<String>.from(currentList);

    if (updated.contains(muscle)) {
      updated.remove(muscle); // second tap → deselect
    } else {
      updated.add(muscle); // first tap → select
    }

    return updated;
  }
}

bool isMuscleSelectedAi(
  List<String> currentList,
  String? muscle,
) {
  {
    return currentList.contains(muscle);
  }
}

List<String> getMusclesForSplit(String split) {
  {
    switch (split.toLowerCase()) {
      case 'push':
        // חזה, כתף קדמית + צדדית, טרייספס
        return ['Chest', 'Front Delts', 'Side Delts', 'Triceps'];
      case 'pull':
        // גב מלא, כתף אחורית, ביצפס
        return ['Lats', 'Upper Back', 'Traps', 'Rear Delts', 'Biceps'];
      case 'legs':
        // כל שרירי הרגליים העיקריים
        return ['Quads', 'Hamstrings', 'Glutes', 'Calves'];
      case 'full body':
        // מכל אזור עיקרי אחד-שניים, אימון מאוזן
        return [
          'Chest',
          'Lats',
          'Upper Back',
          'Front Delts',
          'Side Delts',
          'Quads',
          'Hamstrings',
          'Glutes',
          'Biceps',
          'Triceps',
        ];
      default:
        return <String>[];
    }
  }
}

String mapGoal(int goalIndex) {
  {
    switch (goalIndex) {
      case 0:
        return 'Hypertrophy';
      case 1:
        return 'Strength';
      case 2:
        return 'Muscular Endurance';
      default:
        return 'Hypertrophy'; // fallback
    }
  }
}

int countItems(List<dynamic> items) {
  {
    if (items is List) {
      return items.length;
    }
    return 0;
  }
}

bool canAnalyze(
  bool isPremium,
  int analysisCount,
) {
  {
    if (isPremium) {
      return true;
    }

    const int freeMonthlyLimit = 5;
    return analysisCount < freeMonthlyLimit;
  }
}

bool shouldShowLockButton(
  List<dynamic> analysisList,
  int exerciseId,
  int setNumber,
  bool isPremium,
  int analysisCount,
) {
  {
    // Premium users never see a lock.
    if (isPremium) {
      return false;
    }

    // Quota not exhausted → camera handles this set, no lock.
    const int freeWeeklyLimit = 3;
    if (analysisCount < freeWeeklyLimit) {
      return false;
    }

    // Quota exhausted. Show the lock ONLY if this set is "idle" —
    // i.e. the camera would have been shown were it not for the quota.
    // Sets that are processing / done / errored keep their own state UI.
    if (analysisList.isEmpty) return true;

    for (final item in analysisList) {
      if (item is! Map) continue;

      if (item['exerciseId'] != exerciseId) continue;

      final sets = item['sets'];
      if (sets is! List) return true;

      for (final s in sets) {
        if (s is! Map) continue;

        if (s['setNumber'] == setNumber) {
          final isProcessing = s['isProcessing'] == true;
          final analysisDone = s['analysisDone'] == true;
          final hasError = s['hasError'] == true;

          // Set has its own state → no lock on top of it.
          if (isProcessing || analysisDone || hasError) {
            return false;
          }

          return true;
        }
      }
    }

    return true;
  }
}

List<String>? parseFeedback(String raw) {
  {
    if (raw == null || raw.trim().isEmpty) {
      return [];
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded
            .map((e) => e.toString())
            .where((s) => s.trim().isNotEmpty)
            .toList();
      }
      // Valid JSON but not a list (e.g. a bare string) → single item.
      return [decoded.toString()];
    } catch (_) {
      // Not valid JSON → treat the raw value as one feedback line.
      return [raw];
    }
  }
}

List<dynamic> flattenAnalyzedSets(List<dynamic> analysisList) {
  {
    final out = <Map<String, dynamic>>[];

    if (analysisList == null) return out;

    for (final item in analysisList) {
      if (item is! Map) continue;

      final exerciseId = item['exerciseId'];
      if (exerciseId == null) continue;

      final sets = item['sets'];
      if (sets is! List) continue;

      for (final s in sets) {
        if (s is! Map) continue;

        // Only sets with a completed analysis are relevant for saving.
        if (s['analysisDone'] != true) continue;
        if (s['analysis'] == null) continue;

        // Skip sets that never got a set_log id attached - without it
        // the insert into set_analysis would fail on NOT NULL.
        final setLogId = s['setLogId'];
        if (setLogId == null || setLogId.toString().trim().isEmpty) continue;

        out.add({
          'exerciseId': exerciseId,
          'setNumber': s['setNumber'],
          'setLogId': setLogId,
          'analysis': s['analysis'],
        });
      }
    }

    return out;
  }
}

List<dynamic> flattenWarmupSets(List<dynamic> warmupList) {
  {
    final out = <Map<String, dynamic>>[];

    if (warmupList == null) return out;

    for (final item in warmupList) {
      if (item is! Map) continue;

      final exerciseId = item['exerciseId'];
      if (exerciseId == null) continue;

      // Skip exercises whose warmup block is hidden.
      if (item['hidden'] == true) continue;

      final sets = item['sets'];
      if (sets is! List) continue;

      for (final s in sets) {
        if (s is! Map) continue;

        out.add({
          'exerciseId': exerciseId,
          'setNumber': s['setNumber'],
          'percent': s['percent'],
          'reps': s['reps'],
          'repsText': s['repsText'],
          'weight': s['weight'],
          'isDone': s['isDone'] == true,
        });
      }
    }

    return out;
  }
}

String? getProfileImageToShow(
  String? tempImage,
  String? profileImage,
) {
  {
    // Temp (local page state) wins if it has a real value.
    if (tempImage != null && tempImage.trim().isNotEmpty) {
      return tempImage;
    }

    // Fall back to the persisted app state value.
    if (profileImage != null && profileImage.trim().isNotEmpty) {
      return profileImage;
    }

    return null;
  }
}

String? getPlanName(int plan) {
  {
    if (plan == 1) return 'Monthly';
    if (plan == 2) return 'Yearly';
    return 'Free';
  }
}

String? getWarmupSetField(
  List<dynamic> warmupList,
  int exerciseId,
  int setNumber,
  String field,
) {
  {
    if (warmupList == null) return null;

    for (final item in warmupList) {
      if (item is! Map) continue;
      if (item['exerciseId'] != exerciseId) continue;

      final sets = item['sets'];
      if (sets is! List) return null;

      for (final s in sets) {
        if (s is! Map) continue;
        if (s['setNumber'] != setNumber) continue;

        if (field == 'reps') {
          final t = s['repsText'];
          if (t != null && t.toString().trim().isNotEmpty) {
            return t.toString();
          }
          final r = s['reps'];
          return r?.toString();
        }

        if (field == 'weight') {
          final w = s['weight'];
          if (w == null) return null;
          final str = w.toString().trim();
          return str.isEmpty ? null : str;
        }

        return null;
      }

      return null;
    }

    return null;
  }
}

int getIsSuperset(
  List<dynamic> exerciseSets,
  int exerciseId,
) {
  {
    if (exerciseSets == null) return 0;

    for (final item in exerciseSets) {
      if (item is! Map) continue;
      if (item['exerciseId'] != exerciseId) continue;

      final v = item['isSuperset'];
      if (v == true || v == 1) return 1;
      return 0;
    }

    return 0;
  }
}

String? getSupersetGroupId(
  List<dynamic> exerciseSets,
  int exerciseId,
) {
  {
    if (exerciseSets == null) return '';

    for (final item in exerciseSets) {
      if (item is! Map) continue;
      if (item['exerciseId'] != exerciseId) continue;

      final v = item['supersetGroupId'];
      if (v == null) return '';
      return v.toString();
    }

    return '';
  }
}

int parseTimerToMs(String? timeText) {
  {
    if (timeText == null) return 0;

    final t = timeText.trim().toLowerCase();
    if (t.isEmpty) return 0;

    int seconds = 0;

    if (t.contains('h') || t.contains('m') || t.contains('s')) {
      // Letter format: "1h 12m 45s" / "45m 30s" / "8s"
      final hMatch = RegExp(r'(\d+)\s*h').firstMatch(t);
      final mMatch = RegExp(r'(\d+)\s*m').firstMatch(t);
      final sMatch = RegExp(r'(\d+)\s*s').firstMatch(t);

      if (hMatch == null && mMatch == null && sMatch == null) return 0;

      final h = int.tryParse(hMatch?.group(1) ?? '0') ?? 0;
      final m = int.tryParse(mMatch?.group(1) ?? '0') ?? 0;
      final s = int.tryParse(sMatch?.group(1) ?? '0') ?? 0;

      seconds = h * 3600 + m * 60 + s;
    } else if (t.contains(':')) {
      // Colon format: "45:30" / "1:12:45"
      final parts = t.split(':');
      final nums = <int>[];
      for (final p in parts) {
        final n = int.tryParse(p.trim());
        if (n == null) return 0;
        nums.add(n);
      }

      if (nums.length == 2) {
        seconds = nums[0] * 60 + nums[1];
      } else if (nums.length == 3) {
        seconds = nums[0] * 3600 + nums[1] * 60 + nums[2];
      } else {
        return 0;
      }
    } else {
      return 0;
    }

    return seconds * 1000;
  }
}

bool hasProfileImage(
  String? tempImage,
  String? profileImage,
) {
  {
    if (tempImage != null && tempImage.trim().isNotEmpty) {
      return true;
    }
    if (profileImage != null && profileImage.trim().isNotEmpty) {
      return true;
    }
    return false;
  }
}

String debugFirstAnalyzedSet(List<dynamic>? analysisList) {
  {
    if (analysisList == null || analysisList.isEmpty) {
      return 'analysisList: EMPTY';
    }

    for (final item in analysisList) {
      if (item is! Map) continue;

      final exerciseId = item['exerciseId'];
      final sets = item['sets'];
      if (sets is! List) continue;

      for (final s in sets) {
        if (s is! Map) continue;

        final analysis = s['analysis'];
        final score = (analysis is Map) ? analysis['technique_score'] : null;
        final reps = (analysis is Map) ? analysis['squat_count'] : null;
        final good = (analysis is Map) ? analysis['good_reps'] : null;

        return 'ex=$exerciseId | set=${s['setNumber']} | '
            'done=${s['analysisDone']} | proc=${s['isProcessing']} | '
            'err=${s['hasError']} | '
            'setLogId=${s['setLogId'] ?? 'MISSING'} | '
            'score=$score | reps=$reps | good=$good';
      }
    }

    return 'analysisList: ${analysisList.length} items, no valid sets found';
  }
}

dynamic getHeroWorkout(
  List<WorkoutHomeRow> workouts,
  int index,
) {
  {
    if (workouts.isEmpty) return null;

    final row = workouts[index % workouts.length];

    // Column getters are generated from the query's field names.
    final String id = row.id ?? '';
    final String name =
        (row.name == null || row.name!.trim().isEmpty) ? 'Workout' : row.name!;
    final int exerciseCount = row.exerciseCount ?? 0;

    String lastDone = 'never done';
    final raw = row.lastDoneAt;
    if (raw != null && raw.trim().isNotEmpty) {
      final dt = DateTime.tryParse(raw);
      if (dt != null) {
        final diff = DateTime.now().difference(dt);
        if (diff.inMinutes < 60) {
          lastDone = 'just now';
        } else if (diff.inHours < 24) {
          lastDone = '${diff.inHours}h ago';
        } else if (diff.inDays == 1) {
          lastDone = 'yesterday';
        } else {
          lastDone = '${diff.inDays}d ago';
        }
      }
    }

    return {
      'id': id,
      'name': name,
      'exerciseCount': exerciseCount,
      'lastDone': lastDone,
      'meta': '$name · $exerciseCount exercises · $lastDone',
    };
  }
}

dynamic buildUserAppState(dynamic userJson) {
  {
    if (userJson is! Map) return null;

    return {
      'username': (userJson['username'] ?? '').toString(),
      'birthday': (userJson['date_of_birth'] ?? '').toString(),
      'height': (() {
        final v = userJson['height'];
        if (v is num) return v.toDouble();
        return double.tryParse(v?.toString() ?? '') ?? 0.0;
      })(),
    };
  }
}

String? getAnalysisErrorMessage(
  List<dynamic> analysisList,
  int exerciseId,
  int setNumber,
  String exerciseName,
) {
  {
    const String technicalMsg =
        'Something went wrong while analyzing this video. '
        'Please try again - if it keeps happening, try re-recording.';

    if (analysisList == null || analysisList.isEmpty) {
      return technicalMsg;
    }

    int asInt(dynamic v) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse(v?.toString() ?? '') ?? 0;
    }

    for (final item in analysisList) {
      if (item is! Map) continue;
      if (asInt(item['exerciseId']) != exerciseId) continue;

      final sets = item['sets'];
      if (sets is! List) break;

      for (final s in sets) {
        if (s is! Map) continue;
        if (asInt(s['setNumber']) != setNumber) continue;

        final analysis = s['analysis'];

        // Case 1: analysis RAN but found no reps - user's video issue.
        if (analysis is Map && asInt(analysis['squat_count']) == 0) {
          final String ex =
              (exerciseName == null || exerciseName.trim().isEmpty)
                  ? 'rep'
                  : exerciseName.trim().toLowerCase();
          return "Couldn't analyze this video - make sure your full "
              "body is visible and that you complete at least one $ex.";
        }

        // Case 2: no analysis stored (technical failure).
        return technicalMsg;
      }
    }

    // Set not found at all - technical fallback.
    return technicalMsg;
  }
}

bool isAnalysisValid(dynamic analysisResult) {
  {
    if (analysisResult is! Map) return false;

    int asInt(dynamic v) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse(v?.toString() ?? '') ?? 0;
    }

    // A valid analysis detected at least one rep.
    return asInt(analysisResult['squat_count']) > 0;
  }
}

List<String> testMuscles() {
  return ['Quads', 'Hamstrings', 'Glutes'];
}

int returnTen() {
  return 10;
}

bool? showPerfectScoreIcon(double techniqueScore) {
  return techniqueScore >= 10.0;
}

String analysisQuotaLabel(
  int analysisCount,
  String analysisCountMonth,
  bool isPremium,
) {
  const int monthlyLimit = 5;

  // Premium users never see the chip - return empty so any
  // visibility check on this text hides it.
  if (isPremium) return '';

  // Self-healing month check (mirrors the reset logic in init):
  // if the stored month isn't the current month, the counter is
  // stale and the user effectively has a fresh quota.
  final now = DateTime.now();
  final currentMonth = '${now.year}-${now.month.toString().padLeft(2, '0')}';

  final int used = (analysisCountMonth == currentMonth) ? analysisCount : 0;

  final int left = (monthlyLimit - used).clamp(0, monthlyLimit);

  if (left == 0) return '0/$monthlyLimit left';
  return '$left/$monthlyLimit free left';
}

String quickCheckWorkoutName(String exerciseName) {
  final String name = exerciseName.trim();
  if (name.isEmpty) return 'Quick Form Check';
  return 'Quick Check — $name';
}

bool canStartQuickAnalysis(
  bool isPremium,
  int analysisCount,
  String analysisCountMonth,
) {
  // Premium users always can.
  if (isPremium) return true;

  const int freeMonthlyLimit = 5;

  // Self-healing month check (mirrors the init reset and the quota
  // label): if the stored month isn't the current month, the counter
  // is stale and the user effectively has a fresh quota.
  final now = DateTime.now();
  final currentMonth = '${now.year}-${now.month.toString().padLeft(2, '0')}';

  final int used = (analysisCountMonth == currentMonth) ? analysisCount : 0;

  return used < freeMonthlyLimit;
}

String lastWorkoutStats(
  int durationMs,
  double totalVolume,
  int totalSets,
) {
  final int totalMinutes = (durationMs / 60000).round();

  // Duration: "45m" under an hour, "1:03" from an hour up.
  final String dur = totalMinutes < 60
      ? '${totalMinutes}m'
      : '${totalMinutes ~/ 60}:${(totalMinutes % 60).toString().padLeft(2, '0')}';

  // Volume: rounded, thousands separator.
  final int vol = totalVolume.round();
  final String volStr = vol.toString().replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+$)'),
        (m) => '${m[1]},',
      );

  return '$dur · $volStr kg · $totalSets sets';
}

bool canGenerateWorkout(
  bool isPremium,
  List<String> generationDates,
) {
  if (isPremium) return true;

  const int weeklyLimit = 3;

  final now = DateTime.now();
  final cutoff = now.subtract(const Duration(days: 7));

  int recentCount = 0;
  for (final d in generationDates) {
    final parsed = DateTime.tryParse(d);
    if (parsed == null) continue; // ignore malformed entries
    if (parsed.isAfter(cutoff)) recentCount++;
  }

  return recentCount < weeklyLimit;
}

List<String> addGenerationDate(List<String> generationDates) {
  final now = DateTime.now();
  final cutoff = now.subtract(const Duration(days: 7));

  // Keep only entries from the last 7 days (self-cleaning, the list
  // never grows past a handful of items), then add now.
  final kept = generationDates.where((d) {
    final parsed = DateTime.tryParse(d);
    return parsed != null && parsed.isAfter(cutoff);
  }).toList();

  kept.add(now.toIso8601String());
  return kept;
}

String generationsLeftLabel(List<String> generationDates) {
  const int limit = 3;

  final cutoff = DateTime.now().subtract(const Duration(days: 7));
  int used = 0;
  for (final d in generationDates) {
    final parsed = DateTime.tryParse(d);
    if (parsed != null && parsed.isAfter(cutoff)) used++;
  }
  if (used > limit) used = limit;

  final int left = limit - used;

  if (left == 0) return '3/3 used this week';
  return '$left of $limit left this week';
}

int secondsToMs(int seconds) {
  return seconds * 1000;
}

int workoutDurationMs(DateTime startedAt) {
  final elapsed = DateTime.now().difference(startedAt).inMilliseconds;
  return elapsed < 0 ? 0 : elapsed;
}

String formatMsToMmSs(int? ms) {
  final int safeMs = ms ?? 0;
  final int totalSeconds = (safeMs / 1000).round().clamp(0, 359999);
  final int minutes = totalSeconds ~/ 60;
  final int seconds = totalSeconds % 60;

  return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
}

String navPageFromIndex(int index) {
  switch (index) {
    case 1:
      return 'history';
    case 2:
      return 'stats';
    case 3:
      return 'home';
    case 4:
      return 'library';
    default:
      return 'home';
  }
}

Color chartColorsat(int index) {
  const colors = [
    Color(0xFF3B82F6), // 0 - blue
    Color(0xFF10B981), // 1 - green
    Color(0xFFFACC15), // 2 - yellow
    Color(0xFFFB923C), // 3 - orange
    Color(0xFF8B5CF6), // 4 - purple
    Color(0xFF06B6D4), // 5 - cyan
    Color(0xFFEF4444), // 6 - red
    Color(0xFFEC4899), // 7 - pink
    Color(0xFF9CA3AF), // 8 - gray
  ];

  if (index < 0) return colors[0];
  return colors[index % colors.length];
}

double? getWeightFromLoggedSets(
  List<dynamic> loggedSets,
  int exerciseId,
  int setNumber,
) {
  {
    // helper parse
    double? toDouble(dynamic v) {
      if (v == null) return null;
      if (v is double) return v;
      if (v is int) return v.toDouble();
      return double.tryParse(v.toString().trim());
    }

    // -----------------------------------------
    // 1️⃣ הערך של הסט עצמו - מה שה-WeightField עשה לו commit
    // -----------------------------------------
    final own = loggedSets.firstWhere(
      (s) =>
          s is Map &&
          s['exerciseId'] == exerciseId &&
          s['setNumber'] == setNumber,
      orElse: () => null,
    );
    if (own != null) {
      final parsed = toDouble(own['weight']);
      if (parsed != null) return parsed;
    }

    // -----------------------------------------
    // 2️⃣ fallback - הסט הקודם הקרוב ביותר עם משקל
    // -----------------------------------------
    final loggedSorted = loggedSets
        .where((s) => s is Map && s['exerciseId'] == exerciseId)
        .toList()
      ..sort((a, b) => (a['setNumber'] ?? 0).compareTo(b['setNumber'] ?? 0));

    for (int i = loggedSorted.length - 1; i >= 0; i--) {
      final row = loggedSorted[i];
      final sn = row['setNumber'] ?? 0;

      if (sn < setNumber && row['weight'] != null) {
        final parsed = toDouble(row['weight']);
        if (parsed != null) return parsed;
      }
    }

    // -----------------------------------------
    // 3️⃣ אין כלום
    // -----------------------------------------
    return null;
  }
}

String exercisesCountLabel(List<dynamic>? exercises) {
  final int count = exercises == null ? 0 : exercises.length;
  return count == 1 ? '1 exercise' : '$count exercises';
}

int? getRepsFromLoggedSetsV2(
  List<dynamic> loggedSets,
  int exerciseId,
  int setNumber,
  List<dynamic> exerciseSets,
) {
  {
    int? toInt(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      if (v is double) return v.toInt();
      if (v is String) return int.tryParse(v.trim());
      return null;
    }

    // 1. This set's own logged reps
    for (final s in loggedSets) {
      if (s is Map &&
          toInt(s['exerciseId']) == exerciseId &&
          toInt(s['setNumber']) == setNumber) {
        final parsed = toInt(s['reps']);
        if (parsed != null) return parsed;
        break;
      }
    }

    // 2. Nearest previous logged set
    int? best;
    int bestSn = -1;
    for (final s in loggedSets) {
      if (s is! Map || toInt(s['exerciseId']) != exerciseId) continue;
      final int sn = toInt(s['setNumber']) ?? 0;
      final int? r = toInt(s['reps']);
      if (sn < setNumber && r != null && sn > bestSn) {
        best = r;
        bestSn = sn;
      }
    }
    if (best != null) return best;

    // 3. Target reps from the template
    for (final item in exerciseSets) {
      if (item is! Map) continue;
      if (toInt(item['exerciseId']) != exerciseId) continue;

      final sets = item['sets'];
      if (sets is List) {
        for (final s in sets) {
          if (s is Map && toInt(s['setNumber']) == setNumber) {
            final parsed = toInt(s['targetReps']);
            if (parsed != null) return parsed;
          }
        }
        for (final s in sets) {
          if (s is Map) {
            final parsed = toInt(s['targetReps']);
            if (parsed != null) return parsed;
          }
        }
      }
      break;
    }

    return null;
  }
}

String? aiWorkoutExercisesCountLabel(List<dynamic> aiResult) {
  {
    // Accepts the AI workout-builder response in any shape:
    // null, a parsed Map, a JSON string, or the exercises list directly.
    // Never throws - always returns a label.
    try {
      dynamic data = aiResult;

      if (data == null) return '0 exercises';

      if (data is String) {
        final s = data.trim();
        if (s.isEmpty) return '0 exercises';
        data = jsonDecode(s);
      }

      List<dynamic>? exercises;
      if (data is Map) {
        final ex = data['exercises'];
        if (ex is List) exercises = ex;
      } else if (data is List) {
        exercises = data;
      }

      final int count = exercises?.length ?? 0;
      return count == 1 ? '1 exercise' : '$count exercises';
    } catch (_) {
      return '0 exercises';
    }
  }
}

int? getRepsForSetFromLoggedSets(
  List<dynamic>? loggedSets,
  int exerciseId,
  int setNumber,
) {
  {
    // Returns this set's reps from loggedSets (null if not logged yet).
    // String/int-safe id matching, never throws.
    try {
      if (loggedSets == null || exerciseId == null || setNumber == null) {
        return null;
      }
      int? toInt(dynamic v) {
        if (v == null) return null;
        if (v is int) return v;
        if (v is num) return v.toInt();
        return int.tryParse(v.toString().trim());
      }

      for (final s in loggedSets) {
        if (s is! Map) continue;
        if (toInt(s['exerciseId']) != exerciseId) continue;
        if (toInt(s['setNumber']) != setNumber) continue;
        return toInt(s['reps']);
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}

double? getWeightForSetFromLoggedSets(
  List<dynamic>? loggedSets,
  int exerciseId,
  int setNumber,
) {
  {
    // Returns this set's weight from loggedSets (null if none).
    // String/int-safe id matching, never throws.
    try {
      if (loggedSets == null || exerciseId == null || setNumber == null) {
        return null;
      }
      int? toInt(dynamic v) {
        if (v == null) return null;
        if (v is int) return v;
        if (v is num) return v.toInt();
        return int.tryParse(v.toString().trim());
      }

      double? toDouble(dynamic v) {
        if (v == null) return null;
        if (v is num) return v.toDouble();
        return double.tryParse(v.toString().trim());
      }

      for (final s in loggedSets) {
        if (s is! Map) continue;
        if (toInt(s['exerciseId']) != exerciseId) continue;
        if (toInt(s['setNumber']) != setNumber) continue;
        return toDouble(s['weight']);
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}

bool hasAnalysisToShow(
  List<dynamic> analysisList,
  int exerciseId,
  int setNumber,
) {
  {
    // true if THIS set (exerciseId + setNumber) is being analyzed OR has a
    // finished analysis. Other sets are ignored.
    int? toInt(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse(v.toString().trim());
    }

    bool truthy(dynamic v) {
      if (v is bool) return v;
      if (v is num) return v != 0;
      return v?.toString().toLowerCase() == 'true';
    }

    try {
      if (analysisList == null || exerciseId == null || setNumber == null) {
        return false;
      }
      for (final ex in analysisList) {
        if (ex is! Map) continue;
        if (toInt(ex['exerciseId'] ?? ex['exercise_id']) != exerciseId) {
          continue;
        }
        final sets = ex['sets'];
        if (sets is! List) continue;
        for (final s in sets) {
          if (s is! Map) continue;
          if (toInt(s['setNumber']) != setNumber) continue;
          if (truthy(s['isProcessing'])) return true;
          if (truthy(s['analysisDone']) && s['analysis'] is Map) return true;
          return false; // found the set, nothing to show
        }
      }
      return false;
    } catch (_) {
      return false;
    }
  }
}

String greetingText() {
  {
    final h = DateTime.now().hour;
    if (h < 5) return 'Good evening';
    if (h < 12) return 'Good morning';
    if (h < 18) return 'Good afternoon';
    return 'Good evening';
  }
}

bool isSetTechniquePerfect(
  List<dynamic> analysisList,
  int setNumber,
  int exerciseId,
) {
  {
    try {
      for (final exercise in analysisList) {
        if (exercise is! Map) continue;
        if (exercise['exerciseId'] != exerciseId) continue;

        final sets = exercise['sets'];
        if (sets is! List) continue;

        for (final s in sets) {
          if (s is! Map) continue;
          if (s['setNumber'] != setNumber) continue;

          final analysis = s['analysis'];
          if (analysis is! Map) return false;

          final data =
              analysis['result'] is Map ? analysis['result'] as Map : analysis;

          final raw = data['technique_score'];
          double? score;
          if (raw is num) score = raw.toDouble();
          if (raw is String) score = double.tryParse(raw);
          if (score == null) return false;

          // Perfect only at a true 10 — no rounding (9.5 is NOT perfect).
          return score >= 9.95;
        }
      }
    } catch (e) {
      print("isSetTechniquePerfect error: $e");
    }

    return false;
  }
}
