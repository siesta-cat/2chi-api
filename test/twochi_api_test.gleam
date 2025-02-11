import gleam/dynamic/decode
import gleeunit
import image

pub fn main() {
  gleeunit.main()
}

pub fn images_decoder() {
  use images <- decode.field("images", decode.list(image.decoder()))
  decode.success(images)
}
