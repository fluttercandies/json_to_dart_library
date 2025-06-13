import 'package:dart_style/dart_style.dart';
import 'package:get_it/get_it.dart';
import 'package:json_to_dart_library/json_to_dart_library.dart';

/// Abstract class that provides configuration options for converting JSON to Dart models.
abstract class JsonToDartConfig {
  /// Whether to include a method that converts the object to JSON.
  bool get addMethod => true;

  /// Enable protection when parsing array values.
  bool get enableArrayProtection => false;

  /// Enable protection when parsing data (e.g., null or invalid formats).
  bool get enableDataProtection => false;

  /// Custom header comment to be added at the top of each generated Dart file.
  String get fileHeaderInfo => '';

  /// Number of elements to traverse when inspecting arrays.
  int get traverseArrayCount => 1;

  /// Naming convention for property names in generated classes.
  PropertyNamingConventionsType get propertyNamingConventionsType =>
      PropertyNamingConventionsType.camelCase;

  /// Accessor style for the class properties (none, getter/setter, etc.).
  PropertyAccessorType get propertyAccessorType => PropertyAccessorType.none;

  /// Sorting type for property names in the generated class.
  PropertyNameSortingType get propertyNameSortingType =>
      PropertyNameSortingType.none;

  /// Whether to enable Dart null safety.
  bool get nullsafety => true;

  /// Whether properties can be nullable.
  bool get nullable => true;

  /// Whether to apply smart nullability checks.
  bool get smartNullable => false;

  /// Whether to include a `copyWith` method in the generated classes.
  bool get addCopyMethod => false;

  /// Whether to automatically check for issues during generation.
  bool get automaticCheck => true;

  /// Whether to display a result dialog after conversion.
  bool get showResultDialog => true;

  /// Defines how equality (`==`) and `hashCode` are generated.
  EqualityMethodType get equalityMethodType => EqualityMethodType.official;

  /// Whether to support deep copying of objects.
  bool get deepCopy => false;

  /// The formatter to apply to generated Dart code (e.g., for indentation and styling).
  DartFormatter? get formatter => DartFormatter(
        languageVersion: DartFormatter.latestLanguageVersion,
      );

  /// Creates a new DartProperty based on key-value input and context.
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

  /// Creates a new DartObject based on key-value input and context.
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

  /// Assertion message when a property name is empty.
  String propertyNameAssert(String uid) {
    return "$uid: property name is empty";
  }

  /// Assertion message when a class name is empty.
  String classNameAssert(String uid) {
    return "$uid: class name is empty";
  }

  /// Error message: property name cannot be the same as the class name.
  String get propertyCantSameAsClassName =>
      'property can\'t the same as Class name';

  /// Error message for keyword conflict.
  String keywordCheckFailed(Object name) {
    return '\'$name\' is a key word!';
  }

  /// Error message: property name cannot be the same as a type.
  String get propertyCantSameAsType => 'property can\'t the same as Type';

  /// Error message for illegal characters in names.
  String get containsIllegalCharacters => 'contains illegal characters';

  /// Error message for duplicate property names.
  String get duplicateProperties => 'There are duplicate properties';

  /// Error message for duplicate class names.
  String get duplicateClasses => 'There are duplicate classes';
}

/// Default implementation of [JsonToDartConfig] with default values.
class _DefaultJsonToDartConfig extends JsonToDartConfig {}

/// Internal instance of default config.
_DefaultJsonToDartConfig _defaultJsonToDartConfig = _DefaultJsonToDartConfig();

/// Registers a custom [JsonToDartConfig] into the GetIt dependency injection container.
void registerConfig(JsonToDartConfig config) {
  GetIt.instance.registerSingleton<JsonToDartConfig>(config);
}

/// Gets the registered [JsonToDartConfig], or falls back to default if none is registered.
JsonToDartConfig get jsonToDartConfig =>
    GetIt.instance.isRegistered<JsonToDartConfig>()
        ? GetIt.instance.get<JsonToDartConfig>()
        : _defaultJsonToDartConfig;
