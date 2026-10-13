PREFIX ?= $(HOME)/.local
BINDIR := $(PREFIX)/bin

.PHONY: build test install uninstall

build:
	swift build -c release

test:
	swift test

install: build
	mkdir -p $(BINDIR)
	ln -sf $(CURDIR)/.build/release/gwm $(BINDIR)/gwm

uninstall:
	rm -f $(BINDIR)/gwm
