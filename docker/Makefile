SHELL=/bin/bash

IMG_NAME  ?= md2texpdf
IMG_VER   ?= 0.8
CONT_NAME ?= $(IMG_NAME)


IMG_HASH=$(shell docker image ls -q $(IMG_NAME):$(IMG_VER))
WORK_DIR=$(shell realpath $(PWD))

.PHONY: all
all: run

.PHONY: build
build:
	[[ -n "$(IMG_HASH)" ]] || \
		time docker build -t '$(IMG_NAME):$(IMG_VER)' .

.PHONY: run
run: build
	docker run --rm \
		-v '$(WORK_DIR)/:/work' --workdir=/work \
		--name $(CONT_NAME) -it '$(IMG_NAME):$(IMG_VER)'

.PHONY: clean
clean:
	[[ -z "$(IMG_HASH)" ]] || \
		docker rmi '$(IMG_NAME):$(IMG_VER)'

.PHONY: connect connectasroot
connect:
	docker exec -u user -it $(CONT_NAME) /bin/bash
connectasroot:
	docker exec -it $(CONT_NAME) /bin/bash
