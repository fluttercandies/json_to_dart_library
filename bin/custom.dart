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

  @override
  bool get addCopyMethod => true;

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
    return super.toString();
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
