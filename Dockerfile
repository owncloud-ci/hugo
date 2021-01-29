FROM alpine:3.11

LABEL maintainer="ownCloud DevOps <devops@owncloud.com>"
LABEL org.opencontainers.image.authors="ownCloud DevOps <devops@owncloud.com>"
LABEL org.opencontainers.image.title="ownCloud CI Hugo"
LABEL org.opencontainers.image.url="https://github.com/owncloud-ci/hugo"
LABEL org.opencontainers.image.source="https://github.com/owncloud-ci/hugo"
LABEL org.opencontainers.image.documentation="https://github.com/owncloud-ci/hugo"

ARG BUILD_VERSION

# renovate: datasource=github-releases depName=gohugoio/hugo
ENV HUGO_VERSION="${BUILD_VERSION:-v0.80.0}"

RUN apk --update add --virtual .build-deps curl && \
    HUGO_VERSION="${HUGO_VERSION##v}" && \
    echo "Installing Hugo version '${HUGO_VERSION}' ..." && \
    curl -SsL "https://github.com/gohugoio/hugo/releases/download/v${HUGO_VERSION}/hugo_${HUGO_VERSION}_Linux-64bit.tar.gz" | \
        tar xz -C /usr/bin hugo && \
    apk del .build-deps && \
    chmod 755 /usr/bin/hugo && \
    rm -rf /var/cache/apk/* && \
    rm -rf /tmp/*

WORKDIR /src

ENTRYPOINT ["/usr/bin/hugo"]

CMD []
