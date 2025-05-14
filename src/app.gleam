import given
import gleam/option
import gleam/result
import gleam/string
import pog
import sqlight

pub type DB {
  Postgres(pog.Connection)
  Sqlite(sqlight.Connection)
}

pub type Context {
  Context(config: Config, db: DB)
}

pub type Config {
  Config(port: Int, db_pass: String, db_uri: String, db_table: String)
}

pub type Err {
  Err(code: Int, message: String, log: String)
}

pub fn get_context(config: Config) -> Result(Context, Err) {
  case string.starts_with(config.db_uri, "postgresql://") {
    False -> {
      use conn <- given.ok(sqlight.open(config.db_uri), fn(err) {
        Error(Err(500, "Failed to open sqlite db", string.inspect(err)))
      })
      Ok(Context(config:, db: Sqlite(conn)))
    }
    True -> {
      use database_url <- result.try(
        pog.url_config(config.db_uri)
        |> result.replace_error(Err(
          500,
          "Error parsing database string",
          config.db_uri,
        )),
      )
      let db =
        database_url
        |> pog.password(option.Some(config.db_pass))
        |> pog.connect
      Ok(Context(config:, db: Postgres(db)))
    }
  }
}
