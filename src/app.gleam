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
