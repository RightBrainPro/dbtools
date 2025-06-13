import 'dart:async';


typedef VoidCallback = void Function();
typedef AsyncOperation<T, V> = Future<T> Function(V value);
typedef PasswordProvider = FutureOr<String> Function();
