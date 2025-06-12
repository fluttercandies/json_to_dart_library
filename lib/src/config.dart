import 'package:dart_style/dart_style.dart';
import 'package:get_it/get_it.dart';
import 'package:json_to_dart_library/json_to_dart_library.dart';
import 'package:json_to_dart_library/src/utils/enums.dart';

abstract class JsonToDartConfig {
  /// whether to add a method to convert the object to JSON
  bool get addMethod => true;

  bool get enableArrayProtection => false;

  bool get enableDataProtection => false;

  String get fileHeaderInfo => '';

  int get traverseArrayCount => 1;

  PropertyNamingConventionsType get propertyNamingConventionsType =>
      PropertyNamingConventionsType.camelCase;

  PropertyAccessorType get propertyAccessorType => PropertyAccessorType.none;

  PropertyNameSortingType get propertyNameSortingType =>
      PropertyNameSortingType.none;

  bool get nullsafety => true;

  bool get nullable => true;

  bool get smartNullable => false;

  bool get addCopyMethod => false;

  bool get automaticCheck => true;

  bool get showResultDialog => true;

  EqualityMethodType get equalityMethodType => EqualityMethodType.official;

  bool get deepCopy => false;

  DartFormatter get formatter => DartFormatter(
        languageVersion: DartFormatter.latestLanguageVersion,
      );

  DartProperty createProperty({
    required String uid,
    required int depth,
    required MapEntry<String, dynamic> keyValuePair,
    required bool nullable,
    required DartObject dartObject,
  }) {
    return DartProperty(
      uid: uid,
      keyValuePair: keyValuePair,
      nullable: nullable,
      depth: depth,
      dartObject: dartObject,
    );
  }

  DartObject createDartObject({
    required String uid,
    required int depth,
    required MapEntry<String, dynamic> keyValuePair,
    required bool nullable,
    DartObject? dartObject,
  }) {
    return DartObject(
      uid: uid,
      keyValuePair: keyValuePair,
      nullable: nullable,
      depth: depth,
      dartObject: dartObject,
    );
  }

  String propertyNameAssert(String uid) {
    return "$uid: property name is empty";
  }

  String classNameAssert(String uid) {
    return "$uid: class name is empty";
  }

  String get propertyCantSameAsClassName =>
      'property can\'t the same as Class name';

  String keywordCheckFailed(Object name) {
    return '\'$name\' is a key word!';
  }

  String get propertyCantSameAsType => 'property can\'t the same as Type';

  String get containsIllegalCharacters => 'contains illegal characters';

  String get duplicateProperties => 'There are duplicate properties';

  String get duplicateClasses => 'There are duplicate classes';
}

class _DefaultJsonToDartConfig extends JsonToDartConfig {}

_DefaultJsonToDartConfig _defaultJsonToDartConfig = _DefaultJsonToDartConfig();
void registerConfig(JsonToDartConfig config) {
  GetIt.instance.registerSingleton<JsonToDartConfig>(config);
}

JsonToDartConfig get jsonToDartConfig =>
    GetIt.instance.isRegistered<JsonToDartConfig>()
        ? GetIt.instance.get<JsonToDartConfig>()
        : _defaultJsonToDartConfig;
