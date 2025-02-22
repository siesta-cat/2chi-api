import app
import context
import given
import gleam/http.{Get, Post, Put}
import gleam/json
import gleam/string_tree
import image
import images
import wisp.{type Request, type Response}

fn error_handle(err: String) -> Response {
  case err {
    "400" -> wisp.bad_request()
    "404" -> wisp.not_found()
    "500" -> wisp.internal_server_error()
    "409" -> wisp.response(409)
    _ -> wisp.internal_server_error()
  }
}

pub fn handle_request(req: Request, config: app.Config) -> Response {
  use <- wisp.log_request(req)
  use <- wisp.rescue_crashes
  use req <- wisp.handle_head(req)

  use ctx <- given.ok(context.get_context(config), else_return: error_handle)

  case wisp.path_segments(req) {
    ["health"] -> wisp.html_response(string_tree.from_string("Ready"), 200)
    ["images"] -> handle_images(req, ctx)
    ["images", id] -> handle_image(id, req, ctx)
    _ -> wisp.not_found()
  }
}

fn handle_images(request: Request, ctx: app.Context) -> Response {
  case request.method {
    Get -> {
      let params = wisp.get_query(request)
      use images <- given.ok(images.get(params, ctx), else_return: error_handle)
      wisp.json_response(
        json.object([#("images", json.array(images, image.to_json))])
          |> json.to_string_tree,
        200,
      )
    }
    Post -> {
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
    _ -> wisp.method_not_allowed(allowed: [Get, Post])
  }
}

fn handle_image(id: String, request: Request, ctx: app.Context) -> Response {
  use image <- given.ok(images.get_image(id, ctx), else_return: error_handle)

  case request.method {
    Get ->
      wisp.json_response(image.to_json(image) |> json.to_string_tree(), 200)
    Put -> {
      use json <- wisp.require_string_body(request)
      use _ <- given.ok(
        images.modify(image: image, patch: json, context: ctx),
        else_return: error_handle,
      )
      wisp.response(204)
    }
    _ -> wisp.method_not_allowed(allowed: [Get, Put])
  }
}
