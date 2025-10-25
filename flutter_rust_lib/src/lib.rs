use std::ffi::{c_char, CStr, CString};
use std::thread;
use std::time::Duration;

/// FFI: 간단하고 빠른 동기 함수
/// 두 정수를 더해서 반환합니다.
#[unsafe(no_mangle)] // <-- 수정된 부분
pub extern "C" fn add(a: i32, b: i32) -> i32 {
    a + b
}

/// FFI: 무겁고 오래 걸리는 CPU 집약적 함수 (동기 버전)
/// 이 함수 자체는 동기적으로 동작하므로, Dart에서 Isolate를 통해 호출해야 합니다.
/// C 형식의 문자열 포인터를 받아 Rust 문자열로 변환하고,
/// 오래 걸리는 작업을 시뮬레이션한 뒤, 새로운 C 문자열 포인터를 반환합니다.
#[unsafe(no_mangle)] // <-- 수정된 부분
pub extern "C" fn heavy_computation(name: *const c_char) -> *mut c_char {
    // C 문자열 포인터를 Rust &str로 안전하게 변환
    let name_str = unsafe {
        if name.is_null() {
            return CString::new("Error: name pointer was null").unwrap().into_raw();
        }
        CStr::from_ptr(name).to_str().unwrap_or("Error: Invalid UTF-8")
    };

    // CPU를 많이 사용하는 작업 시뮬레이션
    thread::sleep(Duration::from_secs(3)); // 3초 대기

    let result = format!("Hello, {}. Welcome from Rust!", name_str);

    // Rust String을 C 문자열로 변환하여 포인터를 반환
    // .into_raw()는 Rust가 메모리를 해제하지 않도록 소유권을 넘깁니다.
    // 이 메모리는 반드시 Dart 쪽에서 free_string 함수를 호출하여 해제해야 합니다.
    CString::new(result).unwrap().into_raw()
}

/// FFI: C 문자열 메모리 해제 함수
/// heavy_computation에서 할당한 메모리를 해제합니다.
#[unsafe(no_mangle)] // <-- 수정된 부분
pub extern "C" fn free_string(s: *mut c_char) {
    if s.is_null() {
        return;
    }
    // CString::from_raw()를 사용하여 포인터의 소유권을 다시 가져와
    // Rust의 메모리 관리자가 메모리를 안전하게 해제하도록 합니다.
    unsafe {
        let _ = CString::from_raw(s);
    }
}