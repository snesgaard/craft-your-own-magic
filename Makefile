play: build
	love .
	
test:
	love . test

build:
	make -C art


.PHONY: test
