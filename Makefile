IMAGE = defoogi
TAG = 1.4.4
MAINTAINER=fozztexx@fozztexx.com

WSUSER = wario
PREFIX = /usr/local
COMMAND = $(notdir $(IMAGE))

# Package versions are pinned intentionally.
# This ensures a stable, reproducible toolchain that can be matched to
# specific FujiNet firmware/software releases. In the future, older
# defoogi versions can still be rebuilt against the exact tool
# versions they were originally developed with.
VERSIONS = versions.env

DOCKERFILES = $(wildcard Dockerfiles/*.docker)
CORE = head final tail
COMPONENTS = $(filter-out $(CORE),$(notdir $(DOCKERFILES:.docker=)))

CORE_STAGES = $(addsuffix .docker,$(addprefix Dockerfiles/,$(CORE)))
COMPONENT_STAGES = $(addsuffix .docker,$(addprefix Dockerfiles/,$(COMPONENTS)))

docker-build: $(CORE_STAGES) $(COMPONENT_STAGES) $(COMMAND) $(VERSIONS)
	printf "%s\n" $(COMPONENTS) | \
	sed 's,.*,COPY --from=& /tmp/&.deb /tmp/packages/,' | \
	cat $(word 1,$(CORE_STAGES)) $(COMPONENT_STAGES) \
	  $(word 2,$(CORE_STAGES)) - $(word 3,$(CORE_STAGES)) | \
	tee /tmp/$(IMAGE).dockerfile | \
	env BUILDKIT_PROGRESS=plain \
	  docker build $(REBUILDFLAGS) -f - \
	    $(EXTRA_ARGS) \
	    $(shell sed 's/^\([^=]*\)=/--build-arg \1_VERSION=/' $(VERSIONS)) \
	    --build-arg MAINTAINER=$(MAINTAINER) \
	    --build-arg WSUSER=$(WSUSER) \
	    --rm -t $(IMAGE):$(TAG)$(TAG_ARCH) -t $(IMAGE):latest$(TAG_ARCH) .

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
	export TAG_ARCH="-$$(docker version --format '{{.Server.Arch}}')" \
	&& make IMAGE=$(NAMESPACE)$(IMAGE) \
	&& docker push $(NAMESPACE)$(IMAGE):$(TAG)$${TAG_ARCH} \
	&& docker push $(NAMESPACE)$(IMAGE):latest$${TAG_ARCH}

manifest:
	@if [ -z "$(NAMESPACE)" ] ; then \
	    echo "Error: must include NAMESPACE=" ; \
	    exit 1 ; \
	fi
	@case "$(NAMESPACE)" in \
	    */) ;; \
	    *) echo "Error: NAMESPACE must end with a slash." >&2 ; exit 1 ;; \
	esac
	@create_manifest() { \
		TAG_NAME=$$1 ; \
		DOCKER_API="https://registry.hub.docker.com/v2/repositories/" ; \
		ARCHS=$$(curl -s "$${DOCKER_API}$(NAMESPACE)$(IMAGE)/tags?page_size=100" \
			| jq -r '.results[].name' | sed -n '/^$(TAG)-/s/.*-//p') ; \
		if [ -z "$${ARCHS}" ] ; then \
			echo "No existing archs for $(TAG)" ; \
			exit 1 ; \
		fi ; \
		ARGS="" ; \
		for arch in $${ARCHS} ; do \
			ARGS="$${ARGS} $(NAMESPACE)$(IMAGE):$${TAG_NAME}-$${arch}" ; \
		done ; \
		docker buildx imagetools create -t $(NAMESPACE)$(IMAGE):$${TAG_NAME} $${ARGS} ; \
	} ; \
	create_manifest $(TAG) ; \
	create_manifest latest

# To force a complete clean build, do:
#   make rebuild
rebuild:
	make REBUILDFLAGS="--no-cache --pull"
