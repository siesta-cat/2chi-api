import app
import bison/bson
import bison/object_id
import given
import gleam/dict
import gleam/list
import gleam/option
import gleam/result
import gleam/string
import image/image
import image/status
import mungo
import mungo/cursor
import mungo/error

pub fn url_exists(ctx: app.Context, url: String) -> Result(Bool, app.Error) {
  use url <- result.try(
    mungo.find_one(
      ctx.collection,
      [#("url", bson.String(url))],
      [],
      ctx.config.db_timeout,
    )
    |> result.map_error(fn(err) {
      app.Error(500, "failed to conect to db", string.inspect(err))
    }),
  )
  Ok(option.is_some(url))
}

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

pub fn put_image(image: image.Image, ctx: app.Context) -> Result(Nil, app.Error) {
  use object_id <- result.try(
    object_id.from_string(image.id)
    |> result.replace_error(app.Error(
      400,
      "Invalid image id",
      string.inspect(image),
    )),
  )

  use _ <- result.try(
    mungo.update_one(
      ctx.collection,
      [#("_id", bson.ObjectId(object_id))],
      to_bson(image),
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

fn to_bson(image: image.Image) -> List(#(String, bson.Value)) {
  [
    #("url", bson.String(image.url)),
    #("status", bson.String(status.to_string(image.status))),
    #("tags", bson.Array(list.map(image.tags, fn(tag) { bson.String(tag) }))),
  ]
}

fn from_bson(bson: bson.Value) -> Result(image.Image, String) {
  use id <- result.try(case bson {
    bson.Document(bson) ->
      dict.get(bson, "_id")
      |> result.replace_error(
        "Invalid image found in db " <> string.inspect(bson),
      )
    _ -> Error("Invalid image found in db " <> string.inspect(bson))
  })
  use status <- result.try(case bson {
    bson.Document(bson) ->
      dict.get(bson, "status")
      |> result.replace_error(
        "Invalid image found in db " <> string.inspect(bson),
      )
    _ -> Error("Invalid image found in db " <> string.inspect(bson))
  })
  use tags <- result.try(case bson {
    bson.Document(bson) ->
      dict.get(bson, "tags")
      |> result.replace_error(
        "Invalid image found in db " <> string.inspect(bson),
      )
    _ -> Error("Invalid image found in db " <> string.inspect(bson))
  })
  use url <- result.try(case bson {
    bson.Document(bson) ->
      dict.get(bson, "url")
      |> result.replace_error(
        "Invalid image found in db " <> string.inspect(bson),
      )
    _ -> Error("Invalid image found in db " <> string.inspect(bson))
  })

  use id <- result.try(case id {
    bson.ObjectId(id) -> Ok(object_id.to_string(id))
    _ -> Error("Invalid id found in db " <> string.inspect(id))
  })
  use url <- result.try(case url {
    bson.String(url) -> Ok(url)
    _ -> Error("Invalid url found in db " <> string.inspect(url))
  })
  use status <- result.try(case status {
    bson.String(status) ->
      status.from_string(status)
      |> result.replace_error(
        "Invalid status found in db " <> string.inspect(status),
      )
    _ -> Error("Invalid status found in db " <> string.inspect(status))
  })
  use tags <- result.try(case tags {
    bson.Array(tags) ->
      list.map(tags, fn(tag) {
        case tag {
          bson.String(tag) -> Ok(tag)
          _ -> Error("Invalid tag found in db " <> string.inspect(tag))
        }
      })
      |> result.all
    _ -> Error("Invalid tags found in db " <> string.inspect(tags))
  })

  Ok(image.Image(id:, status:, tags:, url:))
}
