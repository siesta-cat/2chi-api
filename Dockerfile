FROM --platform=$BUILDPLATFORM ghcr.io/gleam-lang/gleam:v1.10.0-erlang-slim AS deps
WORKDIR /app

COPY gleam.toml manifest.toml /app/
RUN gleam update

COPY ./src/ /app/src/

FROM deps AS test
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
  --mount=type=cache,target=/var/lib/apt,sharing=locked \
  apt-get update && apt-get --no-install-recommends install -y ca-certificates build-essential
COPY ./test/ /app/test/
RUN --mount=type=cache,target=/app/build gleam build && cp -r /app/build/dev/ /tmp/dev
RUN mv /tmp/dev /app/build/dev

FROM deps AS build
RUN gleam export erlang-shipment

FROM ghcr.io/gleam-lang/gleam:v1.10.0-erlang-slim AS final
WORKDIR /app
RUN apt-get update && apt-get --no-install-recommends install -y ca-certificates build-essential  && rm -rf /var/lib/apt/lists/*
COPY --from=build /app/build/erlang-shipment .

EXPOSE 8000

ENTRYPOINT ["/app/entrypoint.sh"]
CMD ["run"]
