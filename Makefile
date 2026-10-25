HOST ?= mb-pro

.PHONY: check build
check:
	nix flake check --no-build --no-write-lock-file

build:
	nix build --no-write-lock-file .\#darwinConfigurations.$(HOST).system
