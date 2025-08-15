IMAGE=defoogi
VERSION=1.2
LWTOOLS_VERSION=4.24
CMOC_VERSION=0.1.93
WSUSER=wario
PREFIX=/usr/local
COMMAND=$(notdir $(IMAGE))

docker-build: Dockerfile $(COMMAND)
	env BUILDKIT_PROGRESS=plain \
	  docker build $(REBUILDFLAGS) -f Dockerfile \
	    --build-arg LWTOOLS_VERSION=$(LWTOOLS_VERSION) \
	    --build-arg CMOC_VERSION=$(CMOC_VERSION) \
	    --build-arg WSUSER=$(WSUSER) \
	    --rm -t $(IMAGE):$(VERSION) -t $(IMAGE):latest .

$(COMMAND):
	ln -s start $@

install: $(PREFIX)/bin/$(COMMAND)

$(PREFIX)/bin/$(COMMAND): start
	cp start $(PREFIX)/bin/$(COMMAND)

# To force a complete clean build, do:
#   make rebuild
rebuild:
	rm -f $(BUNDLES)
	make REBUILDFLAGS="--no-cache --pull"
