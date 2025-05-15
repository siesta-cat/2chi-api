pub type Config {
  Config(port: Int, db_pass: String, db_uri: String, db_table: String)
}

pub type Err {
  Err(code: Int, message: String, log: String)
}
