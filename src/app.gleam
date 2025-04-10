import gleam/result
import gleam/string
import mungo
import mungo/client

pub type Context {
  Context(config: Config, collection: client.Collection)
}

pub type Config {
  Config(
    port: Int,
    db_timeout: Int,
    db_user: String,
    db_pass: String,
    db_host: String,
    db_name: String,
    db_collection_name: String,
  )
}

pub type Error {
  Error(code: Int, message: String, log: String)
}

pub fn get_context(config: Config) -> Result(Context, Error) {
  let conection_string =
    "mongodb://"
    <> config.db_user
    <> ":"
    <> config.db_pass
    <> "@"
    <> config.db_host
    <> "/"
    <> config.db_name
    <> "?authSource=admin"
  use client <- result.try(
    mungo.start(conection_string, config.db_timeout)
    |> result.map_error(fn(err) {
      Error(
        500,
        "Error connecting to database",
        config.db_host <> "Recieved error: " <> string.inspect(err),
      )
    }),
  )

  let collection = mungo.collection(client, config.db_collection_name)

  Ok(Context(config:, collection:))
}
