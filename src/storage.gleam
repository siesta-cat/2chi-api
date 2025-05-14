import app
import given
import gleam/bool
import gleam/dynamic/decode
import gleam/int
import gleam/option
import gleam/result
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

fn run_query(
  query: String,
  db: app.DB,
  decoder: decode.Decoder(a),
) -> Result(List(a), app.Err) {
  case db {
    app.Postgres(db) -> {
      use res <- given.ok(
        pog.query(query)
          |> pog.returning(decoder)
          |> pog.execute(db),
        query_err,
      )
      Ok(res.rows)
    }
    app.Sqlite(db) -> {
      use res <- given.ok(
        sqlight.query(query, on: db, with: [], expecting: decoder),
        query_err,
      )
      Ok(res)
    }
  }
}

fn query_err(err) {
  Error(app.Err(500, "Failed to get images from DB", string.inspect(err)))
}

pub fn url_exists(url: String, ctx: app.Context) -> Result(Bool, app.Err) {
  let decoder = {
    use count <- decode.field(0, decode.int)
    decode.success(count)
  }

  let query = "SELECT count(*) FROM " <> ctx.config.db_table
  let url = " WHERE url LIKE " <> url

  let query = string.concat([query, url])

  use count <- result.try(run_query(query, ctx.db, decoder))
  case count {
    [] -> Error(app.Err(500, "Error counting images", ""))
    [count, ..] -> Ok(count > 0)
  }
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

  run_query(query, ctx.db, decoder())
}

pub fn get_image(id: String, ctx: app.Context) -> Result(image.Image, app.Err) {
  use <- bool.guard(
    string.length(id) != 40,
    Error(app.Err(400, "Invalid ID", id)),
  )

  let query = "SELECT id, url, status FROM " <> ctx.config.db_table
  let id = " WHERE id='" <> id <> "'"

  let query = string.concat([query, id])

  use images <- result.try(run_query(query, ctx.db, decoder()))
  case images {
    [] -> Error(app.Err(404, "Image not found", ""))
    [image, ..] -> Ok(image)
  }
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
