import app
import given
import gleam/option
import gleam/result
import gleam/string
import pog
import sqlight
import storage

pub type Context {
  Context(config: app.Config, db: storage.DB)
}

pub fn get_context(config: app.Config) -> Result(Context, app.Err) {
  case string.starts_with(config.db_uri, "postgresql://") {
    False -> {
      use conn <- given.ok(sqlight.open(config.db_uri), fn(err) {
        Error(app.Err(500, "Failed to open sqlite db", string.inspect(err)))
      })
      use _ <- result.try(storage.init_db(config.db_table, storage.Sqlite(conn)))
      Ok(Context(config:, db: storage.Sqlite(conn)))
    }
    True -> {
      use database_url <- result.try(
        pog.url_config(config.db_uri)
        |> result.replace_error(app.Err(
          500,
          "Error parsing database string",
          config.db_uri,
        )),
      )
      let db =
        database_url
        |> pog.password(option.Some(config.db_pass))
        |> pog.pool_size(3)
        |> pog.connect
      use _ <- result.try(storage.init_db(config.db_table, storage.Postgres(db)))
      Ok(Context(config:, db: storage.Postgres(db)))
    }
  }
}
