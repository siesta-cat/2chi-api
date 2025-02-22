import gleam/dynamic/decode

pub type Status {
  Consumed
  Unavailable
  Available
}

pub fn decoder() {
  use status <- decode.then(decode.string)
  case status {
    "available" -> decode.success(Available)
    "unavailable" -> decode.success(Unavailable)
    "consumed" -> decode.success(Consumed)
    _ -> decode.failure(Consumed, "Failed to decode status")
  }
}

pub fn to_string(status: Status) -> String {
  case status {
    Available -> "available"
    Consumed -> "consumed"
    Unavailable -> "unavailable"
  }
}

pub fn from_string(status: String) -> Result(Status, Nil) {
  case status {
    "available" -> Ok(Available)
    "consumed" -> Ok(Consumed)
    "unavailable" -> Ok(Unavailable)
    _ -> Error(Nil)
  }
}
