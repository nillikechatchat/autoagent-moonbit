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
