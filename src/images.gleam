import app
import bison/bson
import bison/ejson
import given
import gleam/bool
import gleam/dict
import gleam/dynamic
import gleam/dynamic/decode
import gleam/int
import gleam/json
import gleam/list
import gleam/option
import gleam/result
import image
import status
import storage

pub fn add(
  image json: String,
  context ctx: app.Context,
) -> Result(image.Image, String) {
  use image <- given.ok(json.parse(json, image.decoder()), fn(_) {
    Error("400")
  })

  use bson <- result.try(
    ejson.from_canonical(json)
    |> result.replace_error("400"),
  )

  use current_images <- result.try(storage.get_images(0, option.None, ctx))

  use <- bool.guard(
    list.any(current_images, fn(current_image) {
      current_image.url == image.url
    }),
    Error("409"),
  )

  use image <- result.try(storage.post_image(bson, ctx))

  Ok(image)
}

pub fn modify(
  image image: image.Image,
  patch json: String,
  context ctx: app.Context,
) -> Result(Nil, String) {
  use bson <- result.try(
    ejson.from_canonical(json)
    |> result.replace_error("400"),
  )

  // Cannot edit url
  use <- bool.guard(dict.has_key(bson, "url"), Error("400"))

  // Must contain valid status if has one
  use <- bool.guard(
    case dict.get(bson, "status") {
      Error(_) -> False
      Ok(status) -> {
        case status {
          bson.String(status) -> {
            case decode.run(dynamic.from(status), status.decoder()) {
              Error(_) -> True
              Ok(_) -> False
            }
          }
          _ -> True
        }
      }
    },
    Error("400"),
  )

  use _ <- result.try(storage.put_image(image, json, ctx))

  Ok(Nil)
}

pub fn get(
  params: List(#(String, String)),
  ctx: app.Context,
) -> Result(List(image.Image), String) {
  use limit <- result.try(
    list.find_map(params, fn(item) {
      let #(key, value) = item
      case key == "limit" {
        False -> Error(Nil)
        True -> Ok(value)
      }
    })
    |> result.unwrap("0")
    |> int.parse()
    |> result.replace_error("400"),
  )

  use <- bool.guard(limit < 0, Error("400"))

  let status =
    list.find_map(params, fn(item) {
      let #(key, value) = item
      case key == "status" {
        False -> Error(Nil)
        True -> Ok(value)
      }
    })
    |> option.from_result()

  use _ <- result.try(case status {
    option.None -> {
      Ok(Nil)
    }
    option.Some(status) -> {
      decode.run(dynamic.from(status), status.decoder())
      |> result.replace_error("400")
      |> result.replace(Nil)
    }
  })

  use images <- result.try(storage.get_images(limit, status, ctx))

  Ok(images)
}

pub fn get_image(id: String, ctx: app.Context) -> Result(image.Image, String) {
  storage.get_image(id, ctx)
}
