import gleam/dynamic/decode
import gleam/json
import status.{type Status}

pub type Image {
  Image(id: String, url: String, status: Status, tags: List(String))
}

pub fn decoder() {
  use id <- decode.field("_id", decode.string)
  use url <- decode.field("url", decode.string)
  use status <- decode.field("status", status.decoder())
  use tags <- decode.field("tags", decode.list(decode.string))
  decode.success(Image(id:, url:, status:, tags:))
}

pub fn to_json(image: Image) -> json.Json {
  json.object([
    #("_id", json.string(image.id)),
    #("url", json.string(image.url)),
    #("status", json.string(status.to_string(image.status))),
    #("tags", json.array(image.tags, of: json.string)),
  ])
}

pub fn to_json_without_id(image: Image) -> String {
  json.object([
    #("url", json.string(image.url)),
    #("status", json.string(status.to_string(image.status))),
    #("tags", json.array(image.tags, of: json.string)),
  ])
  |> json.to_string()
}
