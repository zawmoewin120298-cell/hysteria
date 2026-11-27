FROM golang:1-alpine AS builder

ARG GOPROXY=""
ENV GOPROXY=${GOPROXY}

WORKDIR /go/src/github.com/apernet/hysteria
COPY . .

RUN set -ex \
    && apk add --no-cache git build-base bash ca-certificates \
    && cd app \
    && go build -trimpath -ldflags="-s -w" -o /go/bin/hysteria .

FROM alpine AS dist

RUN if [ ! -e /etc/nsswitch.conf ]; then echo 'hosts: files dns' > /etc/nsswitch.conf; fi

RUN set -ex \
    && apk upgrade \
    && apk add --no-cache bash tzdata ca-certificates iptables nftables

COPY --from=builder /go/bin/hysteria /usr/local/bin/hysteria

ENTRYPOINT ["hysteria"]
CMD ["server", "--listen", ":443", "--auth", "password:YourStrongPassword123", "--tls-self-signed"]
