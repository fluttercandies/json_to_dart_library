## The library to convert json to dart code

The library for https://github.com/fluttercandies/JsonToDart/Flutter/json_to_dart

## simple used

```dart
Future<void> main(List<String> args) async {
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

```
 
## custom

you can define the config and DartObject/DartProperty to generate your own dart style code.

you can see bin/custom.dart to see more info.
