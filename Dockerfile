FROM golang:1-alpine AS builder

ARG GOPROXY=""
ENV GOPROXY=${GOPROXY}

COPY . /go/src/github.com/apernet/hysteria
WORKDIR /go/src/github.com/apernet/hysteria

RUN set -ex \
    && apk add --no-cache git build-base bash python3 \
    && python3 hyperbole.py build -r \
    && mv ./build/hysteria-* /go/bin/hysteria

FROM alpine AS dist

RUN if [ ! -e /etc/nsswitch.conf ]; then echo 'hosts: files dns' > /etc/nsswitch.conf; fi

RUN set -ex \
    && apk upgrade \
    && apk add --no-cache bash tzdata ca-certificates iptables nftables

COPY --from=builder /go/bin/hysteria /usr/local/bin/hysteria

ENTRYPOINT ["hysteria"]
