///|
/// Stub I/O functions for non-native targets (wasm-gc, wasm, js).
/// These provide no-op implementations so the code compiles on all targets.
/// Real implementations are in io_native.mbt (native/llvm only).
///

///|
pub fn http_post(_url : String, _body : String, auth_token~ : String = "") -> String {
  ignore(auth_token)
  ""
}

///|
pub fn http_post_stream(_url : String, _body : String, auth_token~ : String = "") -> String {
  ignore(auth_token)
  ""
}

///|
pub fn time_ms() -> Int64 {
  0L
}

///|
pub fn read_file(_path : String) -> String {
  ""
}

///|
pub fn write_file(_path : String, _content : String) -> Bool {
  false
}

///|
pub fn mkdir(_path : String) -> Bool {
  false
}

///|
pub fn list_dir(_path : String) -> String {
  ""
}

///|
pub fn file_exists(_path : String) -> Bool {
  false
}

///|
pub fn exec_command(_cmd : String) -> String {
  ""
}

///|
pub fn get_env(_key : String) -> String {
  ""
}

///|
pub fn set_env(_key : String, _value : String) -> Bool {
  false
}

///|
pub fn get_cwd() -> String {
  ""
}

///|
pub fn read_stdin_line() -> String {
  ""
}

///|
pub fn stdin_eof() -> Bool {
  true
}
