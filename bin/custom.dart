// ignore_for_file: must_be_immutable

import 'dart:io';

import 'package:json_to_dart_library/json_to_dart_library.dart';

Future<void> main(List<String> args) async {
  registerConfig(MyJsonToDartConfig());
  registerController(MyJsonToDartController());

  DartObject? dartObject = await jsonToDartController.jsonToDartObject(
    json: '''{"data":[{"a":1}],"msg":"s","code":0}''',
  );
  var errors = jsonToDartController.getErrors();
  if (errors.isNotEmpty) {
    print('Errors found:');
    for (var error in errors) {
      print(error);
    }
    return;
  }

  if (dartObject != null) {
    var dartCode = jsonToDartController.generateDartCode(dartObject);
    File('output.dart').writeAsStringSync(dartCode!);
    print('Dart code generated successfully:');
  }
}

class MyJsonToDartConfig extends JsonToDartConfig {
  @override
  bool get addMethod => true;
  @override
  bool get enableArrayProtection => true;
  @override
  bool get enableDataProtection => true;

  @override
  int get traverseArrayCount => 99;

  @override
  bool get nullable => true;

  @override
  bool get nullsafety => true;

  // @override
  // bool get smartNullable => true;
  @override
  DartObject createDartObject({
    required String uid,
    required int depth,
    required MapEntry<String, dynamic> keyValuePair,
    required bool nullable,
    DartObject? dartObject,
  }) {
    return MyDartObject(
      uid: uid,
      depth: depth,
      keyValuePair: keyValuePair,
      nullable: nullable,
      dartObject: dartObject,
    );
  }

  @override
  DartProperty createProperty({
    required String uid,
    required int depth,
    required MapEntry<String, dynamic> keyValuePair,
    required bool nullable,
    required DartObject dartObject,
  }) {
    return MyDartProperty(
      uid: uid,
      depth: depth,
      keyValuePair: keyValuePair,
      nullable: nullable,
      dartObject: dartObject,
    );
  }
}

class MyJsonToDartController with JsonToDartControllerMixin {}

class MyDartObject extends DartObject {
  MyDartObject({
    required super.uid,
    required super.depth,
    required super.keyValuePair,
    required super.nullable,
    super.dartObject,
  });

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
          equalityStringSb.add(item.name);
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
    }

    sb.writeLine(DartHelper.classFooter);

    for (final MapEntry<String, DartObject> item in objectKeys.entries) {
      sb.writeLine(item.value.toString());
    }

    return sb.toString();
  }
}

class MyDartProperty extends DartProperty {
  MyDartProperty({
    required super.uid,
    required super.depth,
    required super.keyValuePair,
    required super.nullable,
    required DartObject super.dartObject,
  });
}
