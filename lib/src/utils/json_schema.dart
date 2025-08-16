import 'package:json_schema/json_schema.dart';

/// A utility class for checking if a JSON map is a valid JSON Schema.
class JsonSchemaHelper {
  /// Checks if the provided JSON map is a valid JSON Schema.
  static bool isJsonSchema(Map<dynamic, dynamic> json) {
    if (json.containsKey(r'$schema') &&
        json[r'$schema'] is String &&
        json[r'$schema'].toString().contains('json-schema')) {
      return true;
    }

    // final schemaKeys = {'type', 'properties', 'items', 'allOf', 'anyOf', 'oneOf', r'$ref'};
    // if (json.keys.any(schemaKeys.contains)) {
    //   return true;
    // }

    return false;
  }

  /// Creates a JSON object based on the provided JSON Schema.
  static dynamic createJsonWithJsonSchema(JsonSchema schema) {
    if (schema.defaultValue != null) return schema.defaultValue;

    if (schema.enumValues != null && schema.enumValues!.isNotEmpty) {
      return schema.enumValues!.first;
    }

    switch (schema.type?.toString()) {
      case 'object':
        final result = <String, dynamic>{};
        schema.properties.forEach((key, propSchema) {
          result[key] = createJsonWithJsonSchema(propSchema);
        });
        return result;

      case 'array':
        if (schema.items != null) {
          return [createJsonWithJsonSchema(schema.items!)];
        }
        return [];

      case 'string':
        if (schema.format == 'date-time') {
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
        if (schema.anyOf.isNotEmpty) {
          return createJsonWithJsonSchema(schema.anyOf.first);
        }
        if (schema.oneOf.isNotEmpty) {
          return createJsonWithJsonSchema(schema.oneOf.first);
        }
        if (schema.allOf.isNotEmpty) {
          return createJsonWithJsonSchema(schema.allOf.first);
        }
        return null;
    }
  }
}
