# Copyright 2019 PingCAP, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# See the License for the specific language governing permissions and
# limitations under the License.

PROJECT=go-boilerplate
GOPATH ?= $(shell go env GOPATH)
P=8

# Ensure GOPATH is set before running build process.
ifeq "$(GOPATH)" ""
  $(error Please set the environment variable GOPATH before running `make`)
endif
FAIL_ON_STDOUT := awk '{ print } END { if (NR > 0) { exit 1 } }'

CURDIR := $(shell pwd)
path_to_add := $(addsuffix /bin,$(subst :,/bin:,$(GOPATH))):$(PWD)/tools/bin
export PATH := $(path_to_add):$(PATH)

GO              := GO111MODULE=on go
GOBUILD         := $(GO) build
GOTEST          := $(GO) test -p $(P)

PACKAGE_LIST  := go list ./...
PACKAGES  := $$($(PACKAGE_LIST))
PACKAGE_DIRECTORIES := $(PACKAGE_LIST) | sed 's|github.com/Rustin-Liu/$(PROJECT)||'
FILES     := $$(find $$($(PACKAGE_DIRECTORIES)) -name "*.go")


.PHONY: build clean test dev check tidy ddltest

build:
	$(GOBUILD)

clean:
	$(GO) clean -i ./...
	rm -rf *.out

test:
	$(GOTEST)
	@>&2 echo "Great, all tests passed."

dev: check test

check: fmt errcheck unconvert lint tidy check-static vet staticcheck goword

fmt:
	@echo "gofmt (simplify)"
	@gofmt -s -l -w $(FILES) 2>&1 | $(FAIL_ON_STDOUT)

goword:tools/bin/goword
	tools/bin/goword $(FILES) 2>&1 | $(FAIL_ON_STDOUT)

gosec:tools/bin/gosec
	tools/bin/gosec ./...

check-static: tools/bin/golangci-lint
	tools/bin/golangci-lint run -v --disable-all --deadline=3m \
	  --enable=misspell \
	  --enable=ineffassign \
	  $$($(PACKAGE_DIRECTORIES))

errcheck:tools/bin/errcheck
	@echo "errcheck"
	@GO111MODULE=on tools/bin/errcheck -exclude ./tools/check/errcheck_excludes.txt -ignoretests -blank $(PACKAGES)

unconvert:tools/bin/unconvert
	@echo "unconvert check"
	@GO111MODULE=on tools/bin/unconvert ./...

lint:tools/bin/revive
	@echo "linting"
	@tools/bin/revive -formatter friendly -config tools/check/revive.toml $(FILES)

vet:
	@echo "vet"
	$(GO) vet -all $(PACKAGES) 2>&1 | $(FAIL_ON_STDOUT)

staticcheck:tools/bin/staticcheck
	@echo "static checking"
	@GO111MODULE=on tools/bin/staticcheck ./...

tidy:
	@echo "go mod tidy"
	./tools/check/check-tidy.sh

tools/bin/revive: tools/check/go.mod
	cd tools/check; \
	$(GO) build -o ../bin/revive github.com/mgechev/revive

tools/bin/goword: tools/check/go.mod
	cd tools/check; \
	$(GO) build -o ../bin/goword github.com/chzchzchz/goword

tools/bin/gosec: tools/check/go.mod
	cd tools/check; \
	$(GO) build -o ../bin/gosec github.com/securego/gosec/cmd/gosec

tools/bin/errcheck: tools/check/go.mod
	cd tools/check; \
	$(GO) build -o ../bin/errcheck github.com/kisielk/errcheck

tools/bin/unconvert: tools/check/go.mod
	cd tools/check; \
	$(GO) build -o ../bin/unconvert github.com/mdempsky/unconvert

tools/bin/staticcheck: tools/check/go.mod
	cd tools/check; \
	$(GO) build -o ../bin/staticcheck honnef.co/go/tools/cmd/staticcheck

tools/bin/golangci-lint:
	curl -sfL https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh| sh -s -- -b ./tools/bin v1.21.0

