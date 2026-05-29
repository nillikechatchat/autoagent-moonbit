///|
/// Stub I/O functions for non-native targets (wasm-gc, wasm, js).
/// These provide no-op implementations so the code compiles on all targets.
/// Real implementations are in io_native.mbt (native/llvm only).
///

///|
pub fn http_post(url : String, body : String, auth_token~ : String = "") -> String {
  ""
}

///|
pub fn read_file(path : String) -> String {
  ""
}

///|
pub fn write_file(path : String, content : String) -> Bool {
  false
}

///|
pub fn mkdir(path : String) -> Bool {
  false
}

///|
pub fn list_dir(path : String) -> String {
  ""
}

///|
pub fn file_exists(path : String) -> Bool {
  false
}

///|
pub fn exec_command(cmd : String) -> String {
  ""
}

///|
pub fn get_env(key : String) -> String {
  ""
}

///|
pub fn set_env(key : String, value : String) -> Bool {
  false
}

///|
pub fn get_cwd() -> String {
  ""
}
