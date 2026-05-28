///|
pub(all) enum MemoryLayer {
  Skeleton
  User
  Experiences
  Sidecar
  Archive
} derive(Debug, Eq)

///|
pub fn render_memory_layer(layer : MemoryLayer) -> String {
  match layer {
    Skeleton => "skeleton"
    User => "user"
    Experiences => "experiences"
    Sidecar => "sidecar"
    Archive => "archive"
  }
}

///|
pub(all) struct LayeredMemory {
  skeleton : Memory
  user : Memory
  experiences : Memory
  sidecar : Memory
  archive : Memory
}

///|
pub fn LayeredMemory::new() -> LayeredMemory {
  {
    skeleton: Memory::new_with_limits(50, 2000),
    user: Memory::new_with_limits(30, 1000),
    experiences: Memory::new_with_limits(50, 2000),
    sidecar: Memory::new_with_limits(100, 3000),
    archive: Memory::new_with_limits(200, 5000),
  }
}

///|
pub fn LayeredMemory::get(self : LayeredMemory, layer : MemoryLayer) -> Memory {
  match layer {
    Skeleton => self.skeleton
    User => self.user
    Experiences => self.experiences
    Sidecar => self.sidecar
    Archive => self.archive
  }
}

///|
pub fn LayeredMemory::reset_all(self : LayeredMemory) -> Unit {
  self.skeleton.reset()
  self.user.reset()
  self.experiences.reset()
  self.sidecar.reset()
  self.archive.reset()
}

///|
pub fn LayeredMemory::reset_sidecar(self : LayeredMemory) -> Unit {
  self.sidecar.reset()
}

///|
pub fn LayeredMemory::total_messages(self : LayeredMemory) -> Int {
  self.skeleton.load().length() +
  self.user.load().length() +
  self.experiences.load().length() +
  self.sidecar.load().length() +
  self.archive.load().length()
}

///|
pub(all) struct MemoryRouter {
  layered : LayeredMemory
}

///|
pub fn MemoryRouter::new() -> MemoryRouter {
  { layered: LayeredMemory::new() }
}

///|
pub fn MemoryRouter::reset_session(self : MemoryRouter) -> Unit {
  self.layered.reset_sidecar()
}

///|
pub fn MemoryRouter::classify_and_store(self : MemoryRouter, msg : Message) -> Unit {
  let layer = classify_message(msg)
  self.layered.get(layer).store(msg)
}

///|
pub fn classify_message(msg : Message) -> MemoryLayer {
  match msg.role {
    System => Skeleton
    User => {
      if msg.content.length() > 500 {
        Archive
      } else if msg.content.has_prefix("[experience]") || msg.content.has_prefix("[经验]") {
        Experiences
      } else if msg.content.has_prefix("[user]") || msg.content.has_prefix("[用户]") {
        User
      } else {
        Sidecar
      }
    }
    Tool => Sidecar
    Assistant => Sidecar
  }
}

///|
pub fn MemoryRouter::default_context(self : MemoryRouter) -> String {
  let mut out = ""
  let skeleton_summary = self.layered.skeleton.summary()
  if skeleton_summary != "" {
    out = out + "[Skeleton Memory]\n" + skeleton_summary
  }
  let user_summary = self.layered.user.summary()
  if user_summary != "" {
    if out != "" { out = out + "\n\n" }
    out = out + "[User Preferences]\n" + user_summary
  }
  out
}

///|
pub fn MemoryRouter::full_context(self : MemoryRouter) -> String {
  let mut out = ""
  let layers = [
    ("Skeleton Memory", self.layered.skeleton),
    ("User Preferences", self.layered.user),
    ("Experiences", self.layered.experiences),
    ("Current Session", self.layered.sidecar),
  ]
  for _, pair in layers {
    let label = pair.0
    let mem = pair.1
    let summary = mem.summary()
    if summary != "" {
      if out != "" { out = out + "\n\n" }
      out = out + "[" + label + "]\n" + summary
    }
  }
  out
}

///|
pub fn MemoryRouter::recall(self : MemoryRouter, query : String) -> String {
  let results : Array[String] = []

  let skeleton_msgs = self.layered.skeleton.load()
  for msg in skeleton_msgs {
    if msg.content.contains(query) {
      results.push("[skeleton] " + render_message(msg))
    }
  }

  let user_msgs = self.layered.user.load()
  for msg in user_msgs {
    if msg.content.contains(query) {
      results.push("[user] " + render_message(msg))
    }
  }

  let exp_msgs = self.layered.experiences.load()
  for msg in exp_msgs {
    if msg.content.contains(query) {
      results.push("[experiences] " + render_message(msg))
    }
  }

  let sidecar_msgs = self.layered.sidecar.load()
  for msg in sidecar_msgs {
    if msg.content.contains(query) {
      results.push("[sidecar] " + render_message(msg))
    }
  }

  if results.length() == 0 {
    "No memories found for: " + query
  } else {
    let mut out = "Recall results for '" + query + "':"
    for r in results {
      out = out + "\n- " + r
    }
    out
  }
}

///|
pub fn MemoryRouter::restore_context(self : MemoryRouter) -> String {
  let mut out = "[Context Restoration]\n"

  let skeleton_summary = self.layered.skeleton.summary()
  if skeleton_summary != "" {
    out = out + "\n[Step 1: Skeleton Layer]\n" + skeleton_summary
  }

  let user_summary = self.layered.user.summary()
  if user_summary != "" {
    out = out + "\n\n[Step 2: User Layer]\n" + user_summary
  }

  let exp_summary = self.layered.experiences.summary()
  if exp_summary != "" {
    out = out + "\n\n[Step 3: Experiences Layer]\n" + exp_summary
  }

  let sidecar_summary = self.layered.sidecar.summary()
  if sidecar_summary != "" {
    out = out + "\n\n[Step 4: Current Session]\n" + sidecar_summary
  }

  out
}
