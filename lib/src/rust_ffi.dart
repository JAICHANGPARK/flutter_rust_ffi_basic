import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart'; // compute()를 위해 필요

// FFI 호출을 수행할 최상위 함수
// compute()의 요구 사항: 반드시 최상위 함수이거나 static 메서드여야 합니다.
String _heavyComputationIsolate(String name) {
  final nameC = name.toNativeUtf8();
  final resultC = RustFFI._heavyComputationSync(nameC);
  final result = resultC.toDartString();

  // 중요: Rust에서 할당된 메모리를 해제합니다.
  RustFFI._freeString(resultC);
  // 입력으로 사용된 포인터도 해제합니다.
  calloc.free(nameC);

  return result;
}

class RustFFI {
  // 1. 라이브러리 로드
  static final _lib = _loadLibrary();

  static DynamicLibrary _loadLibrary() {
    if (Platform.isAndroid || Platform.isLinux) {
      return DynamicLibrary.open('libflutter_rust_lib.so');
    }
    if (Platform.isMacOS) {
      return DynamicLibrary.open('libflutter_rust_lib.dylib');
    }
    if (Platform.isWindows) {
      return DynamicLibrary.open('flutter_rust_lib.dll');
    }
    throw UnsupportedError('Unsupported platform');
  }

  // 2. FFI 함수 시그니처 정의 및 바인딩
  // add (동기)
  static final int Function(int, int) add = _lib
      .lookup<NativeFunction<Int32 Function(Int32, Int32)>>('add')
      .asFunction();

  // heavy_computation (동기)
  static final Pointer<Utf8> Function(Pointer<Utf8>) _heavyComputationSync =
      _lib
          .lookup<NativeFunction<Pointer<Utf8> Function(Pointer<Utf8>)>>(
            'heavy_computation',
          )
          .asFunction();

  // free_string (동기)
  static final void Function(Pointer<Utf8>) _freeString = _lib
      .lookup<NativeFunction<Void Function(Pointer<Utf8>)>>('free_string')
      .asFunction();

  static Future<String> heavyComputationAsync(String name) async {
    return compute(_heavyComputationIsolate, name);
  }

  static String heavyComputation(String name) {
    return _heavyComputationIsolate(name);
  }
}
