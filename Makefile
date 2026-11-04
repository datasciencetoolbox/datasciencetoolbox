IMAGE = datasciencetoolbox/dsatcl2e
TAG = dev

.PHONY: build build-amd64 test run size

# Build for the architecture of this machine
build:
	docker build -t $(IMAGE):$(TAG) .

# Build for amd64 on another architecture (slow: emulated)
build-amd64:
	docker build --platform linux/amd64 -t $(IMAGE):$(TAG)-amd64 .

test:
	docker run --rm -v "$(CURDIR)/tests":/tests $(IMAGE):$(TAG) /tests/smoke.sh

run:
	docker run --rm -it -v "$(CURDIR)":/data $(IMAGE):$(TAG)

size:
	docker image inspect $(IMAGE):$(TAG) --format '{{.Size}}'
