import app
import gleam/result
import mungo

pub fn get_context(config: app.Config) -> Result(app.Context, String) {
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
    |> result.replace_error("500"),
  )

  let collection = mungo.collection(client, config.db_collection_name)

  Ok(app.Context(config:, collection:))
}
