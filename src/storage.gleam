import app
import given
import gleam/dynamic/decode
import gleam/int
import gleam/option
import gleam/string
import image/image
import image/status
import pog
import sqlight

fn decoder() {
  use id <- decode.field(0, decode.string)
  use url <- decode.field(1, decode.string)
  use status <- decode.field(2, status.decoder())
  decode.success(image.Image(id:, url:, status:))
}

fn query_err(err) {
  Error(app.Err(500, "Failed to get images from DB", string.inspect(err)))
}

pub fn url_exists(url: String, ctx: app.Context) -> Result(Bool, app.Err) {
  todo
}

pub fn get_images(
  limit: Int,
  status: option.Option(String),
  ctx: app.Context,
) -> Result(List(image.Image), app.Err) {
  let query = "SELECT id, url, status FROM " <> ctx.config.db_table
  let status = case status {
    option.None -> ""
    option.Some(status) -> " WHERE status LIKE '" <> status <> "'"
  }
  let limit = case limit {
    0 -> ""
    limit -> " LIMIT " <> int.to_string(limit)
  }

  let query = string.concat([query, status, limit])

  case ctx.db {
    app.Postgres(db) -> {
      use res <- given.ok(
        pog.query(query)
          |> pog.returning(decoder())
          |> pog.execute(db),
        query_err,
      )
      Ok(res.rows)
    }
    app.Sqlite(db) -> {
      use res <- given.ok(
        sqlight.query(query, on: db, with: [], expecting: decoder()),
        query_err,
      )
      Ok(res)
    }
  }
}

pub fn get_image(id: String, ctx: app.Context) -> Result(image.Image, app.Err) {
  todo
}

pub fn put_image(image: image.Image, ctx: app.Context) -> Result(Nil, app.Err) {
  todo
}

pub fn post_image(
  image: image.Image,
  ctx: app.Context,
) -> Result(image.Image, app.Err) {
  todo
}
