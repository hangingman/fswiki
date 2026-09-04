.PHONY: all run build raku-test

raku-test:
	raku -I raku/lib raku/t/core.t

run:
	docker compose down
	docker compose up -d --build
	ssh-keygen -f "$${HOME}/.ssh/known_hosts" -R "10.33.1.1"
	ssh-keygen -f "$${HOME}/.ssh/known_hosts" -R "10.33.1.2"

build:
	docker compose build --no-cache
