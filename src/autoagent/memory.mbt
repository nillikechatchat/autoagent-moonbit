///|
pub(all) struct Memory {
  mut messages : Array[Message]
  max_messages : Int
  max_message_length : Int
}

///|
pub fn Memory::new() -> Memory {
  { messages: [], max_messages: 100, max_message_length: 2000 }
}

///|
pub fn Memory::new_with_limits(max_messages : Int, max_message_length : Int) -> Memory {
  { messages: [], max_messages, max_message_length }
}

///|
pub fn Memory::reset(self : Memory) -> Unit {
  self.messages = []
}

///|
pub fn Memory::store(self : Memory, msg : Message) -> Unit {
  let content = if msg.content.length() > self.max_message_length {
    msg.content[:][0:self.max_message_length].to_owned() + "...[truncated]"
  } else {
    msg.content
  }
  let trimmed_msg = { role: msg.role, content }
  if self.messages.length() >= self.max_messages {
    self.messages = self.messages[1:].map(fn(x) { x })
  }
  self.messages.push(trimmed_msg)
}

///|
pub fn Memory::load(self : Memory) -> Array[Message] {
  self.messages
}

///|
pub fn Memory::summary(self : Memory) -> String {
  let mut out = ""
  for i, msg in self.messages {
    if i == 0 {
      out = render_message(msg)
    } else {
      out = out + "\n" + render_message(msg)
    }
  }
  out
}

///|
pub fn Memory::export_json(self : Memory) -> String {
  let mut out = "["
  for i, msg in self.messages {
    if i > 0 { out = out + "," }
    out = out + "{\"role\":\"" + render_role(msg.role) + "\",\"content\":\"" + msg.content + "\"}"
  }
  out = out + "]"
  out
}

///|
pub fn Memory::message_count(self : Memory) -> Int {
  self.messages.length()
}

///|
pub fn Memory::total_chars(self : Memory) -> Int {
  let mut total = 0
  for msg in self.messages {
    total = total + msg.content.length()
  }
  total
}

///|
pub fn Memory::has_messages(self : Memory) -> Bool {
  self.messages.length() > 0
}

///|
pub fn Memory::last_message(self : Memory) -> Message? {
  if self.messages.length() == 0 {
    None
  } else {
    Some(self.messages[self.messages.length() - 1])
  }
}

///|
pub fn Memory::remove_oldest(self : Memory, count : Int) -> Unit {
  let remaining = if count > self.messages.length() { 0 } else { self.messages.length() - count }
  self.messages = self.messages[self.messages.length() - remaining:].map(fn(x) { x })
}
