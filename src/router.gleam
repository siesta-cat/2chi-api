import app
import given
import gleam/bool
import gleam/dynamic
import gleam/dynamic/decode
import gleam/http.{Get, Post, Put}
import gleam/int
import gleam/json
import gleam/list
import gleam/option
import gleam/result
import gleam/string_tree
import image.{type Image}
import status
import storage
import wisp.{type Request, type Response}

pub fn handle_request(req: Request, ctx: app.Context) -> Response {
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

fn handle_images(request: Request, ctx: app.Context) -> Response {
  case request.method {
    Get -> {
      use images <- given.ok(
        get_images(request, ctx),
        else_return: error_handle,
      )
      wisp.json_response(
        json.object([#("images", json.array(images, image.to_json))])
          |> json.to_string_tree,
        200,
      )
    }
    Post -> todo
    _ -> wisp.method_not_allowed(allowed: [Get, Post])
  }
}

fn get_images(request: Request, ctx: app.Context) -> Result(List(Image), String) {
  let params = wisp.get_query(request)

  use limit <- result.try(
    list.find_map(params, fn(item) {
      let #(key, value) = item
      case key == "limit" {
        False -> Error(Nil)
        True -> Ok(value)
      }
    })
    |> result.unwrap("0")
    |> int.parse()
    |> result.replace_error("400"),
  )

  use <- bool.guard(limit < 0, Error("400"))

  let status =
    list.find_map(params, fn(item) {
      let #(key, value) = item
      case key == "status" {
        False -> Error(Nil)
        True -> Ok(value)
      }
    })
    |> option.from_result()

  use _ <- result.try(case status {
    option.None -> {
      Ok(Nil)
    }
    option.Some(status) -> {
      decode.run(dynamic.from(status), status.decoder())
      |> result.replace_error("400")
      |> result.replace(Nil)
    }
  })

  use images <- result.try(storage.get_images(limit, status, ctx))

  Ok(images)
}

fn error_handle(err: String) -> Response {
  case err {
    "400" -> wisp.bad_request()
    "404" -> wisp.not_found()
    "500" -> wisp.internal_server_error()
    _ -> wisp.internal_server_error()
  }
}

fn handle_image(id: String, request: Request, ctx: app.Context) -> Response {
  use image <- given.ok(storage.get_image(id, ctx), else_return: error_handle)

  case request.method {
    Get ->
      wisp.json_response(image.to_json(image) |> json.to_string_tree(), 200)
    Put -> todo
    _ -> wisp.method_not_allowed(allowed: [Get, Put])
  }
}
