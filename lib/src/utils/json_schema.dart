import 'package:json_schema/json_schema.dart';
import 'package:json_to_dart_library/src/utils/camel_under_score_converter.dart';

/// Utility class for working with JSON Schema objects.
/// Provides methods to check schema validity, generate JSON from schema, and extract comments.

/// A utility class for checking if a JSON map is a valid JSON Schema.
class JsonSchemaHelper {
  /// Checks if the provided JSON map is a valid JSON Schema.
  ///
  /// Returns true if the map contains a `$schema` key with a value containing 'json-schema'.
  static bool isJsonSchema(Map<dynamic, dynamic> json) {
    if (json.containsKey(r'$schema') &&
        json[r'$schema'] is String &&
        json[r'$schema'].toString().contains('json-schema')) {
      return true;
    }

    // Uncomment below to check for other schema keys if needed.
    // final schemaKeys = {'type', 'properties', 'items', 'allOf', 'anyOf', 'oneOf', r'$ref'};
    // if (json.keys.any(schemaKeys.contains)) {
    //   return true;
    // }

    return false;
  }

  /// Creates a JSON object based on the provided JSON Schema.
  ///
  /// Delegates to the [createJson] method of the [JsonSchema] instance.
  static dynamic createJsonWithJsonSchema(JsonSchema schema) {
    return schema.createJson();
  }
}

/// Extension methods for [JsonSchema] to provide comment extraction and utility getters.
extension JsonSchemaE on JsonSchema {
  /// Builds a Dart doc comment string from the schema's description, examples, and default value.
  /// Each line is prefixed with '///'.
  String getComment() {
    List<String> comments = [];
    if (description != null && description!.isNotEmpty) {
      comments.add(description!);
    }
    var examples = this
        .examples
        .where((e) => e != null)
        .map((e) => e.toString())
        .where((e) => e.isNotEmpty)
        .toList();
    if (examples.isNotEmpty) {
      comments.add('Examples: ${examples.join(', ')}');
    }
    if (defaultValue != null && defaultValue.toString().isNotEmpty) {
      comments.add('Default: $defaultValue');
    }
    if (comments.isEmpty) {
      return '';
    }

    return comments.join('\n').split('\n').map((e) => '/// $e').join('\n');
  }

  /// Returns true if the schema type is object.
  bool get isObject => type == SchemaType.object;

  /// Returns true if the schema type is array.
  bool get isArray => type == SchemaType.array;

  /// Returns true if the schema type is string.
  bool get isString => type == SchemaType.string;

  /// Returns true if the schema type is boolean.
  bool get isBoolean => type == SchemaType.boolean;

  /// Returns true if the schema type is integer.
  bool get isInteger => type == SchemaType.integer;

  /// Returns true if the schema type is number.
  bool get isNumber => type == SchemaType.number;

  /// Returns true if the schema type is null.
  bool get isNullValue => type == SchemaType.nullValue;

  // Helper for type matching (commented out).
  // static bool _typeMatch(
  //     SchemaType? type, JsonSchema schema, dynamic instance) {
  //   if (type == SchemaType.object) {
  //     return instance is Map;
  //   } else if (type == SchemaType.string) {
  //     return instance is String;
  //   } else if (type == SchemaType.integer) {
  //     return instance is int ||
  //         (schema.schemaVersion >= SchemaVersion.draft6 &&
  //             instance is num &&
  //             instance.remainder(1) == 0);
  //   } else if (type == SchemaType.number) {
  //     return instance is num;
  //   } else if (type == SchemaType.array) {
  //     return instance is List;
  //   } else if (type == SchemaType.boolean) {
  //     return instance is bool;
  //   } else if (type == SchemaType.nullValue) {
  //     return instance == null;
  //   }
  //   return false;
  // }

  /// Creates a JSON object based on the provided JSON Schema.
  ///
  /// Uses default value, enum, or type to generate a sample JSON value.
  dynamic createJson() {
    if (defaultValue != null) return defaultValue;

    if (enumValues != null && enumValues!.isNotEmpty) {
      return enumValues!.first;
    }

    switch (type?.toString()) {
      case 'object':
        final result = <String, dynamic>{};
        properties.forEach((key, propSchema) {
          result[key] = propSchema.createJson();
        });
        return result;

      case 'array':
        if (items != null) {
          return [items!.createJson()];
        }
        return [];

      case 'string':
        if (format == 'date-time') {
          return DateTime.now().toIso8601String();
        }
        return '';

      case 'integer':
        return 0;
      case 'number':
        return 0.1;

      case 'boolean':
        return false;

      default:
        if (anyOf.isNotEmpty) {
          return anyOf.first.createJson();
        }
        if (oneOf.isNotEmpty) {
          return oneOf.first.createJson();
        }
        if (allOf.isNotEmpty) {
          return allOf.first.createJson();
        }
        return null;
    }
  }

  /// Recursively yields this schema and all nested property/item schemas.
  Iterable<JsonSchema> getAllJsonSchema() sync* {
    yield this;

    for (final prop in properties.values) {
      yield* prop.getAllJsonSchema();
    }

    if (items != null) {
      yield* items!.getAllJsonSchema();
    }
  }

  /// Recursively yields only object-type schemas.
  Iterable<JsonSchema> getAllObjects() sync* {
    if (isObject) {
      yield this;
    }

    for (final prop in properties.values) {
      yield* prop.getAllObjects();
    }

    if (items != null) {
      yield* items!.getAllObjects();
    }
  }
}

/// Extension methods for [SchemaType] to provide Dart type conversion.
extension SchemaTypeE on SchemaType {
  /// Returns the Dart type as a string based on the schema type.
  String get dartType {
    switch (this) {
      case SchemaType.object:
        return 'Map<String, dynamic>';
      case SchemaType.array:
        return 'List<dynamic>';
      case SchemaType.string:
        return 'String';
      case SchemaType.boolean:
        return 'bool';
      case SchemaType.integer:
        return 'int';
      case SchemaType.number:
        return 'double';
      case SchemaType.nullValue:
        return 'null';
      default:
        return 'dynamic'; // Fallback for unsupported types
    }
  }
}
