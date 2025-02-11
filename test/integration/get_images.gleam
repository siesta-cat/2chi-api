import config
import context
import gleam/dynamic
import gleam/dynamic/decode
import gleam/int
import gleam/json
import gleam/list
import gleeunit/should
import router
import status
import twochi_api_test
import wisp/testing

pub fn get_images_returns_valid_images_test() {
  let assert Ok(config) = config.load_from_env()

  let ctx = context.get_context(config)

  let response =
    router.handle_request(
      testing.get("/images?limit=3&status=available", []),
      ctx,
    )
  response.status |> should.equal(200)
  let json = response |> testing.string_body()
  let assert Ok(_) = json.parse(json, twochi_api_test.images_decoder())
}

pub fn get_images_status_retuns_only_status_test() {
  let assert Ok(config) = config.load_from_env()

  let ctx = context.get_context(config)

  let statuses = ["consumed", "available", "unavailable"]

  let assert Ok(status) =
    list.first(list.drop(statuses, int.random(list.length(statuses)) - 1))

  let response =
    router.handle_request(testing.get("/images?status=" <> status, []), ctx)
  response.status |> should.equal(200)
  let json = response |> testing.string_body()
  let assert Ok(images) = json.parse(json, twochi_api_test.images_decoder())
  let assert Ok(status) = decode.run(dynamic.from(status), status.decoder())

  list.map(images, fn(image) { image.status |> should.equal(status) })
}

pub fn get_images_returns_400_on_invalid_status_test() {
  let assert Ok(config) = config.load_from_env()

  let ctx = context.get_context(config)

  let response =
    router.handle_request(testing.get("/images?status=foo", []), ctx)
  response.status |> should.equal(400)
}

pub fn get_images_returns_400_on_float_limit_test() {
  let assert Ok(config) = config.load_from_env()

  let ctx = context.get_context(config)

  let response =
    router.handle_request(testing.get("/images?limit=2.4", []), ctx)
  response.status |> should.equal(400)
}

pub fn get_images_returns_400_on_negative_limit_test() {
  let assert Ok(config) = config.load_from_env()

  let ctx = context.get_context(config)

  let response = router.handle_request(testing.get("/images?limit=-1", []), ctx)
  response.status |> should.equal(400)
}

pub fn get_images_returns_400_on_nan_limit_test() {
  let assert Ok(config) = config.load_from_env()

  let ctx = context.get_context(config)

  let response =
    router.handle_request(testing.get("/images?limit=foo", []), ctx)
  response.status |> should.equal(400)
}

pub fn get_images_limit_retuns_limit_or_less_test() {
  let assert Ok(config) = config.load_from_env()

  let ctx = context.get_context(config)

  let limit = 1

  let response =
    router.handle_request(
      testing.get("/images?limit=" <> int.to_string(limit), []),
      ctx,
    )
  response.status |> should.equal(200)
  let json = response |> testing.string_body()
  let assert Ok(images) = json.parse(json, twochi_api_test.images_decoder())

  should.be_true(list.length(images) <= limit)
}

pub fn get_images_limit_zero_retuns_all() {
  let assert Ok(config) = config.load_from_env()

  let ctx = context.get_context(config)

  let response = router.handle_request(testing.get("/images?limit=0", []), ctx)
  response.status |> should.equal(200)
  let json = response |> testing.string_body()
  let assert Ok(images_limit) =
    json.parse(json, twochi_api_test.images_decoder())

  let response = router.handle_request(testing.get("/images", []), ctx)
  response.status |> should.equal(200)
  let json = response |> testing.string_body()
  let assert Ok(images_nolimit) =
    json.parse(json, twochi_api_test.images_decoder())

  images_limit |> should.equal(images_nolimit)
}
