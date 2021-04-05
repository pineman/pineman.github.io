build:
	mkdir -p http/build
	rm -rf http/build/*
	cp -r src/* http/build
	yarn install
	yarn build

frontend: build
	yarn start

backend: build
	docker-compose up
