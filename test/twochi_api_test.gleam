import gleam/dynamic/decode
import gleam/json
import gleam/list
import gleeunit
import image/image
import router
import wisp/testing

pub fn main() {
  gleeunit.main()
}

pub fn images_decoder() {
  use images <- decode.field("images", decode.list(image.decoder()))
  decode.success(images)
}

pub fn get_first_image_id(ctx) -> String {
  let response = router.handle_request(testing.get("/images", []), ctx)
  let json = response |> testing.string_body()
  let assert Ok(images) = json.parse(json, images_decoder())

  let assert Ok(image) = list.first(images)
  image.id
}
