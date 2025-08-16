import 'dart:collection';

import 'package:equatable/equatable.dart';
import 'package:json_to_dart_library/src/controller.dart';

import 'package:json_to_dart_library/src/dart_object.dart';
import 'package:json_to_dart_library/src/error_checker.dart';
import 'package:json_to_dart_library/src/utils/custom_set.dart';
import 'package:json_to_dart_library/src/utils/enums.dart';

import 'config.dart';
import 'utils/camel_under_score_converter.dart';
import 'utils/dart_helper.dart';
import 'utils/string_buffer.dart';
import 'utils/string_helper.dart';

// ignore: must_be_immutable
class DartProperty extends Equatable {
  DartProperty({
    required String uid,
    required this.depth,
    required this.keyValuePair,
    required this.nullable,
    required this.dartObject,
  }) {
    init();
    key = keyValuePair.key;
    this.uid = '${uid}_${keyValuePair.key}';
    propertyAccessorType = jsonToDartConfig.propertyAccessorType;
    type = DartHelper.converDartType(keyValuePair.value.runtimeType);
    name = keyValuePair.key;
    value = keyValuePair.value;
    jsonToDartController.allProperties.add(this);
  }

  /// init before cotructor code
  void init() {}

  final DartObject? dartObject;
  late String uid;
  late int depth;
  late final String key;
  late final dynamic value;
  final MapEntry<String, dynamic> keyValuePair;

  String name = '';

  PropertyAccessorType propertyAccessorType = PropertyAccessorType.none;

  bool nullable = false;

  DartType type = DartType.Object;

  void updateNameByNamingConventionsType() {
    String name = this.name;
    switch (jsonToDartConfig.propertyNamingConventionsType) {
      case PropertyNamingConventionsType.none:
        name = key;
        break;
      case PropertyNamingConventionsType.camelCase:
        name = camelName(key);
        break;
      case PropertyNamingConventionsType.pascal:
        name = upcaseCamelName(key);
        break;
      case PropertyNamingConventionsType.hungarianNotation:
        name = underScoreName(key);
        break;
    }

    this.name = correctName(name, dartProperty: this);
    checkError(this.name);
  }

  void updatePropertyAccessorType() {
    propertyAccessorType = jsonToDartConfig.propertyAccessorType;
  }

  void updateNullable(bool nullable) {
    this.nullable = nullable;
  }

  String getTypeString({String? className}) {
    dynamic temp = value;
    String? result;

    while (temp is List) {
      if (result == null) {
        result = 'List<{0}>';
      } else {
        result = stringFormat('List<{0}>', <String>[result]);
      }
      if (temp.isNotEmpty) {
        temp = temp.first;
      } else {
        break;
      }
    }

    if (result != null) {
      result = stringFormat(result, <String>[
        className ??
            DartHelper.getDartTypeString(
                DartHelper.converDartType(temp?.runtimeType ?? Object), this)
      ]);
    }

    return result ?? (className ?? DartHelper.getDartTypeString(type, this));
  }

  String getListCopy({String? className}) {
    // if (className == null) {
    //   return '$name$toList';
    // }
    dynamic temp = value;
    String copy = '';
    String type = '{0}';

    while (temp is List && temp.isNotEmpty) {
      if (copy == '') {
        copy =
            'e.map(($type e) => ${className != null ? 'e.copyWith()' : 'e'}).toList()';
      } else {
        type = 'List<$type>';
        copy = 'e.map(($type e)=> $copy).toList()';
      }
      if (temp.isNotEmpty) {
        temp = temp.first;
      }
    }

    //type = 'List<$type>';
    // copy =
    //     '${ConfigSetting().nullsafety && !nullable ? name : name + '?'}.map(($type e)=> $copy)$toList';
    copy = stringFormat(copy, <String>[
      className ??
          DartHelper.getDartTypeString(
                  DartHelper.converDartType(temp?.runtimeType ?? Object), this)
              .replaceAll('?', '')
    ]);
    copy = copy.replaceFirst(
      'e',
      jsonToDartConfig.nullsafety && !nullable ? name : '$name?',
    );

    if (!jsonToDartConfig.nullsafety) {
      copy = copy.replaceRange(
          copy.length - '.toList()'.length, null, '?.toList()');
    }
    return copy;
  }

  String getBaseTypeString({String? className}) {
    if (className != null) {
      return className;
    }
    dynamic temp = value;
    while (temp is List) {
      if (temp.isNotEmpty) {
        temp = temp.first;
      } else {
        break;
      }
    }

    return DartHelper.getDartTypeString(
        DartHelper.converDartType(temp?.runtimeType ?? Object), this);
  }

  String getArraySetPropertyString(String setName, String typeString,
      {String? className, String? baseType}) {
    dynamic temp = value;
    final CustomStringBuffer sb = CustomStringBuffer();
    sb.writeLine(
        " final  ${jsonToDartConfig.nullsafety ? '$typeString?' : typeString} $setName = ${DartHelper.jsonRes}['$key'] is List ? ${typeString.substring('List'.length).replaceAll('?', '')}[]: null; ");
    sb.writeLine('    if($setName!=null) {');
    final bool enableTryCatch = jsonToDartConfig.enableArrayProtection;
    final String nonNullable = jsonToDartConfig.nullsafety ? '!' : '';
    int count = 0;
    String? result;
    while (temp is List) {
      if (temp.isNotEmpty) {
        temp = temp.first;
      } else {
        temp = null;
      }
      // delete List<
      typeString = typeString.substring('List<'.length);
      // delete >
      typeString = typeString.substring(0, typeString.length - 1);

      // next is array
      if (temp != null && temp is List) {
        if (count == 0) {
          result =
              " for (final dynamic item$count in asT<List<dynamic>>(${DartHelper.jsonRes}['$key'])$nonNullable) { if (item$count != null) {final $typeString items${count + 1} = ${typeString.substring('List'.length)}[]; {} $setName.add(items${count + 1}); }}";
        } else {
          result = result!.replaceAll('{}',
              " for (final dynamic item$count in asT<List<dynamic>>(item${count - 1})$nonNullable) { if (item$count != null) {final $typeString items${count + 1} = ${typeString.substring('List'.length)}[]; {} items$count.add(items${count + 1}); }}");
        }
      }

      // next is not array
      else {
        String item = 'item${count == 0 ? '' : count.toString()}';
        String addString = '';
        if (className != null) {
          item =
              '$className.fromJson(asT<Map<String,dynamic>>($item)$nonNullable)';
        } else {
          item = DartHelper.getUseAsT(baseType, item);
        }

        if (count == 0) {
          addString = '$setName.add($item); ';
          if (enableTryCatch) {
            addString = 'tryCatch(() { $addString }); ';
          }

          result =
              " for (final dynamic item in ${DartHelper.jsonRes}['$key']$nonNullable as List<dynamic>) { if (item != null) { $addString }}";
        } else {
          addString = 'items$count.add($item); ';

          if (enableTryCatch) {
            addString = 'tryCatch(() { $addString }); ';
          }

          result = result!.replaceAll('{}',
              ' for (final dynamic item$count in asT<List<dynamic>>(item${count - 1})$nonNullable) { if (item$count != null) {$addString}}');
        }
      }

      count++;
    }

    sb.writeLine(result);
    sb.writeLine('    }\n');

    return sb.toString();
  }

  @override
  List<Object?> get props => <Object?>[
        key,
        nullable,
        propertyAccessorType,
        type,
        uid,
      ];

  @override
  String toString() {
    return 'DartProperty($key, $value, $nullable)';
  }

  SetBase<String> propertyError = CustomSet<String>();
  bool get hasPropertyError => propertyError.isNotEmpty;

  late List<DartErrorChecker> errors = <DartErrorChecker>[
    EmptyErrorChecker(this),
    ValidityChecker(this),
    DuplicatePropertyNameChecker(this),
    PropertyAndClassNameSameChecker(this),
  ];

  void checkError(String input) {
    if (!jsonToDartConfig.automaticCheck) {
      errors.first.checkError(input);
      return;
    }
    for (final DartErrorChecker error in errors) {
      error.checkError(input);
    }
  }
}
