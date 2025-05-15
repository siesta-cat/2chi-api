import app
import given
import gleam/bit_array
import gleam/bool
import gleam/crypto
import gleam/dynamic/decode
import gleam/int
import gleam/option
import gleam/result
import gleam/string
import image/image
import image/status
import pog
import sqlight

pub type DB {
  Postgres(pog.Connection)
  Sqlite(sqlight.Connection)
}

fn decoder() {
  use id <- decode.field(0, decode.string)
  use url <- decode.field(1, decode.string)
  use status <- decode.field(2, status.decoder())
  decode.success(image.Image(id:, url:, status:))
}

pub fn run_query(
  query: String,
  db: DB,
  decoder: decode.Decoder(a),
) -> Result(List(a), app.Err) {
  case db {
    Postgres(db) -> {
      use res <- given.ok(
        pog.query(query)
          |> pog.returning(decoder)
          |> pog.execute(db),
        query_err,
      )
      Ok(res.rows)
    }
    Sqlite(db) -> {
      use res <- given.ok(
        sqlight.query(query, on: db, with: [], expecting: decoder),
        query_err,
      )
      Ok(res)
    }
  }
}

fn query_err(err) {
  Error(app.Err(500, "Failed to query DB", string.inspect(err)))
}

pub fn init_db(table: String, db: DB) -> Result(Nil, app.Err) {
  let decoder = {
    decode.success(Nil)
  }

  let create_table =
    "CREATE TABLE IF NOT EXISTS "
    <> table
    <> " (id TEXT PRIMARY KEY, url TEXT UNIQUE, status TEXT)"

  let create_index =
    "CREATE INDEX IF NOT EXISTS urls ON " <> table <> " ( url )"
  use _ <- result.try(run_query(create_table, db, decoder))
  use _ <- result.try(run_query(create_index, db, decoder))

  Ok(Nil)
}

pub fn url_exists(url: String, table: String, db: DB) -> Result(Bool, app.Err) {
  let decoder = {
    use count <- decode.field(0, decode.int)
    decode.success(count)
  }

  let query = "SELECT count(url) FROM " <> table
  let url = " WHERE url LIKE '" <> url <> "'"

  let query = string.concat([query, url])

  use count <- result.try(run_query(query, db, decoder))
  case count {
    [] -> Error(app.Err(500, "Error counting images", ""))
    [count, ..] -> Ok(count > 0)
  }
}

pub fn get_images(
  limit: Int,
  status: option.Option(String),
  table: String,
  db: DB,
) -> Result(List(image.Image), app.Err) {
  let query = "SELECT id, url, status FROM " <> table
  let status = case status {
    option.None -> ""
    option.Some(status) -> " WHERE status LIKE '" <> status <> "'"
  }
  let limit = case limit {
    0 -> ""
    limit -> " LIMIT " <> int.to_string(limit)
  }

  let query = string.concat([query, status, limit])

  run_query(query, db, decoder())
}

pub fn get_image(
  id: String,
  table: String,
  db: DB,
) -> Result(image.Image, app.Err) {
  use <- bool.guard(
    string.length(id) != 40,
    Error(app.Err(400, "Invalid ID", id)),
  )

  let query = "SELECT id, url, status FROM " <> table
  let id = " WHERE id='" <> id <> "'"

  let query = string.concat([query, id])

  use images <- result.try(run_query(query, db, decoder()))
  case images {
    [] -> Error(app.Err(404, "Image not found", ""))
    [image, ..] -> Ok(image)
  }
}

pub fn put_image(
  image: image.Image,
  table: String,
  db: DB,
) -> Result(Nil, app.Err) {
  todo
}

pub fn post_image(
  image: image.Image,
  table: String,
  db: DB,
) -> Result(image.Image, app.Err) {
  let image.Image(id: _, url:, status:) = image

  let id = crypto.hash(crypto.Sha1, <<url:utf8>>) |> bit_array.base16_encode
  let status = status.to_string(status)

  let query = "INSERT INTO " <> table
  let structure = " ( id, url, status )"
  let values =
    string.concat([" VALUES ( '", id, "', '", url, "', '", status, "' )"])

  let query = string.concat([query, structure, values])

  use _ <- result.try(run_query(query, db, decoder()))
  get_image(id, table, db)
}
