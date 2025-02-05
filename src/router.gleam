import app
import gleam/string_tree
import wisp.{type Request, type Response}

pub fn handle_request(req: Request, ctx: app.Context) -> Response {
  use <- wisp.log_request(req)
  use <- wisp.rescue_crashes
  use req <- wisp.handle_head(req)

  case wisp.path_segments(req) {
    ["health"] -> wisp.html_response(string_tree.from_string("Ready"), 200)
    _ -> wisp.not_found()
  }
}
