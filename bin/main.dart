import 'dart:io';

import 'package:json_to_dart_library/json_to_dart_library.dart';

Future<void> main(List<String> args) async {
  DartObject? dartObject = await jsonToDartController.jsonToDartObject(
    json: '''{"d":1}''',
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
