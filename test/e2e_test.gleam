import config
import gleam/json
import gleeunit/should
import image/image
import image/status
import router
import wisp/testing

pub fn end_to_end_test() {
  let assert Ok(config) = config.load_from_env()

  let original_image =
    image.Image(
      id: "irrelevant",
      url: "https://test.url.com/e2etest",
      status: status.Available,
      tags: ["2girl", "sleeping"],
    )

  let image_json = image.to_json_without_id(original_image)

  let response =
    router.handle_request(testing.post("/images", [], image_json), config)
  let json = response |> testing.string_body()
  let assert Ok(posted_image) = json.parse(json, image.decoder())

  posted_image.url |> should.equal(original_image.url)
  posted_image.status |> should.equal(original_image.status)
  posted_image.tags |> should.equal(original_image.tags)

  let image_id = posted_image.id

  let response =
    router.handle_request(testing.get("/images/" <> image_id, []), config)
  let json = response |> testing.string_body()
  let assert Ok(gotten_image) = json.parse(json, image.decoder())

  gotten_image |> should.equal(posted_image)

  let patch =
    json.object([#("status", json.string(status.to_string(status.Consumed)))])
    |> json.to_string()

  router.handle_request(testing.put("/images/" <> image_id, [], patch), config)
  let response =
    router.handle_request(testing.get("/images/" <> image_id, []), config)
  let json = response |> testing.string_body()
  let assert Ok(patched_image) = json.parse(json, image.decoder())

  patched_image.url |> should.equal(gotten_image.url)
  patched_image.tags |> should.equal(gotten_image.tags)
  patched_image.status |> should.equal(status.Consumed)
}
