NAME=timescaledb
# Default is to timescaledev to avoid unexpected push to the main repo
# Set ORG to timescale in the caller
ORG=timescaledev
PG_BASE_IMAGE=postgresql
PG_VER=pg16
PG_VER_NUMBER=$(shell echo $(PG_VER) | cut -c3-)
PG_IMAGE_SUFFIX=$(shell if "$(PG_BASE_IMAGE)" == "postgresql-repmgr"; then echo "bitnami"; else echo "repmgr-bitnami"; fi )
PREV_IMAGE=$(shell if docker pull $(PREV_TS_IMAGE) >/dev/null; then echo "$(PREV_TS_IMAGE)"; else echo "bitnami/$(PG_BASE_IMAGE):$(PG_VER_NUMBER)"; fi )
TS_VERSION=main
PREV_TS_VERSION=$(shell wget --quiet -O - https://raw.githubusercontent.com/timescale/timescaledb/${TS_VERSION}/version.config | grep update_from_version | sed -e 's!update_from_version = !!')
PREV_TS_IMAGE="timescale/timescaledb:$(PREV_TS_VERSION)-pg$(PG_VER_NUMBER)-$(PG_IMAGE_SUFFIX)"
PREV_IMAGE=$(shell if docker pull $(PREV_TS_IMAGE) >/dev/null; then echo "$(PREV_TS_IMAGE)"; else echo "bitnami/$(PG_BASE_IMAGE):$(PG_VER_NUMBER)"; fi )

# Beta releases should not be tagged as latest, so BETA is used to track.
BETA=$(findstring rc,$(TS_VERSION))
TAG_VERSION=$(ORG)/$(NAME):$(TS_VERSION)-$(PG_VER)-$(PG_IMAGE_SUFFIX)
TAG_LATEST=$(ORG)/$(NAME):latest-$(PG_VER)-$(PG_IMAGE_SUFFIX)
TAG=-t $(TAG_VERSION) $(if $(BETA),,-t $(TAG_LATEST))

default: image

.build_$(PG_BASE_IMAGE)_$(TS_VERSION)_$(PG_VER): Dockerfile
	test -n "$(TS_VERSION)"  # TS_VERSION
	test -n "$(PREV_TS_VERSION)"  # PREV_TS_VERSION
	docker build -f ./Dockerfile --build-arg PG_VERSION=$(PG_VER_NUMBER) --build-arg TS_VERSION=$(TS_VERSION) --build-arg PREV_IMAGE=$(PREV_IMAGE) --build-arg PG_BASE_IMAGE=$(PG_BASE_IMAGE) $(TAG) ..
	touch .build_$(PG_BASE_IMAGE)_$(TS_VERSION)_$(PG_VER)-bitnami

image: .build_$(PG_BASE_IMAGE)_$(TS_VERSION)_$(PG_VER)

push: image
	docker push $(TAG_VERSION)
	if [ -z "$(BETA)" ]; then \
		docker push $(TAG_LATEST); \
	fi

clean:
	rm -f *~ .build_*

.PHONY: default image push clean