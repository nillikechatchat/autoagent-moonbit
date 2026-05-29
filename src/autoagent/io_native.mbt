///|
/// Native I/O FFI declarations for AutoAgent.
/// These functions call C implementations via extern "c" linkage.
/// Only compiled for native/llvm targets.
///

///|
#external
type NativePtr

///|
#borrow(url, body, auth)
extern "c" fn autoagent_http_post(
  url : Bytes,
  url_len : Int,
  body : Bytes,
  body_len : Int,
  auth : Bytes,
  auth_len : Int
) -> Bytes = "autoagent_http_post"

///|
#borrow(path)
extern "c" fn autoagent_read_file(path : Bytes, path_len : Int) -> Bytes = "autoagent_read_file"

///|
#borrow(path, content)
extern "c" fn autoagent_write_file(
  path : Bytes,
  path_len : Int,
  content : Bytes,
  content_len : Int
) -> Int = "autoagent_write_file"

///|
#borrow(path)
extern "c" fn autoagent_mkdir(path : Bytes, path_len : Int) -> Int = "autoagent_mkdir"

///|
#borrow(path)
extern "c" fn autoagent_list_dir(path : Bytes, path_len : Int) -> Bytes = "autoagent_list_dir"

///|
#borrow(path)
extern "c" fn autoagent_file_exists(path : Bytes, path_len : Int) -> Int = "autoagent_file_exists"

///|
#borrow(cmd)
extern "c" fn autoagent_exec(cmd : Bytes, cmd_len : Int) -> Bytes = "autoagent_exec"

///|
#borrow(key)
extern "c" fn autoagent_getenv(key : Bytes, key_len : Int) -> Bytes = "autoagent_getenv"

///|
#borrow(key, val)
extern "c" fn autoagent_setenv(
  key : Bytes,
  key_len : Int,
  val : Bytes,
  val_len : Int
) -> Int = "autoagent_setenv"

///|
extern "c" fn autoagent_getcwd_alloc() -> Bytes = "autoagent_getcwd_alloc"

///|
#borrow(ptr)
extern "c" fn autoagent_free(ptr : Bytes) -> Unit = "autoagent_free"

///|
/// Convert String to null-terminated Bytes for C interop
///
fn str_to_c_bytes(s : String) -> Bytes {
  let len = s.length()
  let arr : Array[Byte] = []
  let mut i = 0
  while i < len {
    arr.push(s.code_unit_at(i).to_byte())
    i = i + 1
  }
  arr.push(0b0)
  Bytes::from_array(arr)
}

///|
/// Convert C null-terminated Bytes to String
///
fn c_bytes_to_str(b : Bytes) -> String {
  if b.length() == 0 { return "" }
  let mut len = 0
  while len < b.length() && b[len] != 0b0 {
    len = len + 1
  }
  let s : Array[Byte] = []
  let mut i = 0
  while i < len {
    s.push(b[i])
    i = i + 1
  }
  // Use the same approach as env_native.mbt
  let res = StringBuilder()
  i = 0
  while i < s.length() {
    let mut c = s[i].to_int()
    if c == 0 {
      break
    } else if c < 0x80 {
      res.write_char(c.unsafe_to_char())
      i += 1
    } else if c < 0xE0 {
      if i + 1 >= s.length() { break }
      c = ((c & 0x1F) << 6) | (s[i + 1].to_int() & 0x3F)
      res.write_char(c.unsafe_to_char())
      i += 2
    } else if c < 0xF0 {
      if i + 2 >= s.length() { break }
      c = ((c & 0x0F) << 12) |
        ((s[i + 1].to_int() & 0x3F) << 6) |
        (s[i + 2].to_int() & 0x3F)
      res.write_char(c.unsafe_to_char())
      i += 3
    } else {
      if i + 3 >= s.length() { break }
      c = ((c & 0x07) << 18) |
        ((s[i + 1].to_int() & 0x3F) << 12) |
        ((s[i + 2].to_int() & 0x3F) << 6) |
        (s[i + 3].to_int() & 0x3F)
      c -= 0x10000
      res.write_char(((c >> 10) + 0xD800).unsafe_to_char())
      res.write_char(((c & 0x3FF) + 0xDC00).unsafe_to_char())
      i += 4
    }
  }
  res.to_string()
}

///|
/// HTTP POST request. Returns response body string.
///
pub fn http_post(url : String, body : String, auth_token~ : String = "") -> String {
  let url_b = str_to_c_bytes(url)
  let body_b = str_to_c_bytes(body)
  let auth_b = str_to_c_bytes(auth_token)
  let resp = autoagent_http_post(
    url_b,
    url.length(),
    body_b,
    body.length(),
    auth_b,
    auth_token.length(),
  )
  if resp.length() == 0 { return "" }
  let s = c_bytes_to_str(resp)
  autoagent_free(resp)
  s
}

///|
/// Read file content. Returns empty string on error.
///
pub fn read_file(path : String) -> String {
  let path_b = str_to_c_bytes(path)
  let content = autoagent_read_file(path_b, path.length())
  if content.length() == 0 { return "" }
  let s = c_bytes_to_str(content)
  autoagent_free(content)
  s
}

///|
/// Write file. Returns true on success.
///
pub fn write_file(path : String, content : String) -> Bool {
  let path_b = str_to_c_bytes(path)
  let content_b = str_to_c_bytes(content)
  autoagent_write_file(path_b, path.length(), content_b, content.length()) == 0
}

///|
/// Create directory. Returns true on success.
///
pub fn mkdir(path : String) -> Bool {
  let path_b = str_to_c_bytes(path)
  autoagent_mkdir(path_b, path.length()) == 0
}

///|
/// List directory entries. Returns newline-separated string.
///
pub fn list_dir(path : String) -> String {
  let path_b = str_to_c_bytes(path)
  let entries = autoagent_list_dir(path_b, path.length())
  if entries.length() == 0 { return "" }
  let s = c_bytes_to_str(entries)
  autoagent_free(entries)
  s
}

///|
/// Check if file exists.
///
pub fn file_exists(path : String) -> Bool {
  let path_b = str_to_c_bytes(path)
  autoagent_file_exists(path_b, path.length()) == 1
}

///|
/// Execute shell command. Returns stdout+stderr output.
///
pub fn exec_command(cmd : String) -> String {
  let cmd_b = str_to_c_bytes(cmd)
  let output = autoagent_exec(cmd_b, cmd.length())
  if output.length() == 0 { return "" }
  let s = c_bytes_to_str(output)
  autoagent_free(output)
  s
}

///|
/// Get environment variable. Returns empty string if not set.
///
pub fn get_env(key : String) -> String {
  let key_b = str_to_c_bytes(key)
  let val = autoagent_getenv(key_b, key.length())
  if val.length() == 0 { return "" }
  let s = c_bytes_to_str(val)
  autoagent_free(val)
  s
}

///|
/// Set environment variable.
///
pub fn set_env(key : String, value : String) -> Bool {
  let key_b = str_to_c_bytes(key)
  let val_b = str_to_c_bytes(value)
  autoagent_setenv(key_b, key.length(), val_b, value.length()) == 0
}

///|
/// Get current working directory.
///
pub fn get_cwd() -> String {
  let cwd = autoagent_getcwd_alloc()
  if cwd.length() == 0 { return "" }
  let s = c_bytes_to_str(cwd)
  autoagent_free(cwd)
  s
}
