import 'package:flutter/material.dart'
    show ChangeNotifier, Color, Colors, VoidCallback;
import '/backend/schema/structs/index.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:csv/csv.dart';
import 'package:synchronized/synchronized.dart';
import 'flutter_flow/flutter_flow_util.dart';

class FFAppState extends ChangeNotifier {
  static FFAppState _instance = FFAppState._internal();

  factory FFAppState() {
    return _instance;
  }

  FFAppState._internal();

  static void reset() {
    _instance = FFAppState._internal();
  }

  Future initializePersistedState() async {
    secureStorage = FlutterSecureStorage();
    await _safeInitAsync(() async {
      _isKg = await secureStorage.getBool('ff_isKg') ?? _isKg;
    });
    await _safeInitAsync(() async {
      if (await secureStorage.read(key: 'ff_user') != null) {
        try {
          _user = jsonDecode(await secureStorage.getString('ff_user') ?? '');
        } catch (e) {
          print("Can't decode persisted json. Error: $e.");
        }
      }
    });
    await _safeInitAsync(() async {
      _workout = await secureStorage.getBool('ff_workout') ?? _workout;
    });
    await _safeInitAsync(() async {
      _exercisesets =
          (await secureStorage.getStringList('ff_exercisesets'))?.map((x) {
                try {
                  return jsonDecode(x);
                } catch (e) {
                  print("Can't decode persisted json. Error: $e.");
                  return {};
                }
              }).toList() ??
              _exercisesets;
    });
    await _safeInitAsync(() async {
      if (await secureStorage.read(key: 'ff_activeWorkoutDet') != null) {
        try {
          _activeWorkoutDet = jsonDecode(
              await secureStorage.getString('ff_activeWorkoutDet') ?? '');
        } catch (e) {
          print("Can't decode persisted json. Error: $e.");
        }
      }
    });
    await _safeInitAsync(() async {
      _initialLogin =
          await secureStorage.getBool('ff_initialLogin') ?? _initialLogin;
    });
    await _safeInitAsync(() async {
      _loggedSets =
          (await secureStorage.getStringList('ff_loggedSets'))?.map((x) {
                try {
                  return jsonDecode(x);
                } catch (e) {
                  print("Can't decode persisted json. Error: $e.");
                  return {};
                }
              }).toList() ??
              _loggedSets;
    });
    await _safeInitAsync(() async {
      if (await secureStorage.read(key: 'ff_restTimers') != null) {
        try {
          _restTimers =
              jsonDecode(await secureStorage.getString('ff_restTimers') ?? '');
        } catch (e) {
          print("Can't decode persisted json. Error: $e.");
        }
      }
    });
    await _safeInitAsync(() async {
      _warmupSets =
          (await secureStorage.getStringList('ff_warmupSets'))?.map((x) {
                try {
                  return jsonDecode(x);
                } catch (e) {
                  print("Can't decode persisted json. Error: $e.");
                  return {};
                }
              }).toList() ??
              _warmupSets;
    });
    await _safeInitAsync(() async {
      _sound = await secureStorage.getBool('ff_sound') ?? _sound;
    });
    await _safeInitAsync(() async {
      _heightIsCm = await secureStorage.getBool('ff_heightIsCm') ?? _heightIsCm;
    });
    await _safeInitAsync(() async {
      _bodyWeightIsKg =
          await secureStorage.getBool('ff_bodyWeightIsKg') ?? _bodyWeightIsKg;
    });
    await _safeInitAsync(() async {
      _notifacations =
          await secureStorage.getBool('ff_notifacations') ?? _notifacations;
    });
    await _safeInitAsync(() async {
      _workoutAnalysisState =
          (await secureStorage.getStringList('ff_workoutAnalysisState'))
                  ?.map((x) {
                try {
                  return jsonDecode(x);
                } catch (e) {
                  print("Can't decode persisted json. Error: $e.");
                  return {};
                }
              }).toList() ??
              _workoutAnalysisState;
    });
    await _safeInitAsync(() async {
      _completedExercises =
          (await secureStorage.getStringList('ff_completedExercises'))
                  ?.map((x) {
                try {
                  return jsonDecode(x);
                } catch (e) {
                  print("Can't decode persisted json. Error: $e.");
                  return {};
                }
              }).toList() ??
              _completedExercises;
    });
    await _safeInitAsync(() async {
      _activeWorkoutStartTime =
          await secureStorage.read(key: 'ff_activeWorkoutStartTime') != null
              ? DateTime.fromMillisecondsSinceEpoch(
                  (await secureStorage.getInt('ff_activeWorkoutStartTime'))!)
              : _activeWorkoutStartTime;
    });
    await _safeInitAsync(() async {
      _profile = await secureStorage.getString('ff_profile') ?? _profile;
    });
    await _safeInitAsync(() async {
      _analysisCount =
          await secureStorage.getInt('ff_analysisCount') ?? _analysisCount;
    });
    await _safeInitAsync(() async {
      _analysisCountMonth =
          await secureStorage.getString('ff_analysisCountMonth') ??
              _analysisCountMonth;
    });
    await _safeInitAsync(() async {
      _signedApple =
          await secureStorage.getBool('ff_signedApple') ?? _signedApple;
    });
    await _safeInitAsync(() async {
      _restore = await secureStorage.getBool('ff_restore') ?? _restore;
    });
    await _safeInitAsync(() async {
      _generationDates =
          await secureStorage.getStringList('ff_generationDates') ??
              _generationDates;
    });
  }

  void update(VoidCallback callback) {
    callback();
    notifyListeners();
  }

  late FlutterSecureStorage secureStorage;

  bool _Searchactive = false;
  bool get Searchactive => _Searchactive;
  set Searchactive(bool value) {
    _Searchactive = value;
  }

  List<SetsStruct> _listofsets = [
    SetsStruct.fromSerializableMap(
        jsonDecode('{\"setnumber\":\"0\",\"weight\":\"0\",\"deci\":\"true\"}'))
  ];
  List<SetsStruct> get listofsets => _listofsets;
  set listofsets(List<SetsStruct> value) {
    _listofsets = value;
  }

  void addToListofsets(SetsStruct value) {
    listofsets.add(value);
  }

  void removeFromListofsets(SetsStruct value) {
    listofsets.remove(value);
  }

  void removeAtIndexFromListofsets(int index) {
    listofsets.removeAt(index);
  }

  void updateListofsetsAtIndex(
    int index,
    SetsStruct Function(SetsStruct) updateFn,
  ) {
    listofsets[index] = updateFn(_listofsets[index]);
  }

  void insertAtIndexInListofsets(int index, SetsStruct value) {
    listofsets.insert(index, value);
  }

  ListofsetsStruct _newlist = ListofsetsStruct.fromSerializableMap(jsonDecode(
      '{\"exerciseid\":\"none\",\"set\":\"[\\\"{\\\\\\\"setnumber\\\\\\\":\\\\\\\"0\\\\\\\",\\\\\\\"weight\\\\\\\":\\\\\\\"0\\\\\\\",\\\\\\\"deci\\\\\\\":\\\\\\\"true\\\\\\\"}\\\"]\"}'));
  ListofsetsStruct get newlist => _newlist;
  set newlist(ListofsetsStruct value) {
    _newlist = value;
  }

  void updateNewlistStruct(Function(ListofsetsStruct) updateFn) {
    updateFn(_newlist);
  }

  int _reps = 0;
  int get reps => _reps;
  set reps(int value) {
    _reps = value;
  }

  int _weight = 0;
  int get weight => _weight;
  set weight(int value) {
    _weight = value;
  }

  bool _check = false;
  bool get check => _check;
  set check(bool value) {
    _check = value;
  }

  bool _isKg = true;
  bool get isKg => _isKg;
  set isKg(bool value) {
    _isKg = value;
    secureStorage.setBool('ff_isKg', value);
  }

  void deleteIsKg() {
    secureStorage.delete(key: 'ff_isKg');
  }

  dynamic _user;
  dynamic get user => _user;
  set user(dynamic value) {
    _user = value;
    secureStorage.setString('ff_user', jsonEncode(value));
  }

  void deleteUser() {
    secureStorage.delete(key: 'ff_user');
  }

  bool _workout = false;
  bool get workout => _workout;
  set workout(bool value) {
    _workout = value;
    secureStorage.setBool('ff_workout', value);
  }

  void deleteWorkout() {
    secureStorage.delete(key: 'ff_workout');
  }

  List<dynamic> _exercisesets = [];
  List<dynamic> get exercisesets => _exercisesets;
  set exercisesets(List<dynamic> value) {
    _exercisesets = value;
    secureStorage.setStringList(
        'ff_exercisesets', value.map((x) => jsonEncode(x)).toList());
  }

  void deleteExercisesets() {
    secureStorage.delete(key: 'ff_exercisesets');
  }

  void addToExercisesets(dynamic value) {
    exercisesets.add(value);
    secureStorage.setStringList(
        'ff_exercisesets', _exercisesets.map((x) => jsonEncode(x)).toList());
  }

  void removeFromExercisesets(dynamic value) {
    exercisesets.remove(value);
    secureStorage.setStringList(
        'ff_exercisesets', _exercisesets.map((x) => jsonEncode(x)).toList());
  }

  void removeAtIndexFromExercisesets(int index) {
    exercisesets.removeAt(index);
    secureStorage.setStringList(
        'ff_exercisesets', _exercisesets.map((x) => jsonEncode(x)).toList());
  }

  void updateExercisesetsAtIndex(
    int index,
    dynamic Function(dynamic) updateFn,
  ) {
    exercisesets[index] = updateFn(_exercisesets[index]);
    secureStorage.setStringList(
        'ff_exercisesets', _exercisesets.map((x) => jsonEncode(x)).toList());
  }

  void insertAtIndexInExercisesets(int index, dynamic value) {
    exercisesets.insert(index, value);
    secureStorage.setStringList(
        'ff_exercisesets', _exercisesets.map((x) => jsonEncode(x)).toList());
  }

  dynamic _activeWorkoutDet;
  dynamic get activeWorkoutDet => _activeWorkoutDet;
  set activeWorkoutDet(dynamic value) {
    _activeWorkoutDet = value;
    secureStorage.setString('ff_activeWorkoutDet', jsonEncode(value));
  }

  void deleteActiveWorkoutDet() {
    secureStorage.delete(key: 'ff_activeWorkoutDet');
  }

  bool _hasConnection = true;
  bool get hasConnection => _hasConnection;
  set hasConnection(bool value) {
    _hasConnection = value;
  }

  bool _shouldSync = false;
  bool get shouldSync => _shouldSync;
  set shouldSync(bool value) {
    _shouldSync = value;
  }

  bool _initialLogin = true;
  bool get initialLogin => _initialLogin;
  set initialLogin(bool value) {
    _initialLogin = value;
    secureStorage.setBool('ff_initialLogin', value);
  }

  void deleteInitialLogin() {
    secureStorage.delete(key: 'ff_initialLogin');
  }

  List<dynamic> _loggedSets = [];
  List<dynamic> get loggedSets => _loggedSets;
  set loggedSets(List<dynamic> value) {
    _loggedSets = value;
    secureStorage.setStringList(
        'ff_loggedSets', value.map((x) => jsonEncode(x)).toList());
  }

  void deleteLoggedSets() {
    secureStorage.delete(key: 'ff_loggedSets');
  }

  void addToLoggedSets(dynamic value) {
    loggedSets.add(value);
    secureStorage.setStringList(
        'ff_loggedSets', _loggedSets.map((x) => jsonEncode(x)).toList());
  }

  void removeFromLoggedSets(dynamic value) {
    loggedSets.remove(value);
    secureStorage.setStringList(
        'ff_loggedSets', _loggedSets.map((x) => jsonEncode(x)).toList());
  }

  void removeAtIndexFromLoggedSets(int index) {
    loggedSets.removeAt(index);
    secureStorage.setStringList(
        'ff_loggedSets', _loggedSets.map((x) => jsonEncode(x)).toList());
  }

  void updateLoggedSetsAtIndex(
    int index,
    dynamic Function(dynamic) updateFn,
  ) {
    loggedSets[index] = updateFn(_loggedSets[index]);
    secureStorage.setStringList(
        'ff_loggedSets', _loggedSets.map((x) => jsonEncode(x)).toList());
  }

  void insertAtIndexInLoggedSets(int index, dynamic value) {
    loggedSets.insert(index, value);
    secureStorage.setStringList(
        'ff_loggedSets', _loggedSets.map((x) => jsonEncode(x)).toList());
  }

  dynamic _restTimers;
  dynamic get restTimers => _restTimers;
  set restTimers(dynamic value) {
    _restTimers = value;
    secureStorage.setString('ff_restTimers', jsonEncode(value));
  }

  void deleteRestTimers() {
    secureStorage.delete(key: 'ff_restTimers');
  }

  List<dynamic> _timerMode = [];
  List<dynamic> get timerMode => _timerMode;
  set timerMode(List<dynamic> value) {
    _timerMode = value;
  }

  void addToTimerMode(dynamic value) {
    timerMode.add(value);
  }

  void removeFromTimerMode(dynamic value) {
    timerMode.remove(value);
  }

  void removeAtIndexFromTimerMode(int index) {
    timerMode.removeAt(index);
  }

  void updateTimerModeAtIndex(
    int index,
    dynamic Function(dynamic) updateFn,
  ) {
    timerMode[index] = updateFn(_timerMode[index]);
  }

  void insertAtIndexInTimerMode(int index, dynamic value) {
    timerMode.insert(index, value);
  }

  List<dynamic> _dropSets = [];
  List<dynamic> get dropSets => _dropSets;
  set dropSets(List<dynamic> value) {
    _dropSets = value;
  }

  void addToDropSets(dynamic value) {
    dropSets.add(value);
  }

  void removeFromDropSets(dynamic value) {
    dropSets.remove(value);
  }

  void removeAtIndexFromDropSets(int index) {
    dropSets.removeAt(index);
  }

  void updateDropSetsAtIndex(
    int index,
    dynamic Function(dynamic) updateFn,
  ) {
    dropSets[index] = updateFn(_dropSets[index]);
  }

  void insertAtIndexInDropSets(int index, dynamic value) {
    dropSets.insert(index, value);
  }

  List<dynamic> _warmupSets = [];
  List<dynamic> get warmupSets => _warmupSets;
  set warmupSets(List<dynamic> value) {
    _warmupSets = value;
    secureStorage.setStringList(
        'ff_warmupSets', value.map((x) => jsonEncode(x)).toList());
  }

  void deleteWarmupSets() {
    secureStorage.delete(key: 'ff_warmupSets');
  }

  void addToWarmupSets(dynamic value) {
    warmupSets.add(value);
    secureStorage.setStringList(
        'ff_warmupSets', _warmupSets.map((x) => jsonEncode(x)).toList());
  }

  void removeFromWarmupSets(dynamic value) {
    warmupSets.remove(value);
    secureStorage.setStringList(
        'ff_warmupSets', _warmupSets.map((x) => jsonEncode(x)).toList());
  }

  void removeAtIndexFromWarmupSets(int index) {
    warmupSets.removeAt(index);
    secureStorage.setStringList(
        'ff_warmupSets', _warmupSets.map((x) => jsonEncode(x)).toList());
  }

  void updateWarmupSetsAtIndex(
    int index,
    dynamic Function(dynamic) updateFn,
  ) {
    warmupSets[index] = updateFn(_warmupSets[index]);
    secureStorage.setStringList(
        'ff_warmupSets', _warmupSets.map((x) => jsonEncode(x)).toList());
  }

  void insertAtIndexInWarmupSets(int index, dynamic value) {
    warmupSets.insert(index, value);
    secureStorage.setStringList(
        'ff_warmupSets', _warmupSets.map((x) => jsonEncode(x)).toList());
  }

  String _activeWorkoutTime = '';
  String get activeWorkoutTime => _activeWorkoutTime;
  set activeWorkoutTime(String value) {
    _activeWorkoutTime = value;
  }

  bool _down = true;
  bool get down => _down;
  set down(bool value) {
    _down = value;
  }

  bool _vibration = true;
  bool get vibration => _vibration;
  set vibration(bool value) {
    _vibration = value;
  }

  bool _sound = true;
  bool get sound => _sound;
  set sound(bool value) {
    _sound = value;
    secureStorage.setBool('ff_sound', value);
  }

  void deleteSound() {
    secureStorage.delete(key: 'ff_sound');
  }

  bool _isTimerRunning = false;
  bool get isTimerRunning => _isTimerRunning;
  set isTimerRunning(bool value) {
    _isTimerRunning = value;
  }

  int _workoutSeconds = 0;
  int get workoutSeconds => _workoutSeconds;
  set workoutSeconds(int value) {
    _workoutSeconds = value;
  }

  String _PowerSyncUrl =
      'https://68e7c9be351a891dd218d2f4.powersync.journeyapps.com';
  String get PowerSyncUrl => _PowerSyncUrl;
  set PowerSyncUrl(String value) {
    _PowerSyncUrl = value;
  }

  List<dynamic> _exerciseSetsCretion = [];
  List<dynamic> get exerciseSetsCretion => _exerciseSetsCretion;
  set exerciseSetsCretion(List<dynamic> value) {
    _exerciseSetsCretion = value;
  }

  void addToExerciseSetsCretion(dynamic value) {
    exerciseSetsCretion.add(value);
  }

  void removeFromExerciseSetsCretion(dynamic value) {
    exerciseSetsCretion.remove(value);
  }

  void removeAtIndexFromExerciseSetsCretion(int index) {
    exerciseSetsCretion.removeAt(index);
  }

  void updateExerciseSetsCretionAtIndex(
    int index,
    dynamic Function(dynamic) updateFn,
  ) {
    exerciseSetsCretion[index] = updateFn(_exerciseSetsCretion[index]);
  }

  void insertAtIndexInExerciseSetsCretion(int index, dynamic value) {
    exerciseSetsCretion.insert(index, value);
  }

  List<dynamic> _loggedSetsCreation = [];
  List<dynamic> get loggedSetsCreation => _loggedSetsCreation;
  set loggedSetsCreation(List<dynamic> value) {
    _loggedSetsCreation = value;
  }

  void addToLoggedSetsCreation(dynamic value) {
    loggedSetsCreation.add(value);
  }

  void removeFromLoggedSetsCreation(dynamic value) {
    loggedSetsCreation.remove(value);
  }

  void removeAtIndexFromLoggedSetsCreation(int index) {
    loggedSetsCreation.removeAt(index);
  }

  void updateLoggedSetsCreationAtIndex(
    int index,
    dynamic Function(dynamic) updateFn,
  ) {
    loggedSetsCreation[index] = updateFn(_loggedSetsCreation[index]);
  }

  void insertAtIndexInLoggedSetsCreation(int index, dynamic value) {
    loggedSetsCreation.insert(index, value);
  }

  List<dynamic> _dropSetsCreation = [];
  List<dynamic> get dropSetsCreation => _dropSetsCreation;
  set dropSetsCreation(List<dynamic> value) {
    _dropSetsCreation = value;
  }

  void addToDropSetsCreation(dynamic value) {
    dropSetsCreation.add(value);
  }

  void removeFromDropSetsCreation(dynamic value) {
    dropSetsCreation.remove(value);
  }

  void removeAtIndexFromDropSetsCreation(int index) {
    dropSetsCreation.removeAt(index);
  }

  void updateDropSetsCreationAtIndex(
    int index,
    dynamic Function(dynamic) updateFn,
  ) {
    dropSetsCreation[index] = updateFn(_dropSetsCreation[index]);
  }

  void insertAtIndexInDropSetsCreation(int index, dynamic value) {
    dropSetsCreation.insert(index, value);
  }

  dynamic _restTimerCreation;
  dynamic get restTimerCreation => _restTimerCreation;
  set restTimerCreation(dynamic value) {
    _restTimerCreation = value;
  }

  bool _heightIsCm = true;
  bool get heightIsCm => _heightIsCm;
  set heightIsCm(bool value) {
    _heightIsCm = value;
    secureStorage.setBool('ff_heightIsCm', value);
  }

  void deleteHeightIsCm() {
    secureStorage.delete(key: 'ff_heightIsCm');
  }

  bool _bodyWeightIsKg = true;
  bool get bodyWeightIsKg => _bodyWeightIsKg;
  set bodyWeightIsKg(bool value) {
    _bodyWeightIsKg = value;
    secureStorage.setBool('ff_bodyWeightIsKg', value);
  }

  void deleteBodyWeightIsKg() {
    secureStorage.delete(key: 'ff_bodyWeightIsKg');
  }

  String _setErrorMsg = '';
  String get setErrorMsg => _setErrorMsg;
  set setErrorMsg(String value) {
    _setErrorMsg = value;
  }

  bool _setError = false;
  bool get setError => _setError;
  set setError(bool value) {
    _setError = value;
  }

  List<dynamic> _WorkoutSchedule = [];
  List<dynamic> get WorkoutSchedule => _WorkoutSchedule;
  set WorkoutSchedule(List<dynamic> value) {
    _WorkoutSchedule = value;
  }

  void addToWorkoutSchedule(dynamic value) {
    WorkoutSchedule.add(value);
  }

  void removeFromWorkoutSchedule(dynamic value) {
    WorkoutSchedule.remove(value);
  }

  void removeAtIndexFromWorkoutSchedule(int index) {
    WorkoutSchedule.removeAt(index);
  }

  void updateWorkoutScheduleAtIndex(
    int index,
    dynamic Function(dynamic) updateFn,
  ) {
    WorkoutSchedule[index] = updateFn(_WorkoutSchedule[index]);
  }

  void insertAtIndexInWorkoutSchedule(int index, dynamic value) {
    WorkoutSchedule.insert(index, value);
  }

  bool _isPremium = false;
  bool get isPremium => _isPremium;
  set isPremium(bool value) {
    _isPremium = value;
  }

  bool _notifacations = false;
  bool get notifacations => _notifacations;
  set notifacations(bool value) {
    _notifacations = value;
    secureStorage.setBool('ff_notifacations', value);
  }

  void deleteNotifacations() {
    secureStorage.delete(key: 'ff_notifacations');
  }

  List<dynamic> _workoutAnalysisState = [];
  List<dynamic> get workoutAnalysisState => _workoutAnalysisState;
  set workoutAnalysisState(List<dynamic> value) {
    _workoutAnalysisState = value;
    secureStorage.setStringList(
        'ff_workoutAnalysisState', value.map((x) => jsonEncode(x)).toList());
  }

  void deleteWorkoutAnalysisState() {
    secureStorage.delete(key: 'ff_workoutAnalysisState');
  }

  void addToWorkoutAnalysisState(dynamic value) {
    workoutAnalysisState.add(value);
    secureStorage.setStringList('ff_workoutAnalysisState',
        _workoutAnalysisState.map((x) => jsonEncode(x)).toList());
  }

  void removeFromWorkoutAnalysisState(dynamic value) {
    workoutAnalysisState.remove(value);
    secureStorage.setStringList('ff_workoutAnalysisState',
        _workoutAnalysisState.map((x) => jsonEncode(x)).toList());
  }

  void removeAtIndexFromWorkoutAnalysisState(int index) {
    workoutAnalysisState.removeAt(index);
    secureStorage.setStringList('ff_workoutAnalysisState',
        _workoutAnalysisState.map((x) => jsonEncode(x)).toList());
  }

  void updateWorkoutAnalysisStateAtIndex(
    int index,
    dynamic Function(dynamic) updateFn,
  ) {
    workoutAnalysisState[index] = updateFn(_workoutAnalysisState[index]);
    secureStorage.setStringList('ff_workoutAnalysisState',
        _workoutAnalysisState.map((x) => jsonEncode(x)).toList());
  }

  void insertAtIndexInWorkoutAnalysisState(int index, dynamic value) {
    workoutAnalysisState.insert(index, value);
    secureStorage.setStringList('ff_workoutAnalysisState',
        _workoutAnalysisState.map((x) => jsonEncode(x)).toList());
  }

  List<dynamic> _completedExercises = [];
  List<dynamic> get completedExercises => _completedExercises;
  set completedExercises(List<dynamic> value) {
    _completedExercises = value;
    secureStorage.setStringList(
        'ff_completedExercises', value.map((x) => jsonEncode(x)).toList());
  }

  void deleteCompletedExercises() {
    secureStorage.delete(key: 'ff_completedExercises');
  }

  void addToCompletedExercises(dynamic value) {
    completedExercises.add(value);
    secureStorage.setStringList('ff_completedExercises',
        _completedExercises.map((x) => jsonEncode(x)).toList());
  }

  void removeFromCompletedExercises(dynamic value) {
    completedExercises.remove(value);
    secureStorage.setStringList('ff_completedExercises',
        _completedExercises.map((x) => jsonEncode(x)).toList());
  }

  void removeAtIndexFromCompletedExercises(int index) {
    completedExercises.removeAt(index);
    secureStorage.setStringList('ff_completedExercises',
        _completedExercises.map((x) => jsonEncode(x)).toList());
  }

  void updateCompletedExercisesAtIndex(
    int index,
    dynamic Function(dynamic) updateFn,
  ) {
    completedExercises[index] = updateFn(_completedExercises[index]);
    secureStorage.setStringList('ff_completedExercises',
        _completedExercises.map((x) => jsonEncode(x)).toList());
  }

  void insertAtIndexInCompletedExercises(int index, dynamic value) {
    completedExercises.insert(index, value);
    secureStorage.setStringList('ff_completedExercises',
        _completedExercises.map((x) => jsonEncode(x)).toList());
  }

  DateTime? _activeWorkoutStartTime;
  DateTime? get activeWorkoutStartTime => _activeWorkoutStartTime;
  set activeWorkoutStartTime(DateTime? value) {
    _activeWorkoutStartTime = value;
    value != null
        ? secureStorage.setInt(
            'ff_activeWorkoutStartTime', value.millisecondsSinceEpoch)
        : secureStorage.remove('ff_activeWorkoutStartTime');
  }

  void deleteActiveWorkoutStartTime() {
    secureStorage.delete(key: 'ff_activeWorkoutStartTime');
  }

  String _profile = '';
  String get profile => _profile;
  set profile(String value) {
    _profile = value;
    secureStorage.setString('ff_profile', value);
  }

  void deleteProfile() {
    secureStorage.delete(key: 'ff_profile');
  }

  int _analysisCount = 0;
  int get analysisCount => _analysisCount;
  set analysisCount(int value) {
    _analysisCount = value;
    secureStorage.setInt('ff_analysisCount', value);
  }

  void deleteAnalysisCount() {
    secureStorage.delete(key: 'ff_analysisCount');
  }

  String _analysisCountMonth = '';
  String get analysisCountMonth => _analysisCountMonth;
  set analysisCountMonth(String value) {
    _analysisCountMonth = value;
    secureStorage.setString('ff_analysisCountMonth', value);
  }

  void deleteAnalysisCountMonth() {
    secureStorage.delete(key: 'ff_analysisCountMonth');
  }

  List<dynamic> _warmUpCreation = [];
  List<dynamic> get warmUpCreation => _warmUpCreation;
  set warmUpCreation(List<dynamic> value) {
    _warmUpCreation = value;
  }

  void addToWarmUpCreation(dynamic value) {
    warmUpCreation.add(value);
  }

  void removeFromWarmUpCreation(dynamic value) {
    warmUpCreation.remove(value);
  }

  void removeAtIndexFromWarmUpCreation(int index) {
    warmUpCreation.removeAt(index);
  }

  void updateWarmUpCreationAtIndex(
    int index,
    dynamic Function(dynamic) updateFn,
  ) {
    warmUpCreation[index] = updateFn(_warmUpCreation[index]);
  }

  void insertAtIndexInWarmUpCreation(int index, dynamic value) {
    warmUpCreation.insert(index, value);
  }

  bool _signedApple = false;
  bool get signedApple => _signedApple;
  set signedApple(bool value) {
    _signedApple = value;
    secureStorage.setBool('ff_signedApple', value);
  }

  void deleteSignedApple() {
    secureStorage.delete(key: 'ff_signedApple');
  }

  bool _restore = true;
  bool get restore => _restore;
  set restore(bool value) {
    _restore = value;
    secureStorage.setBool('ff_restore', value);
  }

  void deleteRestore() {
    secureStorage.delete(key: 'ff_restore');
  }

  List<String> _generationDates = [];
  List<String> get generationDates => _generationDates;
  set generationDates(List<String> value) {
    _generationDates = value;
    secureStorage.setStringList('ff_generationDates', value);
  }

  void deleteGenerationDates() {
    secureStorage.delete(key: 'ff_generationDates');
  }

  void addToGenerationDates(String value) {
    generationDates.add(value);
    secureStorage.setStringList('ff_generationDates', _generationDates);
  }

  void removeFromGenerationDates(String value) {
    generationDates.remove(value);
    secureStorage.setStringList('ff_generationDates', _generationDates);
  }

  void removeAtIndexFromGenerationDates(int index) {
    generationDates.removeAt(index);
    secureStorage.setStringList('ff_generationDates', _generationDates);
  }

  void updateGenerationDatesAtIndex(
    int index,
    String Function(String) updateFn,
  ) {
    generationDates[index] = updateFn(_generationDates[index]);
    secureStorage.setStringList('ff_generationDates', _generationDates);
  }

  void insertAtIndexInGenerationDates(int index, String value) {
    generationDates.insert(index, value);
    secureStorage.setStringList('ff_generationDates', _generationDates);
  }
}

void _safeInit(Function() initializeField) {
  try {
    initializeField();
  } catch (_) {}
}

Future _safeInitAsync(Function() initializeField) async {
  try {
    await initializeField();
  } catch (_) {}
}

extension FlutterSecureStorageExtensions on FlutterSecureStorage {
  static final _lock = Lock();

  Future<void> writeSync({required String key, String? value}) async =>
      await _lock.synchronized(() async {
        await write(key: key, value: value);
      });

  void remove(String key) => delete(key: key);

  Future<String?> getString(String key) async => await read(key: key);
  Future<void> setString(String key, String value) async =>
      await writeSync(key: key, value: value);

  Future<bool?> getBool(String key) async {
    final value = await read(key: key);
    return value == null ? null : value == 'true';
  }

  Future<void> setBool(String key, bool value) async =>
      await writeSync(key: key, value: value.toString());

  Future<int?> getInt(String key) async =>
      int.tryParse(await read(key: key) ?? '');
  Future<void> setInt(String key, int value) async =>
      await writeSync(key: key, value: value.toString());

  Future<double?> getDouble(String key) async =>
      double.tryParse(await read(key: key) ?? '');
  Future<void> setDouble(String key, double value) async =>
      await writeSync(key: key, value: value.toString());

  Future<List<String>?> getStringList(String key) async =>
      await read(key: key).then((result) {
        if (result == null || result.isEmpty) {
          return null;
        }
        // Lists are stored as JSON. Older versions stored CSV, which never
        // starts with `["` because CSV quotes any field containing a quote.
        if (result == '[]' || result.startsWith('["')) {
          return (jsonDecode(result) as List).map((e) => e.toString()).toList();
        }
        return const CsvToListConverter(shouldParseNumbers: false)
            .convert(result)
            .first
            .map((e) => e.toString())
            .toList();
      });
  Future<void> setStringList(String key, List<String> value) async =>
      await writeSync(key: key, value: jsonEncode(value));
}
