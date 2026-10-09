import 'dart:convert';

import 'package:flutter/foundation.dart';

import '/flutter_flow/flutter_flow_util.dart';
import 'api_manager.dart';

export 'api_manager.dart' show ApiCallResponse;

const _kPrivateApiFunctionName = 'ffPrivateApiCall';

class AnalyzeSquatCall {
  static Future<ApiCallResponse> call({
    FFUploadedFile? video,
    String? exerciseType = '',
    bool? fast = true,
  }) async {
    return ApiManager.instance.makeApiCall(
      callName: 'AnalyzeSquat',
      apiUrl: 'https://squat-api-docker-f0hd2a.fly.dev/analyze',
      callType: ApiCallType.POST,
      headers: {},
      params: {
        'video': video,
        'exercise_type': exerciseType,
        'fast': fast,
      },
      bodyType: BodyType.MULTIPART,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class WebhookCall {
  static Future<ApiCallResponse> call({
    String? type = '',
    String? message = '',
    String? userId = '',
  }) async {
    return ApiManager.instance.makeApiCall(
      callName: 'webhook',
      apiUrl: 'https://hooks.zapier.com/hooks/catch/25793666/ual4tjj/',
      callType: ApiCallType.POST,
      headers: {},
      params: {
        'type': type,
        'message': message,
        'user_id': userId,
      },
      bodyType: BodyType.MULTIPART,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class WorkoutBuilderCall {
  static Future<ApiCallResponse> call({
    String? goal = '',
    String? level = '',
    List<String>? targetMusclesList,
    String? userToken = '',
    String? apiKey = '',
  }) async {
    final targetMuscles = _serializeList(targetMusclesList);

    final ffApiRequestBody = '''
{
  "goal": ${goal == null ? 'null' : '"${escapeStringForJson(goal)}"'},
  "level": ${level == null ? 'null' : '"${escapeStringForJson(level)}"'},
  "target_muscles": ${targetMuscles}
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'Workout Builder',
      apiUrl:
          'https://zlbmwitjsmenaxofabhi.supabase.co/functions/v1/super-worker',
      callType: ApiCallType.POST,
      headers: {
        'apikey': '${apiKey}',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${userToken}',
      },
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class ApiPagingParams {
  int nextPageNumber = 0;
  int numItems = 0;
  dynamic lastResponse;

  ApiPagingParams({
    required this.nextPageNumber,
    required this.numItems,
    required this.lastResponse,
  });

  @override
  String toString() =>
      'PagingParams(nextPageNumber: $nextPageNumber, numItems: $numItems, lastResponse: $lastResponse,)';
}

String _toEncodable(dynamic item) {
  return item;
}

String _serializeList(List? list) {
  list ??= <String>[];
  try {
    return json.encode(list, toEncodable: _toEncodable);
  } catch (_) {
    if (kDebugMode) {
      print("List serialization failed. Returning empty list.");
    }
    return '[]';
  }
}

String _serializeJson(dynamic jsonVar, [bool isList = false]) {
  jsonVar ??= (isList ? [] : {});
  try {
    return json.encode(jsonVar, toEncodable: _toEncodable);
  } catch (_) {
    if (kDebugMode) {
      print("Json serialization failed. Returning empty json.");
    }
    return isList ? '[]' : '{}';
  }
}

String? escapeStringForJson(String? input) {
  if (input == null) {
    return null;
  }
  final encoded = jsonEncode(input);
  return encoded.substring(1, encoded.length - 1);
}
