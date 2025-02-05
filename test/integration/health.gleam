import app
import gleeunit/should
import router
import wisp/testing

pub fn get_health_test() {
  let config = app.Config(port: 8000)
  let ctx = app.Context(config:)

  let response = router.handle_request(testing.get("/health", []), ctx)
  response.status |> should.equal(200)
}
