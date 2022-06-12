.PHONY: all run build

run:
	docker compose up -d --build
	ssh-keygen -f "$${HOME}/.ssh/known_hosts" -R "10.33.1.1"
	ssh-keygen -f "$${HOME}/.ssh/known_hosts" -R "10.33.1.2"

build:
	docker compose build --no-cache
