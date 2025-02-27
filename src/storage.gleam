import app
import bison/bson
import bison/ejson
import bison/object_id
import given
import gleam/dict
import gleam/dynamic/decode
import gleam/json
import gleam/list
import gleam/option
import gleam/result
import gleam/string
import image
import mungo
import mungo/cursor
import mungo/error
import status

pub fn get_images(
  limit: Int,
  status: option.Option(String),
  ctx: app.Context,
) -> Result(List(image.Image), app.Error) {
  use cursor <- result.try(case status {
    option.None ->
      mungo.find_all(ctx.collection, [], ctx.config.db_timeout)
      |> result.map_error(fn(err) {
        app.Error(500, "failed to conect to db", string.inspect(err))
      })
    option.Some(status) ->
      mungo.find_many(
        ctx.collection,
        [#("status", bson.String(status))],
        [],
        ctx.config.db_timeout,
      )
      |> result.map_error(fn(err) {
        app.Error(500, "failed to conect to db", string.inspect(err))
      })
  })

  use images <- result.try(
    result.all(list.map(
      cursor.to_list(cursor, ctx.config.db_timeout),
      from_bson,
    ))
    |> result.map_error(fn(err) {
      app.Error(500, "Internal server error", string.inspect(err))
    }),
  )

  case limit {
    0 -> Ok(images)
    limit -> Ok(list.take(images, limit))
  }
}

pub fn get_image(id: String, ctx: app.Context) -> Result(image.Image, app.Error) {
  use result <- result.try(case
    mungo.find_by_id(ctx.collection, id, ctx.config.db_timeout)
  {
    Ok(result) -> Ok(result)
    Error(err) ->
      case err {
        error.StructureError -> Error(app.Error(400, "Invalid id value", id))
        err ->
          Error(app.Error(
            500,
            "Error retrieving value from database",
            string.inspect(err),
          ))
      }
  })
  use result <- given.some(result, else_return: fn() {
    Error(app.Error(404, "Image not found", id))
  })

  use image <- result.try(
    from_bson(result)
    |> result.map_error(fn(err) { app.Error(500, "Internal server error", err) }),
  )

  Ok(image)
}

pub fn put_image(
  image: image.Image,
  patch: String,
  ctx: app.Context,
) -> Result(Nil, app.Error) {
  use object_id <- result.try(
    object_id.from_string(image.id)
    |> result.replace_error(app.Error(
      400,
      "Invalid image id",
      string.inspect(image),
    )),
  )

  use patch_bson <- result.try(
    ejson.from_canonical(patch)
    |> result.replace_error(app.Error(400, "invalid patch provided", patch)),
  )

  use image_bson <- result.try(
    ejson.from_canonical(image.to_json_without_id(image))
    |> result.replace_error(app.Error(
      500,
      "Internal server error",
      string.inspect(image),
    )),
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
    |> result.map_error(fn(err) {
      app.Error(500, "failed to update image", string.inspect(err))
    }),
  )

  Ok(Nil)
}

pub fn post_image(
  image: image.Image,
  ctx: app.Context,
) -> Result(image.Image, app.Error) {
  use id <- result.try(
    mungo.insert_one(ctx.collection, to_bson(image), ctx.config.db_timeout)
    |> result.replace_error(app.Error(
      500,
      "Internal server error",
      "Failed to insert image into db " <> string.inspect(image),
    )),
  )

  use id <- result.try(case id {
    bson.ObjectId(id) -> Ok(id)
    _ ->
      Error(app.Error(
        500,
        "Internal server error",
        "Cannot extract id from image " <> string.inspect(id),
      ))
  })

  use image <- result.try(get_image(object_id.to_string(id), ctx))
  Ok(image)
}

fn from_bson(bson: bson.Value) -> Result(image.Image, String) {
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
  decode.success(image.Image(id:, url:, status:, tags:))
}

fn oid_decoder() {
  use id <- decode.field("$oid", decode.string)
  decode.success(id)
}

fn to_bson(image: image.Image) -> List(#(String, bson.Value)) {
  [
    #("url", bson.String(image.url)),
    #("status", bson.String(status.to_string(image.status))),
    #("tags", bson.Array(list.map(image.tags, fn(tag) { bson.String(tag) }))),
  ]
}
