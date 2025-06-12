import 'dart:collection';

import 'package:dartx/dartx.dart';
import 'package:equatable/equatable.dart';

import 'package:json_to_dart_library/json_to_dart_library.dart';

enum DartErrorType {
  classNameEmpty,
  propertyNameEmpty,
  keyword,
}

class DartError extends Equatable {
  const DartError(this.content);
  final String content;
  @override
  List<Object?> get props => <Object>[content];
}

abstract class DartErrorChecker {
  DartErrorChecker(this.property);
  final DartProperty property;
  void checkError(String input);
}

class EmptyErrorChecker extends DartErrorChecker {
  EmptyErrorChecker(DartProperty property) : super(property);

  @override
  void checkError(String input) {
    late String errorInfo;
    late SetBase<String> out;
    // property change
    if (input == property.name) {
      errorInfo = jsonToDartConfig.propertyNameAssert(property.uid);
      out = property.propertyError;
    }
    // class name change
    else {
      final DartObject object = property as DartObject;
      errorInfo = jsonToDartConfig.classNameAssert(object.uid);
      out = object.classError;
    }

    if (input.isEmpty) {
      out.add(errorInfo);
    } else {
      out.remove(errorInfo);
    }
  }
}

class ValidityChecker extends DartErrorChecker {
  ValidityChecker(DartProperty property) : super(property);

  @override
  void checkError(String input) {
    String? errorInfo;
    late SetBase<String> out;
    final String value = input;
    // property change
    if (input == property.name) {
      if (propertyKeyWord.contains(value)) {
        errorInfo = jsonToDartConfig.keywordCheckFailed(value);
      }
      // PropertyAndClassNameSameChecker has do this
      // else if (property is DartObject &&
      //     (property as DartObject).className.value == value) {
      //   errorInfo = appLocalizations.propertyCantSameAsClassName;
      // }
      else if (property.value is List) {
        if (value == 'List') {
          errorInfo = jsonToDartConfig.propertyCantSameAsType;
        } else if (property.getTypeString().contains('<$value>')) {
          errorInfo = jsonToDartConfig.propertyCantSameAsType;
        }
      } else if (property.getBaseTypeString() == value) {
        errorInfo = jsonToDartConfig.propertyCantSameAsType;
      }
      out = property.propertyError;
    }
    // class name change
    else {
      final DartObject object = property as DartObject;
      if (classNameKeyWord.contains(value)) {
        errorInfo = jsonToDartConfig.keywordCheckFailed(value);
      }
      out = object.classError;
    }

    if (errorInfo == null) {
      String temp = '';
      for (int i = 0; i < value.length; i++) {
        final String char = value[i];
        if (char == '_' ||
            (temp.isEmpty ? RegExp('[a-zA-Z]') : RegExp('[a-zA-Z0-9]'))
                .hasMatch(char)) {
          temp += char;
        } else {
          errorInfo = jsonToDartConfig.containsIllegalCharacters;
          break;
        }
      }
    }

    out.removeWhere((String element) => element.startsWith('vcf: '));
    if (errorInfo != null) {
      out.add('vcf: ' + errorInfo);
    }
  }
}

class DuplicateClassChecker extends DartErrorChecker {
  DuplicateClassChecker(DartObject property) : super(property);

  DartObject get dartObject => property as DartObject;

  @override
  void checkError(String input) {
    if (input != dartObject.className) {
      return;
    }

    final Map<String, List<DartObject>> groupObjects = jsonToDartController
        .allObjects
        .groupBy((DartObject element) => element.className);
    final String errorInfo = jsonToDartConfig.duplicateClasses;
    for (final MapEntry<String, List<DartObject>> item
        in groupObjects.entries) {
      for (final DartObject element in item.value) {
        if (item.value.length > 1) {
          element.classError.add(errorInfo);
        } else {
          element.classError.remove(errorInfo);
        }
      }
    }
  }
}

class DuplicatePropertyNameChecker extends DartErrorChecker {
  DuplicatePropertyNameChecker(DartProperty property) : super(property);
  @override
  void checkError(String input) {
    if (property.dartObject == null || input != property.name) {
      return;
    }

    final DartObject dartObject = property.dartObject!;
    final String errorInfo = jsonToDartConfig.duplicateProperties;
    final Map<String, List<DartProperty>> groupProperies =
        dartObject.properties.groupBy((DartProperty element) => element.name);

    for (final MapEntry<String, List<DartProperty>> item
        in groupProperies.entries) {
      for (final DartProperty element in item.value) {
        if (item.value.length > 1) {
          element.propertyError.add(errorInfo);
        } else {
          element.propertyError.remove(errorInfo);
        }
      }
    }
  }
}

class PropertyAndClassNameSameChecker extends DartErrorChecker {
  PropertyAndClassNameSameChecker(DartProperty property) : super(property);
  @override
  void checkError(String input) {
    final String errorInfo = jsonToDartConfig.propertyCantSameAsClassName;
    final Set<DartProperty> hasErrorProperites = <DartProperty>{};
    for (final DartObject dartObject in jsonToDartController.allObjects) {
      final Iterable<DartProperty> list =
          jsonToDartController.allProperties.where((DartProperty element) {
        final bool same = element.name == dartObject.className;
        if (same) {
          hasErrorProperites.add(element);
          element.propertyError.add(errorInfo);
        }
        return same;
      });

      if (list.isNotEmpty) {
        dartObject.classError.add(errorInfo);
      } else {
        dartObject.classError.remove(errorInfo);
      }
    }

    for (final DartProperty item in jsonToDartController.allProperties) {
      if (!hasErrorProperites.contains(item)) {
        item.propertyError.remove(errorInfo);
      }
    }
  }
}
