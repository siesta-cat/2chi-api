.PHONY: test

run:
	docker compose down -v
	docker compose up --build

test:
	docker compose down -v
	docker compose run --build twochi-api-sqlite sh -c "sleep 10 && gleam test" && \
	docker compose run --build twochi-api-postgres sh -c "sleep 10 && gleam test"

