import config
import gleam/json
import gleeunit/should
import image/image
import image/status
import router
import wisp/testing

pub fn post_images_returns_400_for_malformed_requests_test() {
  let assert Ok(config) = config.load_from_env()

  let image =
    image.Image(
      id: "irrelevant",
      url: "https://test.url.com/2",
      status: status.Available,
      tags: ["2girl", "sleeping"],
    )

  let invalid_image =
    json.object([
      #("url", json.string(image.url)),
      #("status", json.string("invalid_status")),
      #("tags", json.array(image.tags, of: json.string)),
    ])
    |> json.to_string()

  let response =
    router.handle_request(testing.post("/images", [], invalid_image), config)
  response.status |> should.equal(400)
}

pub fn post_images_returns_409_for_repeated_requests_test() {
  let assert Ok(config) = config.load_from_env()

  let image =
    image.Image(
      id: "irrelevant",
      url: "https://test.url.com/2",
      status: status.Available,
      tags: ["2girl", "sleeping"],
    )

  let image_json = image.to_json_without_id(image)

  router.handle_request(testing.post("/images", [], image_json), config)

  let response =
    router.handle_request(testing.post("/images", [], image_json), config)
  response.status |> should.equal(409)
}

pub fn post_images_returns_201_test() {
  let assert Ok(config) = config.load_from_env()

  let image =
    image.Image(
      id: "irrelevant",
      url: "https://test.url.com/1",
      status: status.Available,
      tags: ["2girl", "sleeping"],
    )

  let image_json = image.to_json_without_id(image)

  let response =
    router.handle_request(testing.post("/images", [], image_json), config)
  response.status |> should.equal(201)
}
