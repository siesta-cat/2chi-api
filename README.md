# twochi_api

## Introduction

The function of the API is basically to access the images' metadata stored in the database.

## Usage

The API exposes some endpoints to interact with the database.

### GET `/images`

Allows to get a list of image documents.

#### Query params

- `limit`: an optional parameter, which accepts a non-negative integer that dictates the number of documents that the list will have. If its value is equal to `0`, or if this parameter is missing, the endpoint will return all the image documents in the database.
- `status`: an optional parameter, which accepts the values `consumed`, `available` and `unavailable`. It filters the documents that have only the `status` attribute equal to that indicated in the parameter's value. If the parameter is missing, no filter will be applied to the document.

#### Example

- `GET /images?limit=5&status=available` will return 5 documents that have the `available` value in their `status` attribute.

### GET `/images/<id>`

Allows to get an image document.

#### Params

- `id`: the id of the document to be modified.

#### Example

`GET /images/61f7e48f0c651345677b7775` will get the document referenced by the `id` param.

### PUT `/images/<id>`

Modifies an existing image document. The request must provide a JSON-formatted body, with one or more valid document attributes. The existing document attributes will be replaced with the provided new ones.

#### Params

- `id`: the id of the document to be modified.

#### Example

- `PUT /images/61f7e48f0c651345677b7775` with body `{ "status": "consumed" }` will modify the document referenced by the `id` param, changing their `status` value to `consumed`.

### POST `/images`

Allows to insert a new image document.

#### Example

`POST /images` with body `{ "url": "https://my-images.com/foo.jpg", "status": "available", "tags": ["foo", "bar"] }` will insert the image passed on the request body into the database.

## Installation

To install dependencies:

```bash
bun install
```

To run:

```bash
bun run dev
```

For testing, remember:

```bash
bun run test
```

This project was created using `bun init` in bun v1.0.13. [Bun](https://bun.sh) is a fast all-in-one JavaScript runtime.

## Running the tests

`make test`

## Running locally

`make run`
