// ignore_for_file: constant_identifier_names

enum DartType {
  String,
  int,
  Object,
  bool,
  double,
  Null,
}

enum PropertyAccessorType {
  /// default
  none,

  /// final readonly

  final_,
}

enum PropertyNamingConventionsType {
  /// default

  none,

  /// camelCase

  camelCase,

  /// pascal

  pascal,

  /// hungarianNotation

  hungarianNotation
}

enum PropertyNameSortingType {
  none,
  ascending,
  descending,
}

enum EqualityMethodType {
  none,
  official,
  equatable,
}

extension DartTypeE on DartType {
  String get text =>
      this == DartType.Null ? 'Object' : toString().replaceAll('DartType.', '');

  bool get isNull => this == DartType.Null;
}
