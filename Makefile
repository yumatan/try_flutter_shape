.DEFAULT_GOAL := help
.PHONY: help
help:
		@grep -E '^[a-zA-Z0-9_-]+:.*?# .*$$' makefile | awk 'BEGIN {FS = ":[^#]*? #| #"}; {printf "%-57s%s\n", $$1 $$3, $$2}'
.PHONY: clean-and-get
clean-and-get: # $ fvm flutter clean -> $ fvm flutter pub get
		fvm flutter clean
		fvm flutter pub get