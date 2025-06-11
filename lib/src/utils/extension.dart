extension StringE on String? {
  String get uid => '$this${DateTime.now().microsecondsSinceEpoch}';

  bool get isNullOrEmpty => this == null || this!.isEmpty;
}
