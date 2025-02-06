import gleam/dynamic/decode

pub type Status {
  Consumed
  Unavailable
  Available
}

pub type Image {
  Image(url: String, status: Status, tags: List(String))
}

pub fn decoder() {
  use url <- decode.field("url", decode.string)
  use status <- decode.field("status", decode.string)
  use tags <- decode.field("tags", decode.list(decode.string))
  case status {
    "available" -> decode.success(Image(url:, status: Available, tags:))
    "unavailable" -> decode.success(Image(url:, status: Unavailable, tags:))
    "consumed" -> decode.success(Image(url:, status: Consumed, tags:))
    _ ->
      decode.failure(
        Image(status: Consumed, tags:, url:),
        "Failed to decode status",
      )
  }
}
