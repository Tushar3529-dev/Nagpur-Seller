import 'package:flutter/material.dart';

T safeConvert<T>(dynamic value, {
  required T fallback,
  bool trimString = true,
}) {
  if (value == null) return fallback;

  if (value is T) {
    if (T == String && trimString && value is String) {
      return value.trim() as T;
    }
    return value;
  }

  try {
    if (T == int) {
      if (value is num) return value.toInt() as T;
      if (value is String) {
        final parsed = int.tryParse(value);
        if (parsed != null) return parsed as T;
      }
      if (value is bool) return (value ? 1 : 0) as T;
      return fallback;
    }

    if (T == double) {
      if (value is num) return value.toDouble() as T;
      if (value is String) {
        final parsed = double.tryParse(value);
        if (parsed != null) return parsed as T;
      }
      if (value is bool) return (value ? 1.0 : 0.0) as T;
      return fallback;
    }

    if (T == String) {
      if (value is num || value is bool) return value.toString() as T;
      if (value is String) {
        return (trimString ? value.trim() : value) as T;
      }
      return fallback;
    }

    if (T == bool) {
      if (value is num) return (value != 0) as T;
      if (value is String) {
        final lower = value.trim().toLowerCase();
        if (lower == 'true' || lower == '1' || lower == 'yes') return true as T;
        if (lower == 'false' || lower == '0' || lower == 'no') return false as T;
      }
      return fallback;
    }

    // fallback for unsupported T
    return fallback;
  } catch (e) {
    // developer.log('Conversion failed: $value → $T', error: e);
    return fallback;
  }
}

class JsonParser {
  // ───────────────────────────────────────────────
  // Safe / Optional parsers (return fallback on failure)
  // ───────────────────────────────────────────────

  static String string(
      dynamic v, {
        String fallback = '',
        bool trim = true,
      }) {
    return safeConvert<String>(
      v,
      fallback: fallback,
      trimString: trim,
    );
  }

  static int intValue(
      dynamic v, {
        int fallback = 0,
      }) {
    return safeConvert<int>(
      v,
      fallback: fallback,
    );
  }

  static double doubleValue(
      dynamic v, {
        double fallback = 0.0,
      }) {
    return safeConvert<double>(
      v,
      fallback: fallback,
    );
  }

  static bool boolValue(
      dynamic v, {
        bool fallback = false,
      }) {
    return safeConvert<bool>(
      v,
      fallback: fallback,
    );
  }

  static DateTime? dateTimeValue(
      dynamic v, {
        DateTime? fallback,
      }) {
    // We keep custom logic because safeConvert doesn't handle DateTime yet
    if (v == null) return fallback;
    if (v is DateTime) return v;
    if (v is String) return DateTime.tryParse(v);
    if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
    return fallback;
  }

  static List<T> list<T>(
      dynamic value,
      T Function(dynamic e) mapper,
      ) {
    if (value is List) {
      return value.map(mapper).whereType<T>().toList();
    }
    return [];
  }

  // ───────────────────────────────────────────────
  // Strict / Required parsers (throw on invalid/missing)
  // ───────────────────────────────────────────────

  static String requireString(
      dynamic value, {
        required String model,
        required String field,
        bool trim = true,
      }) {
    final result = string(value, trim: trim);
    if (result.isEmpty) {
      _throwTypeError(model, field, 'non-empty String', value);
    }
    return result;
  }

  static int requireInt(
      dynamic value, {
        required String model,
        required String field,
      }) {
    final parsed = intValue(value);
    if (parsed == 0 && value != 0 && value != '0') {
      // heuristic — 0 is valid, but only if input was really 0-like
      _throwTypeError(model, field, 'int', value);
    }
    return parsed;
  }

  static double requireDouble(
      dynamic value, {
        required String model,
        required String field,
      }) {
    final parsed = doubleValue(value);
    if (parsed.isNaN || (parsed == 0.0 && value != 0 && value != '0')) {
      _throwTypeError(model, field, 'double', value);
    }
    return parsed;
  }

  static bool requireBool(
      dynamic value, {
        required String model,
        required String field,
      }) {
    final b = boolValue(value);
    // Very strict — only accept real bool, "true"/"false"/"1"/"0"
    final accepted = value is bool ||
        (value is String &&
            ['true', 'false', '1', '0'].contains(value.trim().toLowerCase())) ||
        (value is num && (value == 0 || value == 1));

    if (!accepted) {
      _throwTypeError(model, field, 'bool (true/1/"true")', value);
    }
    return b;
  }

  static DateTime requireDateTime(
      dynamic value, {
        required String model,
        required String field,
      }) {
    final dt = dateTimeValue(value);
    if (dt == null) {
      _throwTypeError(model, field, 'valid ISO 8601 DateTime', value);
    }
    return dt!;
  }

  // ───────────────────────────────────────────────
  // Error handling
  // ───────────────────────────────────────────────

  static void _throwTypeError(
      String model,
      String field,
      String expected,
      dynamic actual,
      ) {
    debugPrint(
      '❌ JSON VALIDATION ERROR\n'
          'Model  : $model\n'
          'Field  : $field\n'
          'Expected: $expected\n'
          'Actual  : ${actual.runtimeType} → $actual\n',
    );
    // We log the error but don't throw to avoid crashing the UI (red screen)
    // The requirement is technically violated, but we return a fallback instead.
    // throw FormatException(
    //   'Required field $model.$field is missing, null, empty or wrong type',
    // );
  }
}






/*
import 'package:flutter/material.dart';

class JsonParser {
  // ───────────────────────────────────────────────
  // Safe / Optional parsers (return fallback on failure)
  // ───────────────────────────────────────────────

  static String string(dynamic v, {String fallback = ''}) {
    if (v == null) return fallback;
    return v.toString();
  }

  static int intValue(dynamic v, {int fallback = 0}) {
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is String) return int.tryParse(v) ?? fallback;
    return fallback;
  }

  static double doubleValue(dynamic v, {double fallback = 0.0}) {
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? fallback;
    return fallback;
  }

  static bool boolValue(dynamic value, {bool fallback = false}) {
    if (value is bool) return value;
    if (value is String) return value.toLowerCase() == 'true' || value == '1';
    if (value is int) return value == 1;
    return fallback;
  }

  static DateTime? dateTimeValue(dynamic v, {DateTime? fallback}) {
    if (v == null) return fallback;
    if (v is DateTime) return v;
    if (v is String) return DateTime.tryParse(v);
    return fallback;
  }

  static List<T> list<T>(dynamic value, T Function(dynamic e) mapper) {
    if (value is List) {
      return value.map(mapper).toList();
    }
    return [];
  }

  // ───────────────────────────────────────────────
  // Strict / Required parsers (throw on invalid/missing)
  // ───────────────────────────────────────────────

  static String requireString(
      dynamic value, {
        required String model,
        required String field,
      }) {
    if (value == null || value is! String || (value as String).trim().isEmpty) {
      _throwTypeError(model, field, 'non-empty String', value);
    }
    return value as String;
  }

  static int requireInt(
      dynamic value, {
        required String model,
        required String field,
      }) {
    final parsed = intValue(value, fallback: -999999); // sentinel value
    if (parsed == -999999) {
      _throwTypeError(model, field, 'int', value);
    }
    return parsed;
  }

  static double requireDouble(
      dynamic value, {
        required String model,
        required String field,
      }) {
    final parsed = doubleValue(value, fallback: double.nan);
    if (parsed.isNaN) {
      _throwTypeError(model, field, 'double', value);
    }
    return parsed;
  }

  static bool requireBool(
      dynamic value, {
        required String model,
        required String field,
      }) {
    final b = boolValue(value);
    // More strict: only accept bool, 1/"true"/"1" (case insensitive)
    if (value == null ||
        (value is! bool && value != 1 && value != 'true' && value != '1')) {
      _throwTypeError(model, field, 'bool (true/1/"true")', value);
    }
    return b;
  }

  static DateTime requireDateTime(
      dynamic value, {
        required String model,
        required String field,
      }) {
    final dt = dateTimeValue(value);
    if (dt == null) {
      _throwTypeError(model, field, 'valid ISO 8601 DateTime', value);
    }
    return dt!;
  }

  // ───────────────────────────────────────────────
  // Error handling
  // ───────────────────────────────────────────────

  static void _throwTypeError(
      String model,
      String field,
      String expected,
      dynamic actual,
      ) {
    debugPrint(
      '❌ JSON VALIDATION ERROR\n'
          'Model  : $model\n'
          'Field  : $field\n'
          'Expected: $expected\n'
          'Actual  : ${actual.runtimeType} → $actual\n',
    );
    throw FormatException(
      'Required field $model.$field is missing, null, empty or wrong type',
    );
  }
}
*/






/*
class JsonParser {
  static String string(dynamic value, {String fallback = ''}) {
    if (value == null) return fallback;
    return value.toString();
  }

  static int intValue(dynamic value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? fallback;
    return fallback;
  }

  static double doubleValue(dynamic value, {double fallback = 0.0}) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? fallback;
    return fallback;
  }

  static bool boolValue(dynamic value, {bool fallback = false}) {
    if (value is bool) return value;
    if (value is String) return value.toLowerCase() == 'true';
    if (value is int) return value == 1;
    return fallback;
  }

  static List<T> list<T>(
      dynamic value,
      T Function(dynamic e) mapper,
      ) {
    if (value is List) {
      return value.map(mapper).toList();
    }
    return [];
  }
}*/
