import 'dart:io';

import 'package:json_to_dart_library/json_to_dart_library.dart';

Future<void> main(List<String> args) async {
  registerConfig(MyJsonToDartConfig());
  registerController(MyJsonToDartController());

  DartObject? dartObject = await jsonToDartController.jsonToDartObject(
    json: '''{"d":1}''',
  );
  if (dartObject != null) {
    var dartCode = jsonToDartController.generateDartCode(dartObject);
    File('output.dart').writeAsStringSync(dartCode!);
    print('Dart code generated successfully:');
  }
}

class MyJsonToDartConfig extends JsonToDartConfig {
  @override
  bool get addMethod => true;
}

class MyJsonToDartController with JsonToDartControllerMixin {
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

class MyDartObject extends DartObject {
  MyDartObject({
    required String uid,
    required int depth,
    required MapEntry<String, dynamic> keyValuePair,
    required bool nullable,
    DartObject? dartObject,
  }) : super(
          uid: uid,
          depth: depth,
          keyValuePair: keyValuePair,
          nullable: nullable,
          dartObject: dartObject,
        );
}

class MyDartProperty extends DartProperty {
  MyDartProperty({
    required String uid,
    required int depth,
    required MapEntry<String, dynamic> keyValuePair,
    required bool nullable,
    required DartObject dartObject,
  }) : super(
          uid: uid,
          depth: depth,
          keyValuePair: keyValuePair,
          nullable: nullable,
          dartObject: dartObject,
        );
}
