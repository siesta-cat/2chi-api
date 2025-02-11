import app
import bison/bson
import bison/ejson
import given
import gleam/bit_array
import gleam/bool
import gleam/dict
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
    Post -> {
      use image <- given.ok(post_image(request, ctx), else_return: error_handle)
      wisp.json_response(
        image.to_json(image)
          |> json.to_string_tree,
        201,
      )
    }
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
    "409" -> wisp.response(409)
    _ -> wisp.internal_server_error()
  }
}

fn handle_image(id: String, request: Request, ctx: app.Context) -> Response {
  use image <- given.ok(storage.get_image(id, ctx), else_return: error_handle)

  case request.method {
    Get ->
      wisp.json_response(image.to_json(image) |> json.to_string_tree(), 200)
    Put -> {
      use _ <- given.ok(
        put_image(image, request, ctx),
        else_return: error_handle,
      )
      wisp.response(204)
    }
    _ -> wisp.method_not_allowed(allowed: [Get, Put])
  }
}

fn put_image(
  image: Image,
  request: Request,
  ctx: app.Context,
) -> Result(Nil, String) {
  use body <- result.try(
    wisp.read_body_to_bitstring(request)
    |> result.replace_error("400"),
  )
  use json <- result.try(
    bit_array.to_string(body) |> result.replace_error("400"),
  )

  use bson <- result.try(
    ejson.from_canonical(json)
    |> result.replace_error("400"),
  )

  // Cannot edit url
  use <- bool.guard(dict.has_key(bson, "url"), Error("400"))

  // Must contain valid status if has one
  use <- bool.guard(
    case dict.get(bson, "status") {
      Error(_) -> False
      Ok(status) -> {
        case status {
          bson.String(status) -> {
            case decode.run(dynamic.from(status), status.decoder()) {
              Error(_) -> True
              Ok(_) -> False
            }
          }
          _ -> True
        }
      }
    },
    Error("400"),
  )

  use _ <- result.try(storage.put_image(image, json, ctx))

  Ok(Nil)
}

fn post_image(request: Request, ctx: app.Context) -> Result(Image, String) {
  use body <- result.try(
    wisp.read_body_to_bitstring(request)
    |> result.replace_error("400"),
  )
  use json <- result.try(
    bit_array.to_string(body) |> result.replace_error("400"),
  )

  use image <- given.ok(json.parse(json, image.decoder()), fn(_) {
    Error("400")
  })

  use bson <- result.try(
    ejson.from_canonical(json)
    |> result.replace_error("400"),
  )

  use current_images <- result.try(storage.get_images(0, option.None, ctx))

  use <- bool.guard(
    list.any(current_images, fn(current_image) {
      current_image.url == image.url
    }),
    Error("409"),
  )

  use image <- result.try(storage.post_image(bson, ctx))

  Ok(image)
}
