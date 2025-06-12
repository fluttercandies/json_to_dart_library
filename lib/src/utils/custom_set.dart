import 'dart:collection';

class CustomSet<E> extends SetBase<E> {
  final Set<E> _delegate;

  CustomSet() : _delegate = Set();

  CustomSet.withEquality({
    bool Function(E, E)? equals,
    int Function(E)? hashCode,
  }) : _delegate = LinkedHashSet(equals: equals, hashCode: hashCode);

  @override
  bool add(E value) => _delegate.add(value);

  @override
  bool contains(Object? element) => _delegate.contains(element);

  @override
  E? lookup(Object? element) => _delegate.lookup(element);

  @override
  bool remove(Object? value) => _delegate.remove(value);

  @override
  Iterator<E> get iterator => _delegate.iterator;

  @override
  int get length => _delegate.length;

  @override
  void clear() => _delegate.clear();

  @override
  Set<E> toSet() => CustomSet<E>()..addAll(this);

  @override
  String toString() => _delegate.toString();
}
