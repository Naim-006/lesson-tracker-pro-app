import 'dart:developer' as developer;

class Logger {
  static const String _tag = 'LessonTrackerPro';

  static void debug(String message, {Object? error, StackTrace? stackTrace}) {
    developer.log(
      message,
      name: _tag,
      level: 500, // Level 500 is debug in dart:developer
      error: error,
      stackTrace: stackTrace,
    );
  }

  static void info(String message, {Object? error, StackTrace? stackTrace}) {
    developer.log(
      message,
      name: _tag,
      level: 800, // Level 800 is info in dart:developer
      error: error,
      stackTrace: stackTrace,
    );
  }

  static void warning(String message, {Object? error, StackTrace? stackTrace}) {
    developer.log(
      message,
      name: _tag,
      level: 900, // Level 900 is warning in dart:developer
      error: error,
      stackTrace: stackTrace,
    );
  }

  static void error(String message, {Object? error, StackTrace? stackTrace}) {
    developer.log(
      message,
      name: _tag,
      level: 1000, // Level 1000 is error in dart:developer
      error: error,
      stackTrace: stackTrace,
    );
  }

  static void exception(String message, {Object? error, StackTrace? stackTrace}) {
    developer.log(
      message,
      name: _tag,
      level: 1000, // Level 1000 is error in dart:developer
      error: error,
      stackTrace: stackTrace,
    );
  }
}
