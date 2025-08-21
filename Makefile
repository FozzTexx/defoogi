IMAGE=defoogi
VERSION=1.4

WSUSER=wario
PREFIX=/usr/local
COMMAND=$(notdir $(IMAGE))
#MULTI_ARCH=linux/amd64,linux/arm64,linux/arm/v7
MULTI_ARCH=linux/amd64,linux/arm64

# Package versions are pinned intentionally.
# This ensures a stable, reproducible toolchain that can be matched to
# specific FujiNet firmware/software releases. In the future, older
# defoogi versions can still be rebuilt against the exact tool
# versions they were originally developed with.
VERSIONS=versions.env

# Make sure head is always first and foot is always last!
DOCKERFILES=\
  Dockerfile.head \
  Dockerfile.applecommander \
  Dockerfile.atasm \
  Dockerfile.cc1541 \
  Dockerfile.cc65 \
  Dockerfile.cmoc \
  Dockerfile.mads \
  Dockerfile.ow2 \
  Dockerfile.foot

docker-build: Dockerfile $(COMMAND) versions.env
	env BUILDKIT_PROGRESS=plain \
	  docker $(BUILDX) build $(REBUILDFLAGS) -f Dockerfile \
	    $(PLATFORMS) $(EXTRA_ARGS) \
	    $(shell sed 's/^/--build-arg /' $(VERSIONS)) \
	    --build-arg WSUSER=$(WSUSER) \
	    --rm -t $(IMAGE):$(VERSION) -t $(IMAGE):latest .

Dockerfile: $(DOCKERFILES)
	cat $^ > $@

$(COMMAND):
	ln -s start $@

install: $(PREFIX)/bin/$(COMMAND)

$(PREFIX)/bin/$(COMMAND): start
	cp start $(PREFIX)/bin/$(COMMAND)

multi-arch:
	make BUILDX=buildx PLATFORMS="--platform $(MULTI_ARCH)"

# To force a complete clean build, do:
#   make rebuild
rebuild:
	rm -f $(BUNDLES)
	make REBUILDFLAGS="--no-cache --pull"
