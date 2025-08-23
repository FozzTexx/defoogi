IMAGE=defoogi
VERSION=1.4.0

WSUSER=wario
PREFIX=/usr/local
COMMAND=$(notdir $(IMAGE))
#MULTI_ARCH=linux/amd64,linux/arm64,linux/arm/v7,linux/arm/v8
MULTI_ARCH=linux/amd64,linux/arm64

# Package versions are pinned intentionally.
# This ensures a stable, reproducible toolchain that can be matched to
# specific FujiNet firmware/software releases. In the future, older
# defoogi versions can still be rebuilt against the exact tool
# versions they were originally developed with.
VERSIONS=versions.env

COMPONENTS=cc1541 cc65 cmoc dir2atr mads open-watcom-v2 z88dk
CORE=head final tail

CORE_STAGES = $(addsuffix .docker,$(CORE))
COMPONENT_STAGES = $(addsuffix .docker,$(COMPONENTS))

docker-build: $(CORE_STAGES) $(COMPONENT_STAGES) $(COMMAND) versions.env
	printf "%s\n" $(COMPONENTS) | \
	sed 's,.*,COPY --from=& /tmp/&.deb /tmp/packages/,' | \
	cat head.docker $(COMPONENT_STAGES) final.docker - tail.docker | \
	env BUILDKIT_PROGRESS=plain \
	  docker $(BUILDX) build $(REBUILDFLAGS) -f - \
	    $(PLATFORMS) $(EXTRA_ARGS) \
	    $(shell sed 's/^/--build-arg /' $(VERSIONS)) \
	    --build-arg WSUSER=$(WSUSER) \
	    --rm -t $(IMAGE):$(VERSION) -t $(IMAGE):latest .

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
