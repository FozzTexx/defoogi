IMAGE=defoogi
TAG=1.4.0

WSUSER=wario
PREFIX=/usr/local
COMMAND=$(notdir $(IMAGE))

# Package versions are pinned intentionally.
# This ensures a stable, reproducible toolchain that can be matched to
# specific FujiNet firmware/software releases. In the future, older
# defoogi versions can still be rebuilt against the exact tool
# versions they were originally developed with.
VERSIONS=versions.env

COMPONENTS=cc1541 cc65 cmoc dir2atr mads open-watcom-v2 z88dk
CORE=head final tail

CORE_STAGES = $(addsuffix .docker,$(addprefix Dockerfiles/,$(CORE)))
COMPONENT_STAGES = $(addsuffix .docker,$(addprefix Dockerfiles/,$(COMPONENTS)))

docker-build: $(CORE_STAGES) $(COMPONENT_STAGES) $(COMMAND) versions.env
	printf "%s\n" $(COMPONENTS) | \
	sed 's,.*,COPY --from=& /tmp/&.deb /tmp/packages/,' | \
	cat $(word 1,$(CORE_STAGES)) $(COMPONENT_STAGES) \
	  $(word 2,$(CORE_STAGES)) - $(word 3,$(CORE_STAGES)) | \
	env BUILDKIT_PROGRESS=plain \
	  docker build $(REBUILDFLAGS) -f - \
	    $(EXTRA_ARGS) \
	    $(shell sed 's/^/--build-arg /' $(VERSIONS)) \
	    --build-arg WSUSER=$(WSUSER) \
	    --rm -t $(IMAGE):$(TAG) -t $(IMAGE):latest .

$(COMMAND):
	ln -s start $@

install: $(PREFIX)/bin/$(COMMAND)

$(PREFIX)/bin/$(COMMAND): start
	cp start $(PREFIX)/bin/$(COMMAND)

multi-arch:
	@if [ -z "$(NAMESPACE)" ] ; then \
	    echo "Error: must include NAMESPACE=" ; \
	    exit 1 ; \
	fi
	@case "$(NAMESPACE)" in \
	    */) ;; \
	    *) echo "Error: NAMESPACE must end with a slash." >&2 ; exit 1 ;; \
	esac
	make IMAGE=$(NAMESPACE)$(IMAGE) EXTRA_ARGS=--push \
	    TAG=$(TAG)-$$(docker version --format '{{.Server.Arch}}')

manifest:
	@if [ -z "$(NAMESPACE)" ] ; then \
	    echo "Error: must include NAMESPACE=" ; \
	    exit 1 ; \
	fi
	@case "$(NAMESPACE)" in \
	    */) ;; \
	    *) echo "Error: NAMESPACE must end with a slash." >&2 ; exit 1 ;; \
	esac
	DOCKER_API="https://registry.hub.docker.com/v2/repositories/" ; \
	ARCHS=$$(curl -s "$${DOCKER_API}$(NAMESPACE)$(IMAGE)/tags?page_size=100" \
	    | jq -r '.results[].name' | sed -n '/^$(TAG)-/s/.*-//p') ; \
	if [ -z "$${ARCHS}" ] ; then \
	    echo "No existing archs for $(TAG)" ; \
	    exit 1 ; \
	fi ; \
	ARGS="$(NAMESPACE)$(IMAGE):$(TAG)" ; \
	for arch in $${ARCHS} ; do \
	    ARGS="$${ARGS} --amend $(NAMESPACE)$(IMAGE):$(TAG)-$${arch}" ; \
	done ; \
	docker manifest create $${ARGS} ; \
	docker manifest push $(NAMESPACE)$(IMAGE):$(TAG)

# To force a complete clean build, do:
#   make rebuild
rebuild:
	make REBUILDFLAGS="--no-cache --pull"
