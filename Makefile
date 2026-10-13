PREFIX ?= $(HOME)/.local
BINDIR := $(PREFIX)/bin

VERSION ?= $(shell git describe --tags --abbrev=0 2>/dev/null | sed 's/^v//')
DIST := dist/gwm-$(VERSION)-macos-universal.tar.gz

.PHONY: build test install uninstall dist

build:
	swift build -c release

test:
	swift test

install: build
	mkdir -p $(BINDIR)
	ln -sf $(CURDIR)/.build/release/gwm $(BINDIR)/gwm

uninstall:
	rm -f $(BINDIR)/gwm

# Universal (arm64 + x86_64) release tarball for GitHub releases / the Homebrew tap.
dist:
	swift build -c release --arch arm64 --arch x86_64
	rm -rf dist/stage && mkdir -p dist/stage
	cp .build/apple/Products/Release/gwm LICENSE README.md dist/stage/
	tar -czf $(DIST) -C dist/stage gwm LICENSE README.md
	rm -rf dist/stage
	shasum -a 256 $(DIST)
