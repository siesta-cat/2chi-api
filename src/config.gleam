import app
import gleam/result
import glenvy/env

pub fn load_from_env() -> Result(app.Config, String) {
  let port = result.unwrap(read_env_var("PORT", env.get_int), 8000)
  let db_timeout = result.unwrap(read_env_var("DB_TIMEOUT", env.get_int), 512)
  let db_collection_name =
    result.unwrap(read_env_var("DB_COLLECTION_NAME", env.get_string), "images")

  use db_host <- result.try(read_env_var("DB_HOST", env.get_string))
  use db_name <- result.try(read_env_var("DB_NAME", env.get_string))
  use db_user <- result.try(read_env_var("DB_USER", env.get_string))
  use db_pass <- result.try(read_env_var("DB_PASS", env.get_string))
  Ok(app.Config(
    port:,
    db_timeout:,
    db_collection_name:,
    db_host:,
    db_name:,
    db_pass:,
    db_user:,
  ))
}

fn read_env_var(
  name: String,
  read_fun: fn(String) -> Result(a, env.Error),
) -> Result(a, String) {
  read_fun(name)
  |> result.replace_error("Incorrect value for env var '" <> name <> "'")
}
