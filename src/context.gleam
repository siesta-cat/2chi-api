import app
import gleam/result
import gleam/string
import mungo

pub fn get_context(config: app.Config) -> Result(app.Context, app.Error) {
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
      app.Error(
        500,
        "Error connecting to database",
        config.db_host <> "Recieved error: " <> string.inspect(err),
      )
    }),
  )

  let collection = mungo.collection(client, config.db_collection_name)

  Ok(app.Context(config:, collection:))
}
