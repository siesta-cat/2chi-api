import app
import bison/bson.{Document}
import bison/ejson
import bison/object_id
import given
import gleam/dict
import gleam/dynamic/decode
import gleam/json
import gleam/list
import gleam/option
import gleam/result
import image.{type Image, Image}
import mungo
import mungo/cursor
import mungo/error
import status

pub fn get_images(
  limit: Int,
  status: option.Option(String),
  ctx: app.Context,
) -> Result(List(Image), String) {
  use cursor <- result.try(case status {
    option.None ->
      mungo.find_all(ctx.collection, [], ctx.config.db_timeout)
      |> result.replace_error("500")
    option.Some(status) ->
      mungo.find_many(
        ctx.collection,
        [#("status", bson.String(status))],
        [],
        ctx.config.db_timeout,
      )
      |> result.replace_error("500")
  })

  use images <- result.try(
    result.all(list.map(
      cursor.to_list(cursor, ctx.config.db_timeout),
      image_from_bson,
    )),
  )

  case limit {
    0 -> Ok(images)
    limit -> Ok(list.take(images, limit))
  }
}

fn image_from_bson(bson: bson.Value) -> Result(Image, String) {
  use bson <- result.try(case bson {
    Document(bson) -> Ok(bson)
    _ -> Error("500")
  })

  let json = ejson.to_canonical(bson)

  use image <- result.try(
    json.parse(json, decoder_from_bson())
    |> result.replace_error("500"),
  )

  Ok(image)
}

fn oid_decoder() {
  use id <- decode.field("$oid", decode.string)
  decode.success(id)
}

fn decoder_from_bson() {
  use id <- decode.field("_id", oid_decoder())
  use url <- decode.field("url", decode.string)
  use status <- decode.field("status", status.decoder())
  use tags <- decode.field("tags", decode.list(decode.string))
  decode.success(Image(id:, url:, status:, tags:))
}

pub fn get_image(id: String, ctx: app.Context) -> Result(Image, String) {
  use result <- result.try(case
    mungo.find_by_id(ctx.collection, id, ctx.config.db_timeout)
  {
    Ok(result) -> Ok(result)
    Error(err) ->
      case err {
        error.StructureError -> Error("400")
        _ -> Error("500")
      }
  })
  use result <- given.some(result, else_return: fn() { Error("404") })

  use image <- result.try(image_from_bson(result))

  Ok(image)
}

pub fn put_image(
  image: Image,
  patch: String,
  ctx: app.Context,
) -> Result(Nil, String) {
  use object_id <- result.try(
    object_id.from_string(image.id) |> result.replace_error("400"),
  )

  use patch_bson <- result.try(
    ejson.from_canonical(patch)
    |> result.replace_error("400"),
  )

  use image_bson <- result.try(
    ejson.from_canonical(image.to_json_without_id(image))
    |> result.replace_error("500"),
  )

  let new_image_bson =
    dict.combine(image_bson, patch_bson, fn(_existing, new) { new })

  use _ <- result.try(
    mungo.update_one(
      ctx.collection,
      [#("_id", bson.ObjectId(object_id))],
      dict.to_list(new_image_bson),
      [],
      ctx.config.db_timeout,
    )
    |> result.replace_error("500"),
  )

  Ok(Nil)
}

pub fn post_image(
  image: dict.Dict(String, bson.Value),
  ctx: app.Context,
) -> Result(Image, String) {
  use id <- result.try(
    mungo.insert_one(ctx.collection, dict.to_list(image), ctx.config.db_timeout)
    |> result.replace_error("500"),
  )

  use id <- result.try(case id {
    bson.ObjectId(id) -> Ok(id)
    _ -> Error("500")
  })

  use image <- result.try(get_image(object_id.to_string(id), ctx))
  Ok(image)
}
