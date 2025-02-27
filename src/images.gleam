import app
import gleam/bool
import gleam/dynamic
import gleam/dynamic/decode
import gleam/int
import gleam/json
import gleam/list
import gleam/option
import gleam/result
import gleam/string
import image/image
import image/status
import storage

pub fn add(
  image json: String,
  context ctx: app.Context,
) -> Result(image.Image, app.Error) {
  use image <- result.try(
    json.parse(json, image.decoder())
    |> result.replace_error(app.Error(
      400,
      "Invalid image revieved",
      string.inspect(json),
    )),
  )

  use current_images <- result.try(storage.get_images(0, option.None, ctx))

  use <- bool.guard(
    list.any(current_images, fn(current_image) {
      current_image.url == image.url
    }),
    Error(app.Error(409, "image already on database", string.inspect(image))),
  )

  use image <- result.try(storage.post_image(image, ctx))

  Ok(image)
}

pub fn modify(
  image image: image.Image,
  patch json: String,
  context ctx: app.Context,
) -> Result(Nil, app.Error) {
  use patch <- result.try(
    json.parse(json, patch_decoder())
    |> result.replace_error(app.Error(
      400,
      "Invalid image patch revieved",
      string.inspect(json),
    )),
  )

  // Cannot edit url
  use <- bool.guard(
    option.is_some(patch.url),
    Error(app.Error(400, "Cannot modify image url", string.inspect(json))),
  )

  let new_image =
    image.Image(
      id: image.id,
      url: image.url,
      status: option.unwrap(patch.status, image.status),
      tags: option.unwrap(patch.tags, image.tags),
    )

  use _ <- result.try(storage.put_image(new_image, ctx))

  Ok(Nil)
}

pub fn get(
  params: List(#(String, String)),
  ctx: app.Context,
) -> Result(List(image.Image), app.Error) {
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
    |> result.replace_error(app.Error(
      400,
      "Invalid limit value, must be Int",
      "",
    )),
  )

  use <- bool.guard(
    limit < 0,
    Error(app.Error(400, "Limit must be 0 or more", int.to_string(limit))),
  )

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
      |> result.replace_error(app.Error(400, "Invalid status value", status))
      |> result.replace(Nil)
    }
  })

  use images <- result.try(storage.get_images(limit, status, ctx))

  Ok(images)
}

pub fn get_image(id: String, ctx: app.Context) -> Result(image.Image, app.Error) {
  storage.get_image(id, ctx)
}

type Patch {
  Patch(
    url: option.Option(String),
    status: option.Option(status.Status),
    tags: option.Option(List(String)),
  )
}

fn patch_decoder() {
  use url <- decode.optional_field(
    "url",
    option.None,
    decode.optional(decode.string),
  )
  use status <- decode.optional_field(
    "status",
    option.None,
    decode.optional(status.decoder()),
  )
  use tags <- decode.optional_field(
    "tags",
    option.None,
    decode.optional(decode.list(decode.string)),
  )
  decode.success(Patch(url:, status:, tags:))
}
