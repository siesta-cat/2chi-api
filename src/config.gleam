import app
import envoy
import gleam/int
import gleam/result

pub fn load_from_env() -> Result(app.Config, String) {
  let port = result.unwrap(read_env_var("PORT", int.parse), 8000)
  let db_timeout = result.unwrap(read_env_var("DB_TIMEOUT", int.parse), 512)
  let db_collection_name =
    result.unwrap(read_env_var("DB_COLLECTION_NAME", Ok), "images")

  use db_host <- result.try(read_env_var("DB_HOST", Ok))
  use db_name <- result.try(read_env_var("DB_NAME", Ok))
  use db_user <- result.try(read_env_var("DB_USER", Ok))
  use db_pass <- result.try(read_env_var("DB_PASS", Ok))
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
  read_fun: fn(String) -> Result(a, error),
) -> Result(a, String) {
  envoy.get(name)
  |> result.replace_error("Env var '" <> name <> "' not found")
  |> result.map(fn(value) {
    read_fun(value)
    |> result.replace_error("Incorrect value for env var '" <> name <> "'")
  })
  |> result.flatten()
}
