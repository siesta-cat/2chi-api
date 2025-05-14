import config
import gleam/json
import gleeunit/should
import image/image
import router
import twochi_api_test
import wisp/testing

pub fn get_image_returns_valid_images_test() {
  let assert Ok(config) = config.load_from_env()

  let id = twochi_api_test.get_first_image_id(config)

  let response =
    router.handle_request(testing.get("/images/" <> id, []), config)
  response.status |> should.equal(200)
  let json = response |> testing.string_body()
  let assert Ok(_) = json.parse(json, image.decoder())
}

pub fn get_image_nonexistant_returns_404_test() {
  let assert Ok(config) = config.load_from_env()

  let id = "0000000000000000000000000000000000000000"

  let response =
    router.handle_request(testing.get("/images/" <> id, []), config)
  response.status |> should.equal(404)
}

pub fn get_image_returns_400_on_invalid_id_test() {
  let assert Ok(config) = config.load_from_env()

  let response =
    router.handle_request(testing.get("/images/98439384", []), config)
  response.status |> should.equal(400)
}
