# iOrganize — build & packaging
#
# Standard Xcode builds need no local workaround. If a matching workaround
# already exists for the affected Command Line Tools install, use it.

TOOLCHAIN_FIX := $(HOME)/.hikari-swiftpm-libs
ifneq ($(wildcard $(TOOLCHAIN_FIX)/swiftc),)
export SWIFTPM_CUSTOM_LIBS_DIR := $(TOOLCHAIN_FIX)
export SWIFT_EXEC := $(TOOLCHAIN_FIX)/swiftc
SWIFT_OVERLAY := -vfsoverlay $(TOOLCHAIN_FIX)/mask.yaml
endif

APP_NAME := IOrganize
BUNDLE   := dist/iOrganize.app
CONTENTS := $(BUNDLE)/Contents
BINARY   := .build/release/$(APP_NAME)

.PHONY: all build app run install icon clean zip

all: app

build:
	swift build -c release

app: build icon
	rm -rf $(BUNDLE)
	mkdir -p $(CONTENTS)/MacOS $(CONTENTS)/Resources
	cp $(BINARY) $(CONTENTS)/MacOS/$(APP_NAME)
	cp Packaging/Info.plist $(CONTENTS)/Info.plist
	printf 'APPL????' > $(CONTENTS)/PkgInfo
	cp dist/AppIcon.icns $(CONTENTS)/Resources/AppIcon.icns
	codesign --force --deep --sign - $(BUNDLE)
	@echo "✓ Built $(BUNDLE)"

icon: dist/AppIcon.icns

dist/AppIcon.icns: Packaging/make-icon.swift
	mkdir -p dist
	rm -rf dist/AppIcon.iconset
	swift $(SWIFT_OVERLAY) Packaging/make-icon.swift dist/AppIcon.iconset
	iconutil -c icns dist/AppIcon.iconset -o dist/AppIcon.icns

run: app
	open $(BUNDLE)

install: app
	mkdir -p /Applications/iSuite
	rm -rf "/Applications/iSuite/iOrganize.app"
	ditto $(BUNDLE) "/Applications/iSuite/iOrganize.app"
	@echo "✓ Installed to /Applications/iSuite/iOrganize.app"

zip: app
	cd dist && ditto -c -k --sequesterRsrc --keepParent iOrganize.app iOrganize.zip

clean:
	rm -rf .build dist
