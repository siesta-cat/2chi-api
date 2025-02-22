import bison/bson
import bison/ejson
import gleam/dynamic/decode
import gleam/json
import gleam/result
import gleam/string
import status.{type Status}

pub type Image {
  Image(id: String, url: String, status: Status, tags: List(String))
}

pub fn decoder() {
  use id <- decode.optional_field("_id", "no_id", decode.string)
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

pub fn from_bson(bson: bson.Value) -> Result(Image, String) {
  use bson <- result.try(case bson {
    bson.Document(bson) -> Ok(bson)
    _ -> Error("Invalid image found in db:\n" <> string.inspect(bson))
  })

  let json = ejson.to_canonical(bson)

  use image <- result.try(
    json.parse(json, decoder_from_bson())
    |> result.replace_error(
      "Invalid image found in db:\n" <> string.inspect(bson),
    ),
  )

  Ok(image)
}

fn decoder_from_bson() {
  use id <- decode.field("_id", oid_decoder())
  use url <- decode.field("url", decode.string)
  use status <- decode.field("status", status.decoder())
  use tags <- decode.field("tags", decode.list(decode.string))
  decode.success(Image(id:, url:, status:, tags:))
}

fn oid_decoder() {
  use id <- decode.field("$oid", decode.string)
  decode.success(id)
}
