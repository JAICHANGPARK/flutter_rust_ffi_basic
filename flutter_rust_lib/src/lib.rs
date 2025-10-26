use std::ffi::{c_char, CStr, CString};
use std::thread;
use std::time::Duration;

/// FFI: シンプルで高速な同期関数
/// 2つの整数を足して返します。
#[unsafe(no_mangle)]
pub extern "C" fn add(a: i32, b: i32) -> i32 {
    a + b
}

/// FFI: 重くて時間のかかるCPU集約的な関数（同期バージョン）
/// この関数自体は同期的に動作するため、DartのIsolateを介して呼び出す必要があります。
/// C形式の文字列ポインタを受け取り、Rustの文字列に変換し、
/// 時間のかかる作業をシミュレートした後、新しいC文字列ポインタを返します。
#[unsafe(no_mangle)]
pub extern "C" fn heavy_computation(name: *const c_char) -> *mut c_char {
    // C文字列ポインタを安全にRustの&strに変換
    let name_str = unsafe {
        if name.is_null() {
            return CString::new("Error: name pointer was null").unwrap().into_raw();
        }
        CStr::from_ptr(name).to_str().unwrap_or("Error: Invalid UTF-8")
    };

    // CPUを多く使用する作業のシミュレーション
    thread::sleep(Duration::from_secs(3)); // 3秒待機

    let result = format!("Hello, {}. Welcome from Rust!", name_str);

    // RustのStringをC文字列に変換してポインタを返す
    // .into_raw()はRustがメモリを解放しないように所有権を渡します。
    // このメモリは必ずDart側でfree_string関数を呼び出して解放する必要があります。
    CString::new(result).unwrap().into_raw()
}

/// FFI: C文字列のメモリ解放関数
/// heavy_computationで割り当てられたメモリを解放します。
#[unsafe(no_mangle)]
pub extern "C" fn free_string(s: *mut c_char) {
    if s.is_null() {
        return;
    }
    // CString::from_raw()を使用してポインタの所有権を再び取得し、
    // Rustのメモリ管理者がメモリを安全に解放するようにします。
    unsafe {
        let _ = CString::from_raw(s);
    }
}