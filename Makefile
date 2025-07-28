.PHONY: all run build deps test lint

run:
	docker compose down
	docker compose up -d --build

build:
	docker compose build --no-cache

deps:
	docker compose -f docker-compose.dev.yml up -d
	docker compose -f docker-compose.dev.yml exec dev carton install

test: deps
	docker compose -f docker-compose.dev.yml exec dev carton exec prove -l -Ilib -I. -r t

lint: deps
	docker compose -f docker-compose.dev.yml exec dev perlcritic lib plugin
