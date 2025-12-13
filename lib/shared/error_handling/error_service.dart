import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Centralized error handling service for Timeline Biography App
/// Provides graceful degradation, user-friendly messages, and crash reporting
class ErrorService {
  static ErrorService? _instance;
  static ErrorService get instance => _instance ??= ErrorService._();
  
  ErrorService._();

  static const String _errorLogKey = 'error_log';
  static const String _crashReportKey = 'crash_reports';
  static const int _maxErrorLogs = 100;
  static const int _maxCrashReports = 50;

  SharedPreferences? _prefs;
  final List<AppError> _errorLog = [];
  final List<CrashReport> _crashReports = [];
  final StreamController<AppError> _errorController = 
      StreamController<AppError>.broadcast();
  final StreamController<ErrorRecovery> _recoveryController = 
      StreamController<ErrorRecovery>.broadcast();

  // =========================================================================
  // PUBLIC API
  // =========================================================================

  /// Initialize error service
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadErrorLogs();
    await _loadCrashReports();
    
    // Set up global error handlers
    FlutterError.onError = _handleFlutterError;
    PlatformDispatcher.instance.onError = _handlePlatformError;
  }

  /// Log an error with context
  Future<void> logError(
    dynamic error,
    StackTrace stackTrace, {
    String? context,
    Map<String, dynamic>? metadata,
    ErrorSeverity severity = ErrorSeverity.error,
    bool showToUser = false,
  }) async {
    final appError = AppError(
      id: _generateId(),
      timestamp: DateTime.now(),
      error: error.toString(),
      stackTrace: stackTrace.toString(),
      context: context,
      metadata: metadata,
      severity: severity,
      showToUser: showToUser,
    );

    _errorLog.insert(0, appError);
    if (_errorLog.length > _maxErrorLogs) {
      _errorLog.removeLast();
    }

    await _saveErrorLogs();
    _errorController.add(appError);

    // Show user-friendly message if needed
    if (showToUser) {
      _showUserMessage(appError);
    }

    // Report to crash service if critical
    if (severity == ErrorSeverity.critical) {
      await _reportCrash(appError);
    }
  }

  /// Handle network errors gracefully
  Future<T?> handleNetworkError<T>(
    Future<T> Function() operation, {
    T? fallbackValue,
    String? operationContext,
  }) async {
    try {
      return await operation();
    } on SocketException catch (e, stackTrace) {
      await logError(
        e,
        stackTrace,
        context: 'Network operation failed',
        metadata: {
          'operation': operationContext,
          'error_type': 'SocketException',
        },
        showToUser: true,
      );
      return fallbackValue;
    } on TimeoutException catch (e, stackTrace) {
      await logError(
        e,
        stackTrace,
        context: 'Network timeout',
        metadata: {
          'operation': operationContext,
          'error_type': 'TimeoutException',
        },
        showToUser: true,
      );
      return fallbackValue;
    } on HttpException catch (e, stackTrace) {
      await logError(
        e,
        stackTrace,
        context: 'HTTP error',
        metadata: {
          'operation': operationContext,
          'error_type': 'HttpException',
        },
        showToUser: true,
      );
      return fallbackValue;
    } catch (e, stackTrace) {
      await logError(
        e,
        stackTrace,
        context: 'Unexpected network error',
        metadata: {
          'operation': operationContext,
          'error_type': 'Unknown',
        },
        showToUser: true,
      );
      return fallbackValue;
    }
  }

  /// Handle database errors with recovery options
  Future<T?> handleDatabaseError<T>(
    Future<T> Function() operation, {
    T? fallbackValue,
    String? operationContext,
    List<ErrorRecovery>? recoveryOptions,
  }) async {
    try {
      return await operation();
    } on DatabaseException catch (e, stackTrace) {
      await logError(
        e,
        stackTrace,
        context: 'Database operation failed',
        metadata: {
          'operation': operationContext,
          'error_type': 'DatabaseException',
        },
        showToUser: true,
      );

      // Offer recovery options
      if (recoveryOptions != null) {
        for (final option in recoveryOptions) {
          _recoveryController.add(option);
        }
      }

      return fallbackValue;
    } catch (e, stackTrace) {
      await logError(
        e,
        stackTrace,
        context: 'Unexpected database error',
        metadata: {
          'operation': operationContext,
          'error_type': 'Unknown',
        },
        showToUser: true,
      );
      return fallbackValue;
    }
  }

  /// Get user-friendly error message
  String getUserMessage(AppError error) {
    switch (error.metadata?['error_type']) {
      case 'SocketException':
        return 'No internet connection. Please check your network and try again.';
      case 'TimeoutException':
        return 'Request timed out. Please try again.';
      case 'HttpException':
        return 'Server error. Please try again later.';
      case 'DatabaseException':
        return 'Data storage error. Some features may be unavailable.';
      case 'FileSystemException':
        return 'File access error. Please check storage permissions.';
      case 'CameraException':
        return 'Camera error. Please ensure camera permissions are granted.';
      default:
        switch (error.severity) {
          case ErrorSeverity.warning:
            return 'Something unexpected happened, but you can continue using the app.';
          case ErrorSeverity.error:
            return 'An error occurred. Please try again.';
          case ErrorSeverity.critical:
            return 'A critical error occurred. The app may need to be restarted.';
        }
    }
  }

  /// Clear error logs
  Future<void> clearErrorLogs() async {
    _errorLog.clear();
    await _prefs?.remove(_errorLogKey);
  }

  /// Clear crash reports
  Future<void> clearCrashReports() async {
    _crashReports.clear();
    await _prefs?.remove(_crashReportKey);
  }

  /// Export error logs for debugging
  Future<String> exportErrorLogs() async {
    final buffer = StringBuffer();
    buffer.writeln('=== Timeline Biography Error Logs ===');
    buffer.writeln('Exported: ${DateTime.now().toIso8601String()}\n');

    for (final error in _errorLog) {
      buffer.writeln('--- Error ${error.id} ---');
      buffer.writeln('Timestamp: ${error.timestamp.toIso8601String()}');
      buffer.writeln('Severity: ${error.severity.name}');
      if (error.context != null) {
        buffer.writeln('Context: ${error.context}');
      }
      buffer.writeln('Error: ${error.error}');
      if (error.metadata?.isNotEmpty == true) {
        buffer.writeln('Metadata: ${error.metadata}');
      }
      buffer.writeln('Stack Trace:\n${error.stackTrace}\n');
    }

    return buffer.toString();
  }

  // =========================================================================
  // GETTERS
  // =========================================================================

  List<AppError> get errorLogs => List.unmodifiable(_errorLog);
  List<CrashReport> get crashReports => List.unmodifiable(_crashReports);
  Stream<AppError> get errorStream => _errorController.stream;
  Stream<ErrorRecovery> get recoveryStream => _recoveryController.stream;

  // =========================================================================
  // PRIVATE METHODS
  // =========================================================================

  void _handleFlutterError(FlutterErrorDetails details) {
    logError(
      details.exception,
      details.stack ?? StackTrace.current,
      context: 'Flutter framework error',
      severity: ErrorSeverity.error,
    );
  }

  bool _handlePlatformError(Object error, StackTrace stack) {
    logError(
      error,
      stack,
      context: 'Platform error',
      severity: ErrorSeverity.critical,
    );
    return true;
  }

  Future<void> _reportCrash(AppError error) async {
    final report = CrashReport(
      id: _generateId(),
      timestamp: DateTime.now(),
      errorId: error.id,
      error: error.error,
      stackTrace: error.stackTrace,
      deviceInfo: await _getDeviceInfo(),
      appVersion: await _getAppVersion(),
    );

    _crashReports.insert(0, report);
    if (_crashReports.length > _maxCrashReports) {
      _crashReports.removeLast();
    }

    await _saveCrashReports();
  }

  void _showUserMessage(AppError error) {
    // Implementation would show snackbar or dialog
    // For now, just log that it would be shown
    debugPrint('User message: ${getUserMessage(error)}');
  }

  Future<void> _loadErrorLogs() async {
    final logsJson = _prefs?.getStringList(_errorLogKey) ?? [];
    _errorLog.clear();
    
    for (final logJson in logsJson) {
      try {
        // Parse and add to log
        // Implementation would deserialize JSON
      } catch (e) {
        debugPrint('Failed to parse error log: $e');
      }
    }
  }

  Future<void> _loadCrashReports() async {
    final reportsJson = _prefs?.getStringList(_crashReportKey) ?? [];
    _crashReports.clear();
    
    for (final reportJson in reportsJson) {
      try {
        // Parse and add to reports
        // Implementation would deserialize JSON
      } catch (e) {
        debugPrint('Failed to parse crash report: $e');
      }
    }
  }

  Future<void> _saveErrorLogs() async {
    final logsJson = _errorLog.map((e) => e.toJson()).toList();
    await _prefs?.setStringList(_errorLogKey, logsJson);
  }

  Future<void> _saveCrashReports() async {
    final reportsJson = _crashReports.map((r) => r.toJson()).toList();
    await _prefs?.setStringList(_crashReportKey, reportsJson);
  }

  String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString() +
        '_${(DateTime.now().microsecond % 10000).toString().padLeft(4, '0')}';
  }

  Future<Map<String, String>> _getDeviceInfo() async {
    return {
      'platform': Platform.operatingSystem,
      'version': Platform.operatingSystemVersion,
      'locale': Platform.localeName,
    };
  }

  Future<String> _getAppVersion() async {
    // Implementation would get app version from package_info
    return '1.0.0';
  }

  // =========================================================================
  // DISPOSE
  // =========================================================================

  Future<void> dispose() async {
    await _errorController.close();
    await _recoveryController.close();
  }
}

// =========================================================================
// DATA MODELS
// =========================================================================

enum ErrorSeverity {
  warning,
  error,
  critical,
}

class AppError {
  final String id;
  final DateTime timestamp;
  final String error;
  final String stackTrace;
  final String? context;
  final Map<String, dynamic>? metadata;
  final ErrorSeverity severity;
  final bool showToUser;

  AppError({
    required this.id,
    required this.timestamp,
    required this.error,
    required this.stackTrace,
    this.context,
    this.metadata,
    required this.severity,
    required this.showToUser,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'error': error,
      'stackTrace': stackTrace,
      'context': context,
      'metadata': metadata,
      'severity': severity.name,
      'showToUser': showToUser,
    };
  }
}

class CrashReport {
  final String id;
  final DateTime timestamp;
  final String errorId;
  final String error;
  final String stackTrace;
  final Map<String, String> deviceInfo;
  final String appVersion;

  CrashReport({
    required this.id,
    required this.timestamp,
    required this.errorId,
    required this.error,
    required this.stackTrace,
    required this.deviceInfo,
    required this.appVersion,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'errorId': errorId,
      'error': error,
      'stackTrace': stackTrace,
      'deviceInfo': deviceInfo,
      'appVersion': appVersion,
    };
  }
}

class ErrorRecovery {
  final String id;
  final String title;
  final String description;
  final String action;
  final VoidCallback? onExecute;

  ErrorRecovery({
    required this.id,
    required this.title,
    required this.description,
    required this.action,
    this.onExecute,
  });
}

// Custom exception types
class DatabaseException implements Exception {
  final String message;
  DatabaseException(this.message);
  
  @override
  String toString() => 'DatabaseException: $message';
}

class CameraException implements Exception {
  final String message;
  CameraException(this.message);
  
  @override
  String toString() => 'CameraException: $message';
}

class FileSystemException implements Exception {
  final String message;
  final String? path;
  FileSystemException(this.message, [this.path]);
  
  @override
  String toString() => 'FileSystemException: $message${path != null ? ' (path: $path)' : ''}';
}

// =========================================================================
// PROVIDERS
// =========================================================================

final errorServiceProvider = Provider<ErrorService>((ref) {
  return ErrorService.instance;
});

final errorStreamProvider = StreamProvider<AppError>((ref) {
  final service = ref.watch(errorServiceProvider);
  return service.errorStream;
});

final recoveryStreamProvider = StreamProvider<ErrorRecovery>((ref) {
  final service = ref.watch(errorServiceProvider);
  return service.recoveryStream;
});
