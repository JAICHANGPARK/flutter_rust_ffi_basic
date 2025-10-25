import 'package:flutter/material.dart';
import 'package:flutter_rust_ffi_example/src/rust_ffi.dart';
import 'src/rust_ffi.dart';

void main() => runApp(const MyApp());

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  int _addResult = 0;
  Future<String>? _heavyTaskFuture;

  void _runQuickTask() {
    // 동기 FFI 호출: 즉시 결과를 반환하며 UI를 막지 않음 (매우 빠르므로)
    setState(() {
      _addResult = RustFFI.add(10, 20);
    });
  }

  void _runHeavyTask() {
    // 비동기 FFI 호출: UI를 막지 않기 위해 Future를 사용
    setState(() {
      _heavyTaskFuture = RustFFI.heavyComputationAsync("Flutter");
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Flutter + Rust FFI 예제')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // --- 빠른 동기 작업 ---
                const Text(
                  '1. 빠른 동기 작업 (Future 불필요)',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  '계산 결과: 10 + 20 = $_addResult',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                ElevatedButton(
                  onPressed: _runQuickTask,
                  child: const Text('간단한 계산 실행'),
                ),
                const Divider(height: 50),

                // --- 무거운 비동기 작업 ---
                const Text(
                  '2. 무거운 비동기 작업 (Future + Isolate 필수)',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                ElevatedButton(
                  onPressed: _runHeavyTask,
                  child: const Text('무거운 작업 시작 (3초)'),
                ),
                const SizedBox(height: 20),
                FutureBuilder<String>(
                  future: _heavyTaskFuture,
                  builder: (context, snapshot) {
                    if (_heavyTaskFuture == null) {
                      return const Text('버튼을 눌러 작업을 시작하세요.');
                    }
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const CircularProgressIndicator();
                    }
                    if (snapshot.hasError) {
                      return Text(
                        '에러 발생: ${snapshot.error}',
                        style: const TextStyle(color: Colors.red),
                      );
                    }
                    if (snapshot.hasData) {
                      return Text(
                        '작업 결과:\n${snapshot.data}',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineSmall,
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),

                /// Merge Thread
                Text(RustFFI.heavyComputation("Flutter")),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
