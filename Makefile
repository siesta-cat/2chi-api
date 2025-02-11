.PHONY: test

run:
	docker compose down -v
	docker compose up --build

test:
	docker compose down -v
	docker compose run --build twochi-api sh -c "sleep 2 && gleam test"
