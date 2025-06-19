import 'dart:convert';
import 'package:compute/compute.dart';
import 'package:dart_style/dart_style.dart';

import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';
import 'package:json_to_dart_library/src/dart_object.dart';
import 'package:json_to_dart_library/src/dart_property.dart';
import 'package:json_to_dart_library/src/utils/dart_helper.dart';
import 'package:json_to_dart_library/src/utils/extension.dart';
import 'package:json_to_dart_library/src/utils/string_buffer.dart';

import 'config.dart';

/// Provides core functionality to convert JSON to Dart classes.
mixin JsonToDartControllerMixin {
  // Stores all parsed DartProperty instances
  Set<DartProperty> allProperties = <DartProperty>{};

  // Stores all DartObject instances created during parsing
  Set<DartObject> allObjects = <DartObject>{};

  // Keeps track of already printed objects to avoid duplicates
  Set<DartObject> printedObjects = <DartObject>{};

  /// Converts a JSON string into a DartObject representation.
  Future<DartObject?> jsonToDartObject({
    required String json,
    String rootObjectName = 'Root',
  }) async {
    allProperties.clear();
    allObjects.clear();
    if (json.isNullOrEmpty) {
      return null;
    }

    String inputText = json;
    try {
      // Decode JSON in a separate isolate using compute
      final dynamic jsonData =
          await compute<String, dynamic>(jsonDecode, inputText)
              .onError((Object? error, StackTrace stackTrace) {
        handleError(error, stackTrace);
      });

      // Convert the dynamic JSON into DartObject
      final DartObject? extendedObject =
          dynamicToDartObject(jsonData, rootObjectName: rootObjectName);

      // Handle null safety and nullability based on config
      if (extendedObject != null &&
          jsonToDartConfig.nullsafety &&
          jsonToDartConfig.nullable &&
          !jsonToDartConfig.smartNullable) {
        extendedObject.updateNullable(true);
      }

      return extendedObject;
    } catch (error, stackTrace) {
      handleError(error, stackTrace);
    }
    return null;
  }

  /// Converts a dynamic JSON structure to a DartObject
  DartObject? dynamicToDartObject(
    dynamic jsonData, {
    String rootObjectName = 'Root',
  }) {
    DartObject? extendedObject;

    // Handle JSON object
    if (jsonData is Map) {
      extendedObject = jsonToDartConfig.createDartObject(
        depth: 0,
        keyValuePair: MapEntry<String, dynamic>(
            rootObjectName, jsonData as Map<String, dynamic>),
        nullable: false,
        uid: rootObjectName,
      );
    }
    // Handle JSON array
    else if (jsonData is List) {
      final Map<String, List<dynamic>> root = <String, List<dynamic>>{
        rootObjectName: jsonData
      };
      extendedObject = jsonToDartConfig
          .createDartObject(
            depth: 0,
            keyValuePair: MapEntry<String, dynamic>(rootObjectName, root),
            nullable: false,
            uid: rootObjectName,
          )
          .objectKeys[rootObjectName]! // Access the object
        ..decDepth(); // Decrease depth level for correct nesting
    }
    return extendedObject;
  }

  /// Generates Dart class code from a DartObject
  String? generateDartCode(DartObject? dartObject) {
    printedObjects.clear();

    if (dartObject != null) {
      final CustomStringBuffer sb = CustomStringBuffer();
      try {
        // Insert file header info if provided
        if (!jsonToDartConfig.fileHeaderInfo.contains('dart:convert')) {
          // Import JSON utilities
          sb.writeLine(DartHelper.jsonImport);
        }

        if (jsonToDartConfig.fileHeaderInfo.isNotEmpty) {
          String info = jsonToDartConfig.fileHeaderInfo;

          // Handle [Date xxx] placeholder replacement with actual date
          try {
            int start = info.indexOf('[Date');
            final int startIndex = start;
            if (start >= 0) {
              start = start + '[Date'.length;
              final int end = info.indexOf(']', start);
              if (end >= start) {
                String format = info.substring(start, end - start).trim();

                final String replaceString =
                    info.substring(startIndex, end - startIndex + 1);
                if (format == '') {
                  format = 'yyyy MM-dd';
                }

                info = info.replaceAll(
                    replaceString, DateFormat(format).format(DateTime.now()));
              }
            }
          } catch (e) {
            // Ignore date format errors
          }

          sb.writeLine(info);
        }

        // Append JSON parsing helpers if addMethod is enabled
        if (jsonToDartConfig.addMethod) {
          if (jsonToDartConfig.enableArrayProtection) {
            sb.writeLine('import \'dart:developer\';');
            sb.writeLine(jsonToDartConfig.nullsafety
                ? DartHelper.tryCatchMethodNullSafety
                : DartHelper.tryCatchMethod);
          }

          sb.writeLine(jsonToDartConfig.enableDataProtection
              ? jsonToDartConfig.nullsafety
                  ? DartHelper.asTMethodWithDataProtectionNullSafety
                  : DartHelper.asTMethodWithDataProtection
              : jsonToDartConfig.nullsafety
                  ? DartHelper.asTMethodNullSafety
                  : DartHelper.asTMethod);
        }
        String dartObjectString = dartObject.toString();
        if (dartObjectString.isEmpty) {
          return '';
        }
        // Append Dart class definitions
        sb.writeLine(dartObjectString);

        // Format code using Dart formatter
        String result = sb.toString();
        DartFormatter? formatter = jsonToDartConfig.formatter;
        if (formatter != null) {
          result = formatter.format(result);
        }

        return result;
      } catch (e, stack) {
        handleError(e, stack);
        return null;
      }
    }
    return null;
  }

  /// Handles and prints errors, then rethrows them
  void handleError(Object? e, StackTrace stack) {
    print('$e');
    print('$stack');
    throw e as Exception;
  }

  /// Collects and returns a list of error messages from all objects and properties
  List<String> getErrors() {
    List<String> errors = <String>[];

    for (var element in allObjects) {
      errors.addAll(element.classError);
      errors.addAll(element.propertyError);
    }

    for (var element in allProperties) {
      errors.addAll(element.propertyError);
    }

    return errors;
  }
}

// Default controller instance using the mixin
class _JsonToDartController with JsonToDartControllerMixin {}

final _JsonToDartController _jsonToDartController = _JsonToDartController();

/// Register a custom controller instance for use via GetIt
void registerController(JsonToDartControllerMixin controller) {
  GetIt.instance.registerSingleton<JsonToDartControllerMixin>(controller);
}

/// Retrieve the active controller (either registered or default)
JsonToDartControllerMixin get jsonToDartController =>
    GetIt.instance.isRegistered<JsonToDartControllerMixin>()
        ? GetIt.instance.get<JsonToDartControllerMixin>()
        : _jsonToDartController;
