import config
import context
import gleam/dynamic/decode
import gleam/json
import gleam/list
import gleeunit
import image/image
import router
import storage
import wisp/testing

pub fn main() {
  let assert Ok(config) = config.load_from_env()
  let assert Ok(ctx) = context.get_context(config)

  let insert = "INSERT INTO " <> config.db_table <> " (id, url, status) VALUES
  (
		'e9a618f8dbccbd29ff4df62bec051e45533ccceb',
    'testing.com',
    'unavailable'
	),
  (
		'5bba55db4d1b6bbb9e0b6d1eb3eca0fc3ef9a906',
    'testing.org',
    'available'
  ),
  (
		'3725e96f0e0d3f5e60bfa32e30aba597ad72b514',
    'testing.net',
    'consumed'
  ) ON CONFLICT (url) DO NOTHING;"

  let assert Ok(_) = storage.run_query(insert, ctx.db, decode.success(Nil))

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
