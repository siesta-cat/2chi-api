import app
import gleam/result
import glenvy/env

pub fn load_from_env() -> Result(app.Config, String) {
  use port <- result.try(read_env_var("PORT", env.get_int))
  Ok(app.Config(port:))
}

fn read_env_var(
  name: String,
  read_fun: fn(String) -> Result(a, env.Error),
) -> Result(a, String) {
  read_fun(name)
  |> result.replace_error("Incorrect value for env var '" <> name <> "'")
}
