import 'config.dart';
import 'controller.dart';
import 'dart_property.dart';
import 'utils/camel_under_score_converter.dart';
import 'utils/dart_helper.dart';
import 'utils/enums.dart';

import 'utils/string_buffer.dart';
import 'utils/string_helper.dart';

// ignore: must_be_immutable
class DartObject extends DartProperty {
  DartObject({
    required super.uid,
    required super.keyValuePair,
    required super.depth,
    required super.nullable,
    super.dartObject,
  }) {
    properties = <DartProperty>[];
    objectKeys = <String, DartObject>{};
    jObject = (this.keyValuePair.value as Map<String, dynamic>).map(
        (String key, dynamic value) => MapEntry<String, InnerObject>(
            key,
            InnerObject(
                data: value,
                type: DartHelper.converDartType(value.runtimeType),
                nullable: DartHelper.converNullable(value))));

    final String key = this.keyValuePair.key;
    className = correctName(
      upcaseCamelName(key),
      isClassName: true,
    );
    initializeProperties();
    updateNameByNamingConventionsType();

    jsonToDartController.allObjects.add(this);
  }

  Map<String, InnerObject>? jObject;
  Map<String, InnerObject>? mergeObject;

  Map<String, InnerObject>? get outPutObject =>
      mergeObject != null ? mergeObject! : jObject;

  String _className = '';
  String get className => _className;
  set className(String value) {
    _className = value;
  }

  late List<DartProperty> properties;

  late Map<String, DartObject> objectKeys;

  void decDepth() {
    depth -= 1;
    for (final DartObject obj in objectKeys.values) {
      obj.decDepth();
    }
  }

  void initializeProperties() {
    properties.clear();
    objectKeys.clear();
    if (outPutObject != null && outPutObject!.isNotEmpty) {
      for (final MapEntry<String, InnerObject> item in outPutObject!.entries) {
        initializePropertyItem(item, depth);
      }
      orderPropeties();
    }
  }

  void initializePropertyItem(MapEntry<String, InnerObject> item, int depth,
      {bool addProperty = true}) {
    if (item.value.data is Map &&
        (item.value.data as Map<String, dynamic>).isNotEmpty) {
      if (objectKeys.containsKey(item.key)) {
        final DartObject temp = objectKeys[item.key]!;
        temp.merge((item.value.data as Map<String, dynamic>).map(
            (String key, dynamic value) => MapEntry<String, InnerObject>(
                key,
                InnerObject(
                    data: value,
                    type: DartHelper.converDartType(value.runtimeType),
                    nullable: DartHelper.converNullable(value)))));
        objectKeys[item.key] = temp;
      } else {
        final DartObject temp = jsonToDartConfig.createDartObject(
          uid: uid + '_' + item.key,
          keyValuePair: MapEntry<String, dynamic>(item.key, item.value.data),
          nullable: item.value.nullable,
          depth: depth + 1,
          dartObject: this,
        );
        if (addProperty) {
          properties.add(temp);
        }
        objectKeys[item.key] = temp;
      }
    } else if (item.value.data is List) {
      if (addProperty) {
        properties.add(jsonToDartConfig.createProperty(
          uid: uid,
          keyValuePair: MapEntry<String, dynamic>(item.key, item.value.data),
          nullable: item.value.nullable,
          depth: depth,
          dartObject: this,
        ));
      }
      final List<dynamic> array = item.value.data as List<dynamic>;
      if (array.isNotEmpty) {
        int count = jsonToDartConfig.traverseArrayCount;
        if (count == 99) {
          count = array.length;
        }
        final Iterable<dynamic> cutArray = array.take(count);
        for (final dynamic arrayItem in cutArray) {
          initializePropertyItem(
              MapEntry<String, InnerObject>(
                  item.key,
                  InnerObject(
                      data: arrayItem,
                      type: DartHelper.converDartType(arrayItem.runtimeType),
                      nullable: DartHelper.converNullable(value) &&
                          jsonToDartConfig.smartNullable)),
              depth,
              addProperty: false);
        }
      }
    } else {
      if (addProperty) {
        properties.add(jsonToDartConfig.createProperty(
          uid: uid,
          keyValuePair: MapEntry<String, dynamic>(item.key, item.value.data),
          nullable: item.value.nullable,
          depth: depth,
          dartObject: this,
        ));
      }
    }
  }

  void merge(Map<String, InnerObject>? other) {
    bool needInitialize = false;
    if (jObject != null) {
      mergeObject ??= <String, InnerObject>{};

      for (final MapEntry<String, InnerObject> item in jObject!.entries) {
        if (!mergeObject!.containsKey(item.key)) {
          needInitialize = true;
          mergeObject![item.key] = item.value;
        }
      }

      if (other != null) {
        mergeObject ??= <String, InnerObject>{};

        if (jsonToDartConfig.smartNullable) {
          for (final MapEntry<String, InnerObject> existObject
              in mergeObject!.entries) {
            if (!other.containsKey(existObject.key)) {
              final InnerObject newObject = InnerObject(
                  data: existObject.value.data,
                  type: existObject.value.type,
                  nullable: true);
              mergeObject![existObject.key] = newObject;
              needInitialize = true;
            }
          }
        }

        for (final MapEntry<String, InnerObject> item in other.entries) {
          if (!mergeObject!.containsKey(item.key)) {
            needInitialize = true;
            mergeObject![item.key] = InnerObject(
                data: item.value.data, type: item.value.type, nullable: true);
          } else {
            InnerObject existObject = mergeObject![item.key]!;
            if ((existObject.isNull && !item.value.isNull) ||
                (!existObject.isNull && item.value.isNull) ||
                existObject.nullable != item.value.nullable) {
              existObject = InnerObject(
                  data: item.value.data ?? existObject.data,
                  type: item.value.type != DartType.Null
                      ? item.value.type
                      : existObject.type,
                  nullable: (existObject.nullable || item.value.nullable) &&
                      jsonToDartConfig.smartNullable);
              mergeObject![item.key] = existObject;
              needInitialize = true;
            } else if (existObject.isList &&
                item.value.isList &&
                ((existObject.isEmpty || item.value.isEmpty) ||
                    // make sure Object will be merge
                    (existObject.isObject || item.value.isObject))) {
              existObject = InnerObject(
                data: (item.value.data as List<dynamic>)
                  ..addAll(existObject.data as List<dynamic>),
                type: item.value.type,
                nullable: false,
              );
              mergeObject![item.key] = existObject;
              needInitialize = true;
            }
          }
        }
        if (needInitialize) {
          initializeProperties();
        }
      }
    }
  }

  @override
  void updateNameByNamingConventionsType() {
    super.updateNameByNamingConventionsType();

    for (final DartProperty item in properties) {
      item.updateNameByNamingConventionsType();
    }

    for (final MapEntry<String, DartObject> item in objectKeys.entries) {
      item.value.updateNameByNamingConventionsType();
    }
  }

  @override
  void updatePropertyAccessorType() {
    super.updatePropertyAccessorType();

    for (final DartProperty item in properties) {
      item.updatePropertyAccessorType();
    }

    for (final MapEntry<String, DartObject> item in objectKeys.entries) {
      item.value.updatePropertyAccessorType();
    }
  }

  @override
  void updateNullable(bool nullable) {
    super.updateNullable(nullable);
    for (final DartProperty item in properties) {
      item.updateNullable(nullable);
    }

    for (final MapEntry<String, DartObject> item in objectKeys.entries) {
      item.value.updateNullable(nullable);
    }
  }

  @override
  String getTypeString({String? className}) {
    return this.className;
  }

  void orderPropeties() {
    final PropertyNameSortingType sortingType =
        jsonToDartConfig.propertyNameSortingType;
    if (sortingType != PropertyNameSortingType.none) {
      if (sortingType == PropertyNameSortingType.ascending) {
        properties.sort((DartProperty left, DartProperty right) =>
            left.name.compareTo(right.name));
      } else {
        properties.sort((DartProperty left, DartProperty right) =>
            right.name.compareTo(left.name));
      }
    }

    if (outPutObject != null) {
      for (final MapEntry<String, DartObject> item in objectKeys.entries) {
        item.value.orderPropeties();
      }
    }
  }

  @override
  String toString() {
    if (jsonToDartController.printedObjects.contains(this)) {
      return '';
    }
    jsonToDartController.printedObjects.add(this);

    orderPropeties();

    final CustomStringBuffer sb = CustomStringBuffer();

    sb.writeLine(stringFormat(DartHelper.classHeader, <String>[
      className,
      if (jsonToDartConfig.equalityMethodType == EqualityMethodType.equatable)
        'with EquatableMixin'
      else
        '',
    ]));

    if (properties.isNotEmpty) {
      final CustomStringBuffer factorySb = CustomStringBuffer();
      final CustomStringBuffer factorySb1 = CustomStringBuffer();
      final CustomStringBuffer propertySb = CustomStringBuffer();
      //StringBuffer propertySb1 = StringBuffer();
      final CustomStringBuffer fromJsonSb = CustomStringBuffer();
      //Array
      final CustomStringBuffer fromJsonSb1 = CustomStringBuffer();
      final CustomStringBuffer toJsonSb = CustomStringBuffer();

      final CustomStringBuffer copyWithParameterSb = CustomStringBuffer();
      final CustomStringBuffer copyWithBodySb = CustomStringBuffer();

      final List<String> equalityStringSb = <String>[];
      final List<String> equalityStringSb1 = <String>[];
      final bool isAllFinalProperties = !properties.any(
          (DartProperty element) =>
              element.propertyAccessorType != PropertyAccessorType.final_);

      factorySb.writeLine(stringFormat(DartHelper.factoryStringHeader,
          <String>['${isAllFinalProperties ? 'const' : ''} $className']));

      toJsonSb.writeLine(DartHelper.toJsonHeader);

      for (final DartProperty item in properties) {
        final String lowName =
            item.name.substring(0, 1).toLowerCase() + item.name.substring(1);
        final String name = item.name;
        String? className;
        String? typeString;
        final String setName = DartHelper.getSetPropertyString(item);
        String setString = '';
        final String fss = DartHelper.factorySetString(
          item.propertyAccessorType,
          (!jsonToDartConfig.nullsafety) ||
              (jsonToDartConfig.nullsafety && item.nullable),
        );
        final bool isGetSet = fss.startsWith('{');

        String copyProperty = item.name;

        if (item is DartObject) {
          className = item.className;

          setString = stringFormat(DartHelper.setObjectProperty, <String>[
            item.name,
            item.key,
            className,
            if (jsonToDartConfig.nullsafety && item.nullable)
              '${DartHelper.jsonRes}[\'${item.key}\']==null?null:'
            else
              '',
            if (jsonToDartConfig.nullsafety) '!' else ''
          ]);
          typeString = className;
          if (jsonToDartConfig.nullsafety && item.nullable) {
            typeString += '?';
          }

          if (jsonToDartConfig.addCopyMethod && jsonToDartConfig.deepCopy) {
            if (!jsonToDartConfig.nullsafety || item.nullable) {
              copyProperty += '?';
            }
            copyProperty += '.copyWith()';
          }
        } else if (item.value is List) {
          if (objectKeys.containsKey(item.key)) {
            className = objectKeys[item.key]!.className;
          }
          typeString = item.getTypeString(className: className);

          typeString = typeString.replaceAll('?', '');

          fromJsonSb1.writeLine(item.getArraySetPropertyString(
            lowName,
            typeString,
            className: className,
            baseType: item
                .getBaseTypeString(className: className)
                .replaceAll('?', ''),
          ));

          setString = ' ${item.name}:$lowName';

          if (jsonToDartConfig.nullsafety) {
            if (item.nullable) {
              typeString += '?';
            } else {
              setString += '!';
            }
          }
          setString += ',';
          if (jsonToDartConfig.addCopyMethod && jsonToDartConfig.deepCopy) {
            copyProperty = item.getListCopy(className: className);
          }
        } else {
          setString = DartHelper.setProperty(item.name, item, this.className);
          typeString = DartHelper.getDartTypeString(item.type, item);
        }

        if (isGetSet) {
          factorySb.writeLine(stringFormat(fss, <String>[typeString, lowName]));
          if (factorySb1.length == 0) {
            factorySb1.write('}):');
          } else {
            factorySb1.write(',');
          }
          factorySb1.write('$setName=$lowName');
        } else {
          factorySb.writeLine(stringFormat(fss, <String>[item.name]));
        }

        propertySb.writeLine(stringFormat(
            DartHelper.propertyS(item.propertyAccessorType),
            <String>[typeString, name, lowName]));
        fromJsonSb.writeLine(setString);

        // String setNameTemp = setName;

        // if (className != null) {
        //   String toJson = '=> e.toJson()';
        //   dynamic value = item.value;
        //   String typeString = className;
        //   while (value is List) {
        //     toJson = '=> e.map(($typeString e) $toJson)';
        //     typeString = 'List<$typeString>';
        //     if (value.isNotEmpty) {
        //       value = value.first;
        //     } else {
        //       break;
        //     }
        //   }
        //   toJson = toJson.replaceFirst('=>', '');
        //   toJson = toJson.replaceFirst('e', '');
        //   toJson = toJson.trim();

        //   final bool nonNullAble = ConfigSetting().nullsafety && !item.nullable;
        //   setNameTemp += '${nonNullAble ? '' : '?'}$toJson';
        // }

        toJsonSb.writeLine(stringFormat(DartHelper.toJsonSetString, <String>[
          item.key,
          setName,
        ]));

        if (jsonToDartConfig.addCopyMethod) {
          if (copyProperty.isEmpty) {
            copyProperty = item.name;
          }
          copyWithBodySb
              .writeLine('${item.name}: ${item.name}?? $copyProperty,');
          copyWithParameterSb.writeLine(
              '$typeString${typeString.contains('?') ? '' : '?'}${item.name},');
        }

        if (jsonToDartConfig.equalityMethodType ==
            EqualityMethodType.official) {
          equalityStringSb.add('${item.name}.hashCode');
          equalityStringSb1.add('${item.name} == other.${item.name}');
        } else if (jsonToDartConfig.equalityMethodType ==
            EqualityMethodType.equatable) {
          equalityStringSb.add('${item.name}');
        }
      }

      if (factorySb1.length == 0) {
        factorySb.writeLine(DartHelper.factoryStringFooter);
      } else {
        factorySb1.write(';');
        factorySb.write(factorySb1.toString());
      }

      String fromJson = '';
      if (fromJsonSb1.length != 0) {
        fromJson = stringFormat(
                jsonToDartConfig.nullsafety
                    ? DartHelper.fromJsonHeader1NullSafety
                    : DartHelper.fromJsonHeader1,
                <String>[className]) +
            fromJsonSb1.toString() +
            stringFormat(DartHelper.fromJsonFooter1,
                <String>[className, fromJsonSb.toString()]);
      } else {
        fromJson = stringFormat(
                jsonToDartConfig.nullsafety
                    ? DartHelper.fromJsonHeaderNullSafety
                    : DartHelper.fromJsonHeader,
                <String>[className]) +
            fromJsonSb.toString() +
            DartHelper.fromJsonFooter;
      }

      //fromJsonSb.AppendLine(DartHelper.FromJsonFooter);

      toJsonSb.writeLine(DartHelper.toJsonFooter);
      sb.writeLine(factorySb.toString());
      sb.writeLine(fromJson);
      sb.writeLine(propertySb.toString());
      sb.writeLine(DartHelper.classToString);
      sb.writeLine(toJsonSb.toString());

      if (jsonToDartConfig.addCopyMethod) {
        sb.writeLine(stringFormat(DartHelper.copyMethodString, <String>[
          className,
          copyWithBodySb.toString(),
          '{${copyWithParameterSb.toString()}}',
        ]));
      }

      if (jsonToDartConfig.equalityMethodType != EqualityMethodType.none) {
        switch (jsonToDartConfig.equalityMethodType) {
          case EqualityMethodType.none:
            break;
          case EqualityMethodType.official:
            sb.writeLine(
                stringFormat(DartHelper.officialEqualityString, <String>[
              equalityStringSb.join('^'),
              className,
              equalityStringSb1.join('&&'),
            ]));
            break;
          case EqualityMethodType.equatable:
            sb.writeLine(
                stringFormat(DartHelper.equatableEqualityString, <String>[
              equalityStringSb.join(','),
            ]));
            break;
        }
      }
      // sb.writeLine(stringFormat(DartHelper.classToClone,
      //     <String>[className, if (ConfigSetting().nullsafety) '!' else '']));
    }

    sb.writeLine(DartHelper.classFooter);

    for (final MapEntry<String, DartObject> item in objectKeys.entries) {
      sb.writeLine(item.value.toString());
    }

    return sb.toString();
  }

  @override
  List<Object?> get props => <Object?>[
        key,
        uid,
      ];
}

class InnerObject {
  InnerObject({
    required this.data,
    required this.type,
    required this.nullable,
  });
  final dynamic data;
  final DartType type;
  // data is null ?
  final bool nullable;

  bool get isList => data is List;
  bool get isEmpty => isList && (data as List<dynamic>).isEmpty;
  bool get isNull => type.isNull;
  bool get isObject => type == DartType.Object;
}

class CheckError implements Exception {
  CheckError(this.msg);
  final String msg;
}
