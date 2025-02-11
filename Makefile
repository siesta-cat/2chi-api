.PHONY: test

run:
	docker compose down -v
	docker compose run --build twochi-api

test:
	docker compose down -v
	docker compose run --build twochi-api sh -c "sleep 2 && gleam test"
