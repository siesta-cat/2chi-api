import app
import mungo

pub fn get_context(config: app.Config) -> app.Context {
  let assert Ok(client) =
    mungo.start(
      "mongodb://"
        <> config.db_user
        <> ":"
        <> config.db_pass
        <> "@"
        <> config.db_host
        <> "/"
        <> config.db_name
        <> "?authSource=admin",
      config.db_timeout,
    )

  let collection = mungo.collection(client, config.db_collection_name)

  app.Context(config:, collection:)
}
