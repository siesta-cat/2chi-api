import config
import gleeunit/should
import router
import wisp/testing

pub fn get_health_test() {
  let assert Ok(config) = config.load_from_env()

  let response = router.handle_request(testing.get("/health", []), config)
  response.status |> should.equal(200)
}
