import app
import gleam/io
import mungo

pub fn get_context(config: app.Config) -> app.Context {
  io.println("MongoDB connection string: ")
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
  let assert Ok(client) =
    mungo.start(conection_string |> io.debug, config.db_timeout)

  io.println("MongoDB collection: ")
  let collection =
    mungo.collection(client, config.db_collection_name) |> io.debug

  app.Context(config:, collection:)
}
