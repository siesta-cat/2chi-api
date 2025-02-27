import config
import gleam/json
import gleeunit/should
import image/status
import router
import twochi_api_test
import wisp/testing

pub fn put_image_returns_204_on_valid_patch_test() {
  let assert Ok(config) = config.load_from_env()

  let id = twochi_api_test.get_first_image_id(config)

  let patch =
    json.object([#("status", json.string(status.to_string(status.Available)))])
    |> json.to_string()

  let response =
    router.handle_request(testing.put("/images/" <> id, [], patch), config)
  response.status |> should.equal(204)
}

pub fn put_image_nonexistant_returns_404_test() {
  let assert Ok(config) = config.load_from_env()

  let id = "000000000000000000000000"

  let patch =
    json.object([#("status", json.string(status.to_string(status.Available)))])
    |> json.to_string()

  let response =
    router.handle_request(testing.put("/images/" <> id, [], patch), config)
  response.status |> should.equal(404)
}

pub fn put_image_invalid_id_returns_400_test() {
  let assert Ok(config) = config.load_from_env()

  let id = "98439384"

  let patch =
    json.object([#("status", json.string(status.to_string(status.Available)))])
    |> json.to_string()

  let response =
    router.handle_request(testing.put("/images/" <> id, [], patch), config)
  response.status |> should.equal(400)
}

pub fn put_image_invalid_patch_returns_400_test() {
  let assert Ok(config) = config.load_from_env()

  let id = twochi_api_test.get_first_image_id(config)

  let patch =
    json.object([#("status", json.string("invalid_status"))])
    |> json.to_string()

  let response =
    router.handle_request(testing.put("/images/" <> id, [], patch), config)
  response.status |> should.equal(400)
}

pub fn put_image_patch_changing_url_returns_400_test() {
  let assert Ok(config) = config.load_from_env()

  let id = twochi_api_test.get_first_image_id(config)

  let patch =
    json.object([#("url", json.string("https://test.url.com/3"))])
    |> json.to_string()

  let response =
    router.handle_request(testing.put("/images/" <> id, [], patch), config)
  response.status |> should.equal(400)
}
