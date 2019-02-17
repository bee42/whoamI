ARG GOLANG_TARGET=${GOLANG_TARGET:-golang:1.11.5-stretch}
ARG TARGET=${TARGET:-alpine:3.9}
FROM ${GOLANG_TARGET} as build

ENV REPO=github.com/bee42/whoamI \
    OUTPUT_PATH=/output

RUN apt-get update && apt-get install -y --no-install-recommends git make curl && \
    curl https://raw.githubusercontent.com/golang/dep/master/install.sh | sh

ARG ARCH=${ARCH:-amd64}
ARG OS=${OS:-linux}
WORKDIR $GOPATH/src/${REPO}
COPY . ./
RUN mkdir -p vendor && dep ensure
RUN mkdir -p $OUTPUT_PATH && \
    GOOS=${OS} GOARCH=${ARCH} CGO_ENABLED=0 go build -a --installsuffix cgo --ldflags="-s" -o $OUTPUT_PATH/whoamI

#FROM ${TARGET} as user
#
#RUN addgroup -g 1000 -S app && \
#    adduser -u 1000 -S app -G app

FROM ${TARGET}
LABEL maintainer nicals.mietz@bee42.com
LABEL maintainer peter.rossbach@bee42.com
#COPY --from=user /etc/group /etc/group
#COPY --from=user /etc/passwd /etc/passwd
#USER app
#COPY --chown=app:app --from=build /output/whoamI /whoamI
COPY --from=build /output/whoamI /whoamI
ENTRYPOINT ["/whoamI"]
#CMD [ "--port", "8080"]
#EXPOSE 8080
EXPOSE 80

# Metadata
ARG VCS_REF
ARG BUILD_DATE
ARG VERSION

# Metadata
LABEL maintainer="bee42 cloud native crew <cloud-native@bee42.com>" \
      org.opencontainers.image.title="whoami" \
      org.opencontainers.image.version="${VERSION}" \
      org.opencontainers.image.revision="${VCS_REF}" \
      org.opencontainers.image.created="${BUILD_DATE}" \
      org.opencontainers.image.url="https://hub.docker.com/r/bee42/whoami/" \
      org.opencontainers.image.source="https://github.com/bee42/whoamI/" \
      org.opencontainers.image.authors="bee42 cloud native crew <cloud-native@bee42.com>" \
      org.opencontainers.image.vendor="bee42 solutions gmbh" \
      org.opencontainers.image.licenses="Apache-2.0" \
      com.bee42.image.type="service-stateless" \
