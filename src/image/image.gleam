import gleam/dynamic/decode
import gleam/json
import image/status

pub type Image {
  Image(id: String, url: String, status: status.Status)
}

pub fn decoder() {
  use id <- decode.optional_field("id", "no_id", decode.string)
  use url <- decode.field("url", decode.string)
  use status <- decode.field("status", status.decoder())
  decode.success(Image(id:, url:, status:))
}

pub fn to_json(image: Image) -> json.Json {
  json.object([
    #("id", json.string(image.id)),
    #("url", json.string(image.url)),
    #("status", json.string(status.to_string(image.status))),
  ])
}

pub fn to_json_without_id(image: Image) -> String {
  json.object([
    #("url", json.string(image.url)),
    #("status", json.string(status.to_string(image.status))),
  ])
  |> json.to_string()
}
