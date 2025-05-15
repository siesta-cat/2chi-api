import app
import context
import given
import gleam/http
import gleam/int
import gleam/json
import gleam/string
import gleam/string_tree
import image/image
import images
import wisp.{type Request, type Response}

fn error_handle(err: app.Err) -> Response {
  case err {
    app.Err(code, message, log) -> {
      wisp.log_info(
        string.concat(["Error ", int.to_string(code), " ", message, ": ", log]),
      )
      let json =
        json.object([
          #("code", json.int(code)),
          #("error", json.string(message)),
        ])
      wisp.json_response(json.to_string_tree(json), code)
    }
  }
}

pub fn handle_request(req: Request, ctx: context.Context) -> Response {
  use <- wisp.log_request(req)
  use <- wisp.rescue_crashes
  use req <- wisp.handle_head(req)

  case wisp.path_segments(req) {
    ["health"] -> wisp.html_response(string_tree.from_string("Ready"), 200)
    ["images"] -> handle_images(req, ctx)
    ["images", id] -> handle_image(id, req, ctx)
    _ -> wisp.not_found()
  }
}

fn handle_images(request: Request, ctx: context.Context) -> Response {
  case request.method {
    http.Get -> {
      let params = wisp.get_query(request)
      use images <- given.ok(images.get(params, ctx), else_return: error_handle)
      wisp.json_response(
        json.object([#("images", json.array(images, image.to_json))])
          |> json.to_string_tree,
        200,
      )
    }
    http.Post -> {
      use json <- wisp.require_string_body(request)
      use image <- given.ok(
        images.add(image: json, context: ctx),
        else_return: error_handle,
      )
      wisp.json_response(
        image.to_json(image)
          |> json.to_string_tree,
        201,
      )
    }
    _ -> wisp.method_not_allowed(allowed: [http.Get, http.Post])
  }
}

fn handle_image(id: String, request: Request, ctx: context.Context) -> Response {
  use image <- given.ok(images.get_image(id, ctx), else_return: error_handle)

  case request.method {
    http.Get ->
      wisp.json_response(image.to_json(image) |> json.to_string_tree(), 200)
    http.Put -> {
      use json <- wisp.require_string_body(request)
      use _ <- given.ok(
        images.modify(image: image, patch: json, context: ctx),
        else_return: error_handle,
      )
      wisp.response(204)
    }
    _ -> wisp.method_not_allowed(allowed: [http.Get, http.Put])
  }
}
