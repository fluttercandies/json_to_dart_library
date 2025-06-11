import 'dart:convert';
import 'package:compute/compute.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';
import 'package:json_to_dart_library/src/dart_object.dart';
import 'package:json_to_dart_library/src/dart_property.dart';
import 'package:json_to_dart_library/src/utils/dart_helper.dart';
import 'package:json_to_dart_library/src/utils/extension.dart';
import 'package:json_to_dart_library/src/utils/string_buffer.dart';

import 'config.dart';

mixin JsonToDartControllerMixin {
  Set<DartProperty> allProperties = <DartProperty>{};
  Set<DartObject> allObjects = <DartObject>{};
  Set<DartObject> printedObjects = <DartObject>{};

  /// convert json string to DartObject
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
      // if (kIsWeb) {
      //   // fix https://github.com/dart-lang/sdk/issues/34105
      //   inputText = json.replaceAll('.0', '.1');
      // }

      final dynamic jsonData =
          await compute<String, dynamic>(jsonDecode, inputText)
              .onError((Object? error, StackTrace stackTrace) {
        handleError(error, stackTrace);
      });

      final DartObject? extendedObject =
          dynamicToDartObject(jsonData, rootObjectName: rootObjectName);

      if (extendedObject == null) {
        return null;
      }

      if (jsonToDartConfig.nullsafety &&
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

  DartObject? dynamicToDartObject(
    dynamic jsonData, {
    String rootObjectName = 'Root',
  }) {
    DartObject? extendedObject;

    if (jsonData is Map) {
      extendedObject = jsonToDartConfig.createDartObject(
        depth: 0,
        keyValuePair: MapEntry<String, dynamic>(
            rootObjectName, jsonData as Map<String, dynamic>),
        nullable: false,
        uid: rootObjectName,
      );
    } else if (jsonData is List) {
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
          .objectKeys[rootObjectName]!
        ..decDepth();
    }
    return extendedObject;
  }

  String? generateDartCode(DartObject? dartObject) {
    printedObjects.clear();

    if (dartObject != null) {
      // final DartObject? errorObject = allObjects.firstOrNullWhere(
      //     (DartObject element) =>
      //         element.classError.isNotEmpty ||
      //         element.propertyError.isNotEmpty);
      // if (errorObject != null) {
      //   showAlertDialog(errorObject.classError.join('\n') +
      //       '\n' +
      //       errorObject.propertyError.join('\n'));
      //   return null;
      // }

      // final DartProperty? errorProperty = allProperties.firstOrNullWhere(
      //     (DartProperty element) => element.propertyError.isNotEmpty);

      // if (errorProperty != null) {
      //   showAlertDialog(errorProperty.propertyError.join('\n'));
      //   return null;
      // }

      final CustomStringBuffer sb = CustomStringBuffer();
      try {
        if (jsonToDartConfig.fileHeaderInfo.isNotEmpty) {
          String info = jsonToDartConfig.fileHeaderInfo;
          //[Date MM-dd HH:mm]
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
            // showAlertDialog(appLocalizations.timeFormatError, Icons.error);
          }

          sb.writeLine(info);
        }

        sb.writeLine(DartHelper.jsonImport);

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

        sb.writeLine(dartObject.toString());
        String result = sb.toString();

        result = jsonToDartConfig.formatter.format(result);

        // _textEditingController.text = result;
        // Clipboard.setData(ClipboardData(text: result));

        return result;
      } catch (e, stack) {
        handleError(e, stack);
        return null;
      }
    }
    return null;
  }

  void handleError(Object? e, StackTrace stack) {
    print('$e');
    print('$stack');

    // showAlertDialog(appLocalizations.formatErrorInfo, Icons.error);
  }
}

class _JsonToDartController with JsonToDartControllerMixin {}

_JsonToDartController _jsonToDartController = _JsonToDartController();

void registerController(JsonToDartControllerMixin controller) {
  GetIt.instance.registerSingleton<JsonToDartControllerMixin>(controller);
}

JsonToDartControllerMixin get jsonToDartController =>
    GetIt.instance.isRegistered<JsonToDartControllerMixin>()
        ? GetIt.instance.get<JsonToDartControllerMixin>()
        : _jsonToDartController;
