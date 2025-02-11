import config
import context
import gleam/json
import gleam/list
import gleeunit/should
import image
import router
import twochi_api_test
import wisp/testing

pub fn get_image_returns_valid_images_test() {
  let assert Ok(config) = config.load_from_env()

  let ctx = context.get_context(config)

  let response = router.handle_request(testing.get("/images", []), ctx)
  let json = response |> testing.string_body()
  let assert Ok(images) = json.parse(json, twochi_api_test.images_decoder())

  let assert Ok(image) = list.first(images)
  let id = image.id

  let response = router.handle_request(testing.get("/images/" <> id, []), ctx)
  response.status |> should.equal(200)
  let json = response |> testing.string_body()
  let assert Ok(_) = json.parse(json, image.decoder())
}

pub fn get_image_nonexistant_returns_404_test() {
  let assert Ok(config) = config.load_from_env()

  let ctx = context.get_context(config)

  let id = "000000000000000000000000"

  let response = router.handle_request(testing.get("/images/" <> id, []), ctx)
  response.status |> should.equal(404)
}

pub fn get_image_returns_400_on_invalid_id_test() {
  let assert Ok(config) = config.load_from_env()

  let ctx = context.get_context(config)

  let response = router.handle_request(testing.get("/images/98439384", []), ctx)
  response.status |> should.equal(400)
}
