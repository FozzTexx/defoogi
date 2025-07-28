IMAGE=defoogi
VERSION=1.0
LWTOOLS_VERSION=4.24
CMOC_VERSION=0.1.90
WSUSER=wario

docker-build: Dockerfile $(IMAGE)
	env BUILDKIT_PROGRESS=plain \
	  docker build $(REBUILDFLAGS) -f Dockerfile \
	    --build-arg LWTOOLS_VERSION=$(LWTOOLS_VERSION) \
	    --build-arg CMOC_VERSION=$(CMOC_VERSION) \
	    --build-arg WSUSER=$(WSUSER) \
	    --rm -t $(IMAGE):$(VERSION) -t $(IMAGE):latest .

$(IMAGE):
	ln -s start $(IMAGE)

# To force a complete clean build, do:
#   make rebuild
rebuild:
	rm -f $(BUNDLES)
	make REBUILDFLAGS="--no-cache --pull"
