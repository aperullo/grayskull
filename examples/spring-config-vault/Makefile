.DEFAULT_GOAL := all


.PHONY: build-svr
build-svr:
	cd ./demo_svr && \
	docker build -t spring-svr -f Dockerfile .


.PHONY: build-client
build-client:
	cd ./demo_client && \
	docker build -t spring-client -f Dockerfile .

all: build-svr build-client
