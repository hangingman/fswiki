.PHONY: config

all: build run

build:
	docker-compose -f docker-compose-heroku.yml build

build-no-cache:
	docker-compose -f docker-compose-heroku.yml build --no-cache

run-all:
	docker-compose -f docker-compose-heroku.yml up

run-wiki:
	docker-compose -f docker-compose-heroku.yml up wiki

run-db:
	docker-compose -f docker-compose-heroku.yml up db

down:
	docker-compose -f docker-compose-heroku.yml down

cgroups:
	sudo mkdir -p /sys/fs/cgroup/systemd
	sudo mount -t cgroup -o none,name=systemd cgroup /sys/fs/cgroup/systemd

config:
	docker-compose -f docker-compose-heroku.yml config
