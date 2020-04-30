FROM alpine:3.11

LABEL maintainer="ownCloud GmbH <devops@owncloud.com>" \
    org.label-schema.name="Hugo" \
    org.label-schema.vendor="ownCloud GmbH" \
    org.label-schema.schema-version="1.0"

ARG BUILD_VERSION=0.69.2
ENV HUGO_VERSION="${BUILD_VERSION:-0.69.2}"

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
