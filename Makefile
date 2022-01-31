.PHONY: config

all: build run

build:
	docker-compose -f docker-compose-heroku.yml build

build-no-cache:
	docker-compose -f docker-compose-heroku.yml build --no-cache

run:
	docker-compose -f docker-compose-heroku.yml up

cgroups:
	sudo mkdir -p /sys/fs/cgroup/systemd
	sudo mount -t cgroup -o none,name=systemd cgroup /sys/fs/cgroup/systemd

config:
	docker-compose -f docker-compose-heroku.yml config
