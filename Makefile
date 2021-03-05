.PHONY: all images lint test clean cross

.DEFAULT_GOAL := all
IMAGE_PREFIX ?= grafana
IMAGE_TAG := $(shell ./tools/image-tag)
GIT_REVISION := $(shell git rev-parse --short HEAD)
GIT_BRANCH := $(shell git rev-parse --abbrev-ref HEAD)
GO_FLAGS := -mod=vendor -ldflags "-extldflags \"-static\" -s -w -X $(VPREFIX).Branch=$(GIT_BRANCH) -X $(VPREFIX).Version=$(IMAGE_TAG) -X $(VPREFIX).Revision=$(GIT_REVISION)" -tags netgo

all: benchtool cortextool chunktool logtool
images: cortextool-image chunktool-image logtool-image benchtool-image
benchtool: cmd/benchtool/benchtool
cortextool: cmd/cortextool/cortextool
chunktool: cmd/chunktool/chunktool
logtool: cmd/logtool/logtool
e2ealerting: cmd/e2ealerting/e2ealerting

benchtool-image:
	$(SUDO) docker build -t $(IMAGE_PREFIX)/benchtool -f cmd/benchtool/Dockerfile .
	$(SUDO) docker tag $(IMAGE_PREFIX)/benchtool $(IMAGE_PREFIX)/benchtool:$(IMAGE_TAG)

cortextool-image:
	$(SUDO) docker build -t $(IMAGE_PREFIX)/cortextool -f cmd/cortextool/Dockerfile .
	$(SUDO) docker tag $(IMAGE_PREFIX)/cortextool $(IMAGE_PREFIX)/cortextool:$(IMAGE_TAG)

chunktool-image:
	$(SUDO) docker build -t $(IMAGE_PREFIX)/chunktool -f cmd/chunktool/Dockerfile .
	$(SUDO) docker tag $(IMAGE_PREFIX)/chunktool $(IMAGE_PREFIX)/chunktool:$(IMAGE_TAG)

logtool-image:
	$(SUDO) docker build -t $(IMAGE_PREFIX)/logtool -f cmd/logtool/Dockerfile .
	$(SUDO) docker tag $(IMAGE_PREFIX)/logtool $(IMAGE_PREFIX)/logtool:$(IMAGE_TAG)

e2ealerting-image:
	$(SUDO) docker build -t $(IMAGE_PREFIX)/e2ealerting -f cmd/e2ealerting/Dockerfile .
	$(SUDO) docker tag $(IMAGE_PREFIX)/e2ealerting $(IMAGE_PREFIX)/e2ealerting:$(IMAGE_TAG)
push-e2ealerting-image: e2ealerting-image
	$(SUDO) docker push $(IMAGE_PREFIX)/e2ealerting:$(IMAGE_TAG)

cmd/benchtool/benchtool: $(APP_GO_FILES) cmd/benchtool/main.go
	CGO_ENABLED=0 go build $(GO_FLAGS) -o $@ ./$(@D)

cmd/cortextool/cortextool: $(APP_GO_FILES) cmd/cortextool/main.go
	CGO_ENABLED=0 go build $(GO_FLAGS) -o $@ ./$(@D)

cmd/chunktool/chunktool: $(APP_GO_FILES) cmd/chunktool/main.go
	CGO_ENABLED=0 go build $(GO_FLAGS) -o $@ ./$(@D)

cmd/logtool/logtool: $(APP_GO_FILES) cmd/logtool/main.go
	CGO_ENABLED=0 go build $(GO_FLAGS) -o $@ ./$(@D)

cmd/e2ealerting/e2ealerting: $(APP_GO_FILES) cmd/e2ealerting/main.go
	CGO_ENABLED=0 go build $(GO_FLAGS) -o $@ ./$(@D)

cmd/rules-migrator/rules-migrator: $(APP_GO_FILES) cmd/rules-migrator/main.go
	CGO_ENABLED=0 go build $(GO_FLAGS) -o $@ ./$(@D)

lint:
	golangci-lint run -v

cross:
	CGO_ENABLED=0 gox -output="dist/{{.Dir}}-{{.OS}}-{{.Arch}}" -ldflags=${LDFLAGS} -arch="amd64" -os="linux windows darwin" ./cmd/cortextool
	CGO_ENABLED=0 gox -output="dist/{{.Dir}}-{{.OS}}-{{.Arch}}" -ldflags=${LDFLAGS} -arch="amd64" -os="linux windows darwin" ./cmd/chunktool
	CGO_ENABLED=0 gox -output="dist/{{.Dir}}-{{.OS}}-{{.Arch}}" -ldflags=${LDFLAGS} -arch="amd64" -os="linux windows darwin" ./cmd/logtool
	CGO_ENABLED=0 gox -output="dist/{{.Dir}}-{{.OS}}-{{.Arch}}" -ldflags=${LDFLAGS} -arch="amd64" -os="linux windows darwin" ./cmd/e2ealerting

test:
	go test -mod=vendor -p=8 ./pkg/...

clean:
	rm -rf cmd/benchtool/benchtool
	rm -rf cmd/cortextool/cortextool
	rm -rf cmd/chunktool/chunktool
	rm -rf cmd/logtool/logtool
	rm -rf cmd/e2ealerting/e2ealerting
