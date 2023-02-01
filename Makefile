love_bin:=./nodeworks/download/love2d.appimage

$(love_bin):
	make -C nodeworks download

download: $(love_bin)

play: build
	love .
	
test: $(love_bin)
	$(love_bin) . test

build:
	make -C art


.PHONY: test
