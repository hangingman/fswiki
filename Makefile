.PHONY: all run build raku-test raku-run raku-dev

raku-dev:
	FSWIKI_DEV_HOST=127.0.0.1 FSWIKI_DEV_PORT=8081 $(HOME)/.raku/bin/cro run

raku-test:
	raku -I raku/lib raku/t/core.t
	raku -I raku/lib raku/t/http-health.t
	raku -I raku/lib raku/t/http-source.t
	raku -I raku/lib raku/t/storage-memory.t
	raku -I raku/lib raku/t/storage-file.t

raku-run:
	raku -I raku/lib -e 'use FSWiki::HTTP::App; start-server(:port(8081))'

run:
	docker compose down
	docker compose up -d --build
	ssh-keygen -f "$${HOME}/.ssh/known_hosts" -R "10.33.1.1"
	ssh-keygen -f "$${HOME}/.ssh/known_hosts" -R "10.33.1.2"

build:
	docker compose build --no-cache
