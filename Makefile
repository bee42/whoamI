default: build

APP ?= bee42/whoami
DOCKER_IMAGE ?= ${APP}
DOCKER_TAG ?= `git rev-parse --abbrev-ref HEAD`
MANIFEST_TAG ?= $(DOCKER_TAG)
MULTIARCH ?= amd64 arm arm64

build:
	@docker build \
	  --build-arg VERSION=`cat VERSION` \
	  --build-arg VCS_REF=`git rev-parse --short HEAD` \
	  --build-arg BUILD_DATE=`date -u +"%Y-%m-%dT%H:%M:%SZ"` \
	  --tag $(DOCKER_IMAGE):$(DOCKER_TAG) .

labels:
	@echo "list image labels: "
	@docker image inspect \
	--format='{{range $$k, $$v := .Config.Labels}}{{$$k}}={{$$v}}{{println}}{{end}}' \
	$(DOCKER_IMAGE):$(DOCKER_TAG)

push:
	# Push to registry
	@docker push $(DOCKER_IMAGE):$(DOCKER_TAG)

build-multiarch:
	@for arch in $(MULTIARCH); do \
	  case $${arch} in \
			amd64 ) target_image="multiarch/alpine:amd64-v3.9" ;; \
			arm   ) target_image="multiarch/alpine:armhf-v3.9" ;; \
			arm64 ) target_image="multiarch/alpine:arm64-v3.9" ;; \
	  esac ; \
		docker image build --no-cache \
				--build-arg TARGET=$${target_image} \
				--build-arg TARGET_ARCH=$${arch} \
				--build-arg VERSION=`cat VERSION` \
				--build-arg VCS_REF=$(DOCKER_TAG) \
				--build-arg BUILD_DATE=`date -u +"%Y-%m-%dT%H:%M:%SZ"` \
				-t $(DOCKER_IMAGE):$(DOCKER_TAG)-$${arch} . ; \
	done

push-multiarch:
	@echo "Create and push multiarch manifest: "
	@for arch in $(MULTIARCH); do \
	   docker image push $(DOCKER_IMAGE):$(DOCKER_TAG)-$${arch} ; \
	done
	@docker manifest create $(DOCKER_IMAGE):$(MANIFEST_TAG) \
	  $(DOCKER_IMAGE):$(DOCKER_TAG)-amd64 \
	  $(DOCKER_IMAGE):$(DOCKER_TAG)-arm \
	  $(DOCKER_IMAGE):$(DOCKER_TAG)-arm64
	@for arch in $(MULTIARCH); do \
	  case $${arch} in \
			amd64 ) manifest_annotate="" ;; \
			arm   ) manifest_annotate="--os linux --arch arm" ;; \
			arm64 ) manifest.annotate="--os linux --arch arm64 --variant v8" ;; \
	  esac ; \
 		docker manifest annotate $(DOCKER_IMAGE):$(MANIFEST_TAG) $(DOCKER_IMAGE):$(DOCKER_TAG)-$${arch} $${manifest_annotate} ;\
 	done
	@docker manifest push $(DOCKER_IMAGE):$(MANIFEST_TAG)
