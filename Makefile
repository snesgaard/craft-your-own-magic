test:
	love . test

build:
	make -C art

play: build
	love .

.PHONY: test
