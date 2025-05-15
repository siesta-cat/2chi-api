import app
import envoy
import gleam/int
import gleam/result

pub fn load_from_env() -> Result(app.Config, String) {
  let port = result.unwrap(read_env_var("PORT", int.parse), 8000)
  let db_table = result.unwrap(read_env_var("DB_TABLE", Ok), "images")
  let db_uri = result.unwrap(read_env_var("DB_URI", Ok), "sqlite.db")
  let db_pass = result.unwrap(read_env_var("DB_PASS", Ok), "")

  Ok(app.Config(port:, db_table:, db_uri:, db_pass:))
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
