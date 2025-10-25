# Flutter Rust FFI Example

This project demonstrates how to integrate a native Rust library with a Flutter application using Dart's Foreign Function Interface (FFI). It showcases two common use cases:

1.  **Quick, Synchronous Calls**: A simple `add` function that is fast enough to be called directly without blocking the UI thread.
2.  **Long-Running, Asynchronous Calls**: A `heavy_computation` function that simulates a time-consuming task. This function is called from a separate Dart Isolate to prevent the Flutter UI from freezing.

## Project Structure

```
/
├── flutter_rust_lib/  # Contains the Rust native library
│   ├── src/
│   │   └── lib.rs     # Rust source code with functions exposed via FFI
│   └── Cargo.toml     # Rust package manager configuration
├── lib/
│   ├── main.dart      # Main Flutter application and UI
│   └── src/
│       └── rust_ffi.dart # Dart code for loading and calling the Rust library
└── pubspec.yaml       # Flutter project configuration
```

## How It Works

### Rust Side (`flutter_rust_lib/src/lib.rs`)

- The Rust library is configured in `Cargo.toml` with `crate-type = ["cdylib"]` to produce a C-compatible dynamic library (`.so`, `.dylib`, or `.dll`).
- It exposes three functions:
    - `add(a: i32, b: i32) -> i32`: A simple function that takes two 32-bit integers and returns their sum.
    - `heavy_computation(name: *const c_char) -> *mut c_char`: Simulates a long task by sleeping for 3 seconds. It takes a C string, allocates new memory for a result string, and returns a pointer to it.
    - `free_string(s: *mut c_char)`: Frees the memory allocated by `heavy_computation`. This is crucial to prevent memory leaks, as Dart's garbage collector cannot manage memory allocated by Rust.
- The `#[no_mangle]` attribute is used to prevent the Rust compiler from changing the function names, ensuring they are easily accessible from Dart.

### Dart/Flutter Side (`lib/src/rust_ffi.dart`)

- **Loading the Library**: The `DynamicLibrary.open()` function loads the compiled Rust library based on the operating system.
- **FFI Bindings**:
    - Dart defines `typedef`s for the C function signatures and then uses `_lib.lookup<NativeFunction<...>>().asFunction()` to create callable Dart functions from the native Rust code.
- **Handling Synchronous Calls**: The `add` function is mapped directly and can be called like any other Dart function.
- **Handling Asynchronous Calls**:
    - The synchronous `_heavyComputationSync` binding is not called directly from the UI thread.
    - A wrapper function, `heavyComputationAsync`, uses Flutter's `compute()` function to run the FFI call in a separate Isolate.
    - This `compute()` function calls a top-level function (`_heavyComputationIsolate`) which handles:
        1.  Converting Dart strings to C-compatible pointers (`toNativeUtf8`).
        2.  Calling the synchronous Rust function.
        3.  Converting the returned C string pointer back to a Dart `String`.
        4.  **Crucially, calling `_freeString` to release the memory allocated in Rust.**
        5.  Freeing the input pointer memory.

### UI (`lib/main.dart`)

- The UI consists of two buttons to trigger the Rust functions.
- The result of the quick `add` function is displayed directly.
- A `FutureBuilder` is used to handle the asynchronous result of `heavy_computation`. It shows a `CircularProgressIndicator` while the Rust code is "working" in the background and then displays the result when the `Future` completes.

## Getting Started

### Prerequisites

- [Flutter SDK](https://flutter.dev/docs/get-started/install)
- [Rust toolchain](https://www.rust-lang.org/tools/install)

### Build Steps

1.  **Build the Rust Library**:
    Navigate to the Rust library directory and build it.

    ```bash
    cd flutter_rust_lib
    cargo build --release
    ```

2.  **Place the Compiled Library**:
    The build command will produce a dynamic library in `flutter_rust_lib/target/release/`. You need to copy this file to the correct location for Flutter to find it.

    - **For macOS/iOS**: Copy `libflutter_rust_lib.dylib` to `macos/Runner/` and `ios/Runner/`.
    - **For Linux**: Copy `libflutter_rust_lib.so` to `linux/`.
    - **For Windows**: Copy `flutter_rust_lib.dll` to `windows/runner/`.
    - **For Android**: The setup is more complex and typically requires configuring the `android/app/build.gradle` file to include the `.so` file in the final APK.

3.  **Run the Flutter App**:
    Once the library is in place, run the Flutter application as usual.

    ```bash
    flutter run
    ```