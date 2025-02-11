import config
import context
import gleeunit/should
import router
import wisp/testing

pub fn get_health_test() {
  let assert Ok(config) = config.load_from_env()

  let ctx = context.get_context(config)

  let response = router.handle_request(testing.get("/health", []), ctx)
  response.status |> should.equal(200)
}
