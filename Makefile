.PHONY: help build-local test-github test-alloy test-collector bump-patch bump-minor bump-major

.DEFAULT_GOAL := help

help: ## Show available commands
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[33m%-20s\033[0m %s\n", $$1, $$2}'

build-local: ## Build all images locally (for testing)
	docker build -t github-actions-exporter:local docker/github-actions-exporter/
	docker build -t grafana-alloy:local docker/grafana-alloy/
	docker build -t github-actions-collector:local docker/github-actions-collector/

test-github: ## Test GitHub Actions exporter locally
	docker run --rm --env-file .env github-actions-exporter:local

test-collector: ## Test GitHub Actions collector locally
	docker run --rm --env-file .env github-actions-collector:local

test-alloy: ## Test Grafana Alloy config validation
	docker run --rm -v $(PWD)/docker/grafana-alloy/config.alloy:/etc/alloy/config.alloy \
		grafana/alloy:latest fmt --write=false /etc/alloy/config.alloy

bump-patch: ## Bump patch version (1.0.0 → 1.0.1)
	@current=$$(cat VERSION); \
	new=$$(echo $$current | awk -F. '{print $$1"."$$2"."$$3+1}'); \
	echo $$new > VERSION; \
	echo "Version bumped: $$current → $$new"

bump-minor: ## Bump minor version (1.0.0 → 1.1.0)
	@current=$$(cat VERSION); \
	new=$$(echo $$current | awk -F. '{print $$1"."$$2+1".0"}'); \
	echo $$new > VERSION; \
	echo "Version bumped: $$current → $$new"

bump-major: ## Bump major version (1.0.0 → 2.0.0)
	@current=$$(cat VERSION); \
	new=$$(echo $$current | awk -F. '{print $$1+1".0.0"}'); \
	echo $$new > VERSION; \
	echo "Version bumped: $$current → $$new"
