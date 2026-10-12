import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '/backend/schema/structs/index.dart';

import '/backend/sqlite/sqlite_manager.dart';
import '/auth/base_auth_user_provider.dart';

import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';

import '/index.dart';

export 'package:go_router/go_router.dart';
export 'serialization_util.dart';

const kTransitionInfoKey = '__transition_info__';

GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

class AppStateNotifier extends ChangeNotifier {
  AppStateNotifier._();

  static AppStateNotifier? _instance;
  static AppStateNotifier get instance => _instance ??= AppStateNotifier._();

  BaseAuthUser? initialUser;
  BaseAuthUser? user;
  bool showSplashImage = true;
  String? _redirectLocation;

  /// Determines whether the app will refresh and build again when a sign
  /// in or sign out happens. This is useful when the app is launched or
  /// on an unexpected logout. However, this must be turned off when we
  /// intend to sign in/out and then navigate or perform any actions after.
  /// Otherwise, this will trigger a refresh and interrupt the action(s).
  bool notifyOnAuthChange = true;

  bool get loading => user == null || showSplashImage;
  bool get loggedIn => user?.loggedIn ?? false;
  bool get initiallyLoggedIn => initialUser?.loggedIn ?? false;
  bool get shouldRedirect => loggedIn && _redirectLocation != null;

  String getRedirectLocation() => _redirectLocation!;
  bool hasRedirect() => _redirectLocation != null;
  void setRedirectLocationIfUnset(String loc) => _redirectLocation ??= loc;
  void clearRedirectLocation() => _redirectLocation = null;

  /// Mark as not needing to notify on a sign in / out when we intend
  /// to perform subsequent actions (such as navigation) afterwards.
  void updateNotifyOnAuthChange(bool notify) => notifyOnAuthChange = notify;

  void update(BaseAuthUser newUser) {
    final shouldUpdate =
        user?.uid == null || newUser.uid == null || user?.uid != newUser.uid;
    initialUser ??= newUser;
    user = newUser;
    // Refresh the app on auth change unless explicitly marked otherwise.
    // No need to update unless the user has changed.
    if (notifyOnAuthChange && shouldUpdate) {
      notifyListeners();
    }
    // Once again mark the notifier as needing to update on auth change
    // (in order to catch sign in / out events).
    updateNotifyOnAuthChange(true);
  }

  void stopShowingSplashImage() {
    showSplashImage = false;
    notifyListeners();
  }
}

GoRouter createRouter(AppStateNotifier appStateNotifier) => GoRouter(
      initialLocation: '/',
      debugLogDiagnostics: true,
      refreshListenable: appStateNotifier,
      navigatorKey: appNavigatorKey,
      errorBuilder: (context, state) => appStateNotifier.loggedIn
          ? MasterPageWidget()
          : SignInWelcomePage6Widget(),
      routes: [
        FFRoute(
          name: '_initialize',
          path: '/',
          builder: (context, _) => appStateNotifier.loggedIn
              ? MasterPageWidget()
              : SignInWelcomePage6Widget(),
        ),
        FFRoute(
          name: WorkoutAfterviewWidget.routeName,
          path: WorkoutAfterviewWidget.routePath,
          builder: (context, params) => WorkoutAfterviewWidget(
            workoutLogId: params.getParam(
              'workoutLogId',
              ParamType.String,
            ),
          ),
        ),
        FFRoute(
          name: ExerciseHistoryWidget.routeName,
          path: ExerciseHistoryWidget.routePath,
          builder: (context, params) => ExerciseHistoryWidget(
            exerciseId: params.getParam(
              'exerciseId',
              ParamType.int,
            ),
            overview: params.getParam(
              'overview',
              ParamType.bool,
            ),
            analytics: params.getParam(
              'analytics',
              ParamType.bool,
            ),
          ),
        ),
        FFRoute(
          name: SettingssWidget.routeName,
          path: SettingssWidget.routePath,
          builder: (context, params) => SettingssWidget(),
        ),
        FFRoute(
          name: TemplateWorkoutWidget.routeName,
          path: TemplateWorkoutWidget.routePath,
          builder: (context, params) => TemplateWorkoutWidget(
            workoutTemplate: params.getParam<GetWorkoutTemplateRow>(
              'workoutTemplate',
              ParamType.SqliteRow,
            ),
          ),
        ),
        FFRoute(
          name: SignupInWidget.routeName,
          path: SignupInWidget.routePath,
          builder: (context, params) => SignupInWidget(),
        ),
        FFRoute(
          name: ForgotPassword02Widget.routeName,
          path: ForgotPassword02Widget.routePath,
          builder: (context, params) => ForgotPassword02Widget(),
        ),
        FFRoute(
          name: WorkoutV2Widget.routeName,
          path: WorkoutV2Widget.routePath,
          builder: (context, params) => WorkoutV2Widget(
            workoutId: params.getParam(
              'workoutId',
              ParamType.String,
            ),
          ),
        ),
        FFRoute(
          name: WorkoutComparisonWidget.routeName,
          path: WorkoutComparisonWidget.routePath,
          builder: (context, params) => WorkoutComparisonWidget(
            idA: params.getParam(
              'idA',
              ParamType.String,
            ),
            idB: params.getParam(
              'idB',
              ParamType.String,
            ),
          ),
        ),
        FFRoute(
          name: WorkoutLogEditV2Widget.routeName,
          path: WorkoutLogEditV2Widget.routePath,
          builder: (context, params) => WorkoutLogEditV2Widget(
            workoutLogId: params.getParam(
              'workoutLogId',
              ParamType.String,
            ),
          ),
        ),
        FFRoute(
          name: CompareSelectWidget.routeName,
          path: CompareSelectWidget.routePath,
          builder: (context, params) => CompareSelectWidget(
            workoutLogAId: params.getParam(
              'workoutLogAId',
              ParamType.String,
            ),
          ),
        ),
        FFRoute(
          name: AddExercisesV3Widget.routeName,
          path: AddExercisesV3Widget.routePath,
          builder: (context, params) => AddExercisesV3Widget(
            alreadySelceted: params.getParam<dynamic>(
              'alreadySelceted',
              ParamType.JSON,
              isList: true,
            ),
            workoutName: params.getParam(
              'workoutName',
              ParamType.String,
            ),
            adduserEx: params.getParam<dynamic>(
              'adduserEx',
              ParamType.JSON,
              isList: true,
            ),
            addUserEx: params.getParam(
              'addUserEx',
              ParamType.bool,
            ),
          ),
        ),
        FFRoute(
          name: CreateUserExerciseWidget.routeName,
          path: CreateUserExerciseWidget.routePath,
          builder: (context, params) => CreateUserExerciseWidget(
            alreadySelected: params.getParam<dynamic>(
              'alreadySelected',
              ParamType.JSON,
              isList: true,
            ),
            workoutName: params.getParam(
              'workoutName',
              ParamType.String,
            ),
          ),
        ),
        FFRoute(
          name: AddExercisesMidSeissionWidget.routeName,
          path: AddExercisesMidSeissionWidget.routePath,
          builder: (context, params) => AddExercisesMidSeissionWidget(
            alreadySelceted: params.getParam<dynamic>(
              'alreadySelceted',
              ParamType.JSON,
              isList: true,
            ),
            workoutId: params.getParam(
              'workoutId',
              ParamType.String,
            ),
            addUserEx: params.getParam(
              'addUserEx',
              ParamType.bool,
            ),
            userExlist: params.getParam<dynamic>(
              'userExlist',
              ParamType.JSON,
              isList: true,
            ),
          ),
        ),
        FFRoute(
          name: HelpUsWidget.routeName,
          path: HelpUsWidget.routePath,
          builder: (context, params) => HelpUsWidget(),
        ),
        FFRoute(
          name: ReportBugWidget.routeName,
          path: ReportBugWidget.routePath,
          builder: (context, params) => ReportBugWidget(),
        ),
        FFRoute(
          name: FeedbackWidget.routeName,
          path: FeedbackWidget.routePath,
          builder: (context, params) => FeedbackWidget(),
        ),
        FFRoute(
          name: EditWorkoutV2Widget.routeName,
          path: EditWorkoutV2Widget.routePath,
          builder: (context, params) => EditWorkoutV2Widget(
            alreadySelceted: params.getParam<dynamic>(
              'alreadySelceted',
              ParamType.JSON,
              isList: true,
            ),
            shouldInit: params.getParam(
              'shouldInit',
              ParamType.bool,
            ),
            workoutName: params.getParam(
              'workoutName',
              ParamType.String,
            ),
            workoutId: params.getParam(
              'workoutId',
              ParamType.String,
            ),
          ),
        ),
        FFRoute(
          name: AddExercisesForEditWidget.routeName,
          path: AddExercisesForEditWidget.routePath,
          builder: (context, params) => AddExercisesForEditWidget(
            workoutName: params.getParam(
              'workoutName',
              ParamType.String,
            ),
            workoutId: params.getParam(
              'workoutId',
              ParamType.String,
            ),
          ),
        ),
        FFRoute(
          name: AddExercisesForWorklogEditWidget.routeName,
          path: AddExercisesForWorklogEditWidget.routePath,
          builder: (context, params) => AddExercisesForWorklogEditWidget(
            alreadySelceted: params.getParam<dynamic>(
              'alreadySelceted',
              ParamType.JSON,
              isList: true,
            ),
            workoutLOgId: params.getParam(
              'workoutLOgId',
              ParamType.String,
            ),
          ),
        ),
        FFRoute(
          name: ProfEditV2Widget.routeName,
          path: ProfEditV2Widget.routePath,
          builder: (context, params) => ProfEditV2Widget(),
        ),
        FFRoute(
          name: AccountSettingsWidget.routeName,
          path: AccountSettingsWidget.routePath,
          builder: (context, params) => AccountSettingsWidget(),
        ),
        FFRoute(
          name: ReplaceExercisePageWidget.routeName,
          path: ReplaceExercisePageWidget.routePath,
          builder: (context, params) => ReplaceExercisePageWidget(
            exerciseId: params.getParam(
              'exerciseId',
              ParamType.int,
            ),
          ),
        ),
        FFRoute(
          name: ReplaceExercisePageCreationWidget.routeName,
          path: ReplaceExercisePageCreationWidget.routePath,
          builder: (context, params) => ReplaceExercisePageCreationWidget(
            exerciseId: params.getParam(
              'exerciseId',
              ParamType.int,
            ),
          ),
        ),
        FFRoute(
          name: CreateUserExerciseMidSessionWidget.routeName,
          path: CreateUserExerciseMidSessionWidget.routePath,
          builder: (context, params) => CreateUserExerciseMidSessionWidget(
            alreadySelected: params.getParam<dynamic>(
              'alreadySelected',
              ParamType.JSON,
              isList: true,
            ),
            workoutName: params.getParam(
              'workoutName',
              ParamType.String,
            ),
          ),
        ),
        FFRoute(
          name: RoutineBuilderWidget.routeName,
          path: RoutineBuilderWidget.routePath,
          builder: (context, params) => RoutineBuilderWidget(
            workoutsIds: params.getParam<String>(
              'workoutsIds',
              ParamType.String,
              isList: true,
            ),
            initial: params.getParam(
              'initial',
              ParamType.int,
            ),
          ),
        ),
        FFRoute(
          name: SelectWorkoutsWidget.routeName,
          path: SelectWorkoutsWidget.routePath,
          builder: (context, params) => SelectWorkoutsWidget(
            numWorkouts: params.getParam(
              'numWorkouts',
              ParamType.int,
            ),
          ),
        ),
        FFRoute(
          name: CalenderWidget.routeName,
          path: CalenderWidget.routePath,
          builder: (context, params) => CalenderWidget(),
        ),
        FFRoute(
          name: ExerciseHistoryCustomWidget.routeName,
          path: ExerciseHistoryCustomWidget.routePath,
          builder: (context, params) => ExerciseHistoryCustomWidget(
            exerciseId: params.getParam(
              'exerciseId',
              ParamType.int,
            ),
            overview: params.getParam(
              'overview',
              ParamType.bool,
            ),
            analytics: params.getParam(
              'analytics',
              ParamType.bool,
            ),
          ),
        ),
        FFRoute(
          name: TestWidget.routeName,
          path: TestWidget.routePath,
          builder: (context, params) => TestWidget(
            result: params.getParam(
              'result',
              ParamType.JSON,
            ),
          ),
        ),
        FFRoute(
          name: VideopageWidget.routeName,
          path: VideopageWidget.routePath,
          builder: (context, params) => VideopageWidget(
            videop: params.getParam(
              'videop',
              ParamType.String,
            ),
            analysisResult: params.getParam(
              'analysisResult',
              ParamType.JSON,
            ),
          ),
        ),
        FFRoute(
          name: ManageSubscriptionWidget.routeName,
          path: ManageSubscriptionWidget.routePath,
          builder: (context, params) => ManageSubscriptionWidget(),
        ),
        FFRoute(
          name: Test3Widget.routeName,
          path: Test3Widget.routePath,
          builder: (context, params) => Test3Widget(
            result2: params.getParam(
              'result2',
              ParamType.JSON,
            ),
          ),
        ),
        FFRoute(
          name: VideopageHEVYWidget.routeName,
          path: VideopageHEVYWidget.routePath,
          builder: (context, params) => VideopageHEVYWidget(
            videop: params.getParam(
              'videop',
              ParamType.String,
            ),
            analysisResult: params.getParam(
              'analysisResult',
              ParamType.JSON,
            ),
          ),
        ),
        FFRoute(
          name: LiveSquatWidget.routeName,
          path: LiveSquatWidget.routePath,
          builder: (context, params) => LiveSquatWidget(),
        ),
        FFRoute(
          name: BarbelllWidget.routeName,
          path: BarbelllWidget.routePath,
          builder: (context, params) => BarbelllWidget(
            result: params.getParam(
              'result',
              ParamType.JSON,
            ),
          ),
        ),
        FFRoute(
          name: CameraWidget.routeName,
          path: CameraWidget.routePath,
          builder: (context, params) => CameraWidget(
            exerciseId: params.getParam(
              'exerciseId',
              ParamType.int,
            ),
          ),
        ),
        FFRoute(
          name: AiCustomMuscelsWidget.routeName,
          path: AiCustomMuscelsWidget.routePath,
          builder: (context, params) => AiCustomMuscelsWidget(),
        ),
        FFRoute(
          name: AiWorkoutTypeWidget.routeName,
          path: AiWorkoutTypeWidget.routePath,
          builder: (context, params) => AiWorkoutTypeWidget(),
        ),
        FFRoute(
          name: AiExpirenceLevelWidget.routeName,
          path: AiExpirenceLevelWidget.routePath,
          builder: (context, params) => AiExpirenceLevelWidget(
            muscels: params.getParam<String>(
              'muscels',
              ParamType.String,
              isList: true,
            ),
          ),
        ),
        FFRoute(
          name: AiGoalWidget.routeName,
          path: AiGoalWidget.routePath,
          builder: (context, params) => AiGoalWidget(
            muscels: params.getParam<String>(
              'muscels',
              ParamType.String,
              isList: true,
            ),
            expirence: params.getParam(
              'expirence',
              ParamType.String,
            ),
          ),
        ),
        FFRoute(
          name: TestAIWidget.routeName,
          path: TestAIWidget.routePath,
          builder: (context, params) => TestAIWidget(
            result: params.getParam<GetSetAnalysisRow>(
              'result',
              ParamType.SqliteRow,
            ),
          ),
        ),
        FFRoute(
          name: AiWorkoutLoadingWidget.routeName,
          path: AiWorkoutLoadingWidget.routePath,
          builder: (context, params) => AiWorkoutLoadingWidget(
            goal: params.getParam(
              'goal',
              ParamType.int,
            ),
            expirence: params.getParam(
              'expirence',
              ParamType.String,
            ),
            muscels: params.getParam<String>(
              'muscels',
              ParamType.String,
              isList: true,
            ),
          ),
        ),
        FFRoute(
          name: AiWorkoutViewWidget.routeName,
          path: AiWorkoutViewWidget.routePath,
          builder: (context, params) => AiWorkoutViewWidget(
            result: params.getParam(
              'result',
              ParamType.JSON,
            ),
            goal: params.getParam(
              'goal',
              ParamType.int,
            ),
          ),
        ),
        FFRoute(
          name: PremiumPaywallPageWidget.routeName,
          path: PremiumPaywallPageWidget.routePath,
          builder: (context, params) => PremiumPaywallPageWidget(),
        ),
        FFRoute(
          name: ChangePasswordWidget.routeName,
          path: ChangePasswordWidget.routePath,
          builder: (context, params) => ChangePasswordWidget(),
        ),
        FFRoute(
          name: SignInWelcomePage6Widget.routeName,
          path: SignInWelcomePage6Widget.routePath,
          builder: (context, params) => SignInWelcomePage6Widget(),
        ),
        FFRoute(
          name: FullResultPageWidget.routeName,
          path: FullResultPageWidget.routePath,
          builder: (context, params) => FullResultPageWidget(
            exerciseName: params.getParam(
              'exerciseName',
              ParamType.String,
            ),
            analysis: params.getParam(
              'analysis',
              ParamType.JSON,
            ),
            exerciseId: params.getParam(
              'exerciseId',
              ParamType.int,
            ),
            isBodyweight: params.getParam(
              'isBodyweight',
              ParamType.int,
            ),
          ),
        ),
        FFRoute(
          name: FullAnalyzingStatePageWidget.routeName,
          path: FullAnalyzingStatePageWidget.routePath,
          builder: (context, params) => FullAnalyzingStatePageWidget(
            exerciseName: params.getParam(
              'exerciseName',
              ParamType.String,
            ),
            videoFile: params.getParam(
              'videoFile',
              ParamType.FFUploadedFile,
            ),
            exerciseId: params.getParam(
              'exerciseId',
              ParamType.int,
            ),
            isBodyweight: params.getParam(
              'isBodyweight',
              ParamType.int,
            ),
          ),
        ),
        FFRoute(
          name: MasterPageWidget.routeName,
          path: MasterPageWidget.routePath,
          builder: (context, params) => MasterPageWidget(
            initialTab: params.getParam(
              'initialTab',
              ParamType.int,
            ),
          ),
        ),
        FFRoute(
          name: CreateWorkoutV2Widget.routeName,
          path: CreateWorkoutV2Widget.routePath,
          builder: (context, params) => CreateWorkoutV2Widget(
            alreadySelceted: params.getParam<dynamic>(
              'alreadySelceted',
              ParamType.JSON,
              isList: true,
            ),
            shouldInit: params.getParam(
              'shouldInit',
              ParamType.bool,
            ),
            workoutName: params.getParam(
              'workoutName',
              ParamType.String,
            ),
          ),
        ),
        FFRoute(
          name: WorkoutCompleteWidget.routeName,
          path: WorkoutCompleteWidget.routePath,
          builder: (context, params) => WorkoutCompleteWidget(
            workoutLogId: params.getParam(
              'workoutLogId',
              ParamType.String,
            ),
          ),
        ),
        FFRoute(
          name: WorkoutSummaryViewWidget.routeName,
          path: WorkoutSummaryViewWidget.routePath,
          builder: (context, params) => WorkoutSummaryViewWidget(
            workoutLogId: params.getParam(
              'workoutLogId',
              ParamType.String,
            ),
          ),
        )
      ].map((r) => r.toRoute(appStateNotifier)).toList(),
    );

extension NavParamExtensions on Map<String, String?> {
  Map<String, String> get withoutNulls => Map.fromEntries(
        entries
            .where((e) => e.value != null)
            .map((e) => MapEntry(e.key, e.value!)),
      );
}

extension NavigationExtensions on BuildContext {
  void goNamedAuth(
    String name,
    bool mounted, {
    Map<String, String> pathParameters = const <String, String>{},
    Map<String, String> queryParameters = const <String, String>{},
    Object? extra,
    bool ignoreRedirect = false,
  }) =>
      !mounted || GoRouter.of(this).shouldRedirect(ignoreRedirect)
          ? null
          : goNamed(
              name,
              pathParameters: pathParameters,
              queryParameters: queryParameters,
              extra: extra,
            );

  void pushNamedAuth(
    String name,
    bool mounted, {
    Map<String, String> pathParameters = const <String, String>{},
    Map<String, String> queryParameters = const <String, String>{},
    Object? extra,
    bool ignoreRedirect = false,
  }) =>
      !mounted || GoRouter.of(this).shouldRedirect(ignoreRedirect)
          ? null
          : pushNamed(
              name,
              pathParameters: pathParameters,
              queryParameters: queryParameters,
              extra: extra,
            );

  void safePop() {
    // If there is only one route on the stack, navigate to the initial
    // page instead of popping.
    if (canPop()) {
      pop();
    } else {
      go('/');
    }
  }
}

extension GoRouterExtensions on GoRouter {
  AppStateNotifier get appState => AppStateNotifier.instance;
  void prepareAuthEvent([bool ignoreRedirect = false]) =>
      appState.hasRedirect() && !ignoreRedirect
          ? null
          : appState.updateNotifyOnAuthChange(false);
  bool shouldRedirect(bool ignoreRedirect) =>
      !ignoreRedirect && appState.hasRedirect();
  void clearRedirectLocation() => appState.clearRedirectLocation();
  void setRedirectLocationIfUnset(String location) =>
      appState.updateNotifyOnAuthChange(false);
}

extension _GoRouterStateExtensions on GoRouterState {
  Map<String, dynamic> get extraMap =>
      extra != null ? extra as Map<String, dynamic> : {};
  Map<String, dynamic> get allParams => <String, dynamic>{}
    ..addAll(pathParameters)
    ..addAll(uri.queryParameters)
    ..addAll(extraMap);
  TransitionInfo get transitionInfo => extraMap.containsKey(kTransitionInfoKey)
      ? extraMap[kTransitionInfoKey] as TransitionInfo
      : TransitionInfo.appDefault();
}

class FFParameters {
  FFParameters(this.state, [this.asyncParams = const {}]);

  final GoRouterState state;
  final Map<String, Future<dynamic> Function(String)> asyncParams;

  Map<String, dynamic> futureParamValues = {};

  // Parameters are empty if the params map is empty or if the only parameter
  // present is the special extra parameter reserved for the transition info.
  bool get isEmpty =>
      state.allParams.isEmpty ||
      (state.allParams.length == 1 &&
          state.extraMap.containsKey(kTransitionInfoKey));
  bool isAsyncParam(MapEntry<String, dynamic> param) =>
      asyncParams.containsKey(param.key) && param.value is String;
  bool get hasFutures => state.allParams.entries.any(isAsyncParam);
  Future<bool> completeFutures() => Future.wait(
        state.allParams.entries.where(isAsyncParam).map(
          (param) async {
            final doc = await asyncParams[param.key]!(param.value)
                .onError((_, __) => null);
            if (doc != null) {
              futureParamValues[param.key] = doc;
              return true;
            }
            return false;
          },
        ),
      ).onError((_, __) => [false]).then((v) => v.every((e) => e));

  dynamic getParam<T>(
    String paramName,
    ParamType type, {
    bool isList = false,
    StructBuilder<T>? structBuilder,
  }) {
    if (futureParamValues.containsKey(paramName)) {
      return futureParamValues[paramName];
    }
    if (!state.allParams.containsKey(paramName)) {
      return null;
    }
    final param = state.allParams[paramName];
    // Got parameter from `extras`, so just directly return it.
    if (param is! String) {
      return param;
    }
    // Return serialized value.
    return deserializeParam<T>(
      param,
      type,
      isList,
      structBuilder: structBuilder,
    );
  }
}

class FFRoute {
  const FFRoute({
    required this.name,
    required this.path,
    required this.builder,
    this.requireAuth = false,
    this.asyncParams = const {},
    this.routes = const [],
  });

  final String name;
  final String path;
  final bool requireAuth;
  final Map<String, Future<dynamic> Function(String)> asyncParams;
  final Widget Function(BuildContext, FFParameters) builder;
  final List<GoRoute> routes;

  GoRoute toRoute(AppStateNotifier appStateNotifier) => GoRoute(
        name: name,
        path: path,
        redirect: (context, state) {
          if (appStateNotifier.shouldRedirect) {
            final redirectLocation = appStateNotifier.getRedirectLocation();
            appStateNotifier.clearRedirectLocation();
            return redirectLocation;
          }

          if (requireAuth && !appStateNotifier.loggedIn) {
            appStateNotifier.setRedirectLocationIfUnset(state.uri.toString());
            return '/signInWelcomePage6';
          }
          return null;
        },
        pageBuilder: (context, state) {
          fixStatusBarOniOS16AndBelow(context);
          final ffParams = FFParameters(state, asyncParams);
          final page = ffParams.hasFutures
              ? FutureBuilder(
                  future: ffParams.completeFutures(),
                  builder: (context, _) => builder(context, ffParams),
                )
              : builder(context, ffParams);
          final child = appStateNotifier.loading
              ? Center(
                  child: SizedBox(
                    width: 50.0,
                    height: 50.0,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        FlutterFlowTheme.of(context).secondary,
                      ),
                    ),
                  ),
                )
              : page;

          final transitionInfo = state.transitionInfo;
          return transitionInfo.hasTransition
              ? CustomTransitionPage(
                  key: state.pageKey,
                  name: state.name,
                  child: child,
                  transitionDuration: transitionInfo.duration,
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) =>
                          PageTransition(
                    type: transitionInfo.transitionType,
                    duration: transitionInfo.duration,
                    reverseDuration: transitionInfo.duration,
                    alignment: transitionInfo.alignment,
                    curve: transitionInfo.transitionType ==
                            PageTransitionType.scale
                        ? const Interval(0.0, 0.5)
                        : Curves.linear,
                    child: child,
                  ).buildTransitions(
                    context,
                    animation,
                    secondaryAnimation,
                    child,
                  ),
                )
              : MaterialPage(
                  key: state.pageKey, name: state.name, child: child);
        },
        routes: routes,
      );
}

class TransitionInfo {
  const TransitionInfo({
    required this.hasTransition,
    this.transitionType = PageTransitionType.fade,
    this.duration = const Duration(milliseconds: 300),
    this.alignment,
  });

  final bool hasTransition;
  final PageTransitionType transitionType;
  final Duration duration;
  final Alignment? alignment;

  static TransitionInfo appDefault() => TransitionInfo(hasTransition: false);
}

class RootPageContext {
  const RootPageContext(this.isRootPage, [this.errorRoute]);
  final bool isRootPage;
  final String? errorRoute;

  static bool isInactiveRootPage(BuildContext context) {
    final rootPageContext = context.read<RootPageContext?>();
    final isRootPage = rootPageContext?.isRootPage ?? false;
    final location = GoRouterState.of(context).uri.toString();
    return isRootPage &&
        location != '/' &&
        location != rootPageContext?.errorRoute;
  }

  static Widget wrap(Widget child, {String? errorRoute}) => Provider.value(
        value: RootPageContext(true, errorRoute),
        child: child,
      );
}

extension GoRouterLocationExtension on GoRouter {
  String getCurrentLocation() {
    final RouteMatch lastMatch = routerDelegate.currentConfiguration.last;
    final RouteMatchList matchList = lastMatch is ImperativeRouteMatch
        ? lastMatch.matches
        : routerDelegate.currentConfiguration;
    return matchList.uri.toString();
  }
}
