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
    && apk add --no-cache bash tzdata ca-certificates openssl iptables nftables

COPY --from=builder /go/bin/hysteria /usr/local/bin/hysteria

ENTRYPOINT ["/bin/sh", "-c"]
CMD ["openssl req -x509 -newkey rsa:2048 -nodes -keyout /tmp/key.pem -out /tmp/cert.pem -days 365 -subj '/CN=bing.com' && cat <<'EOF' > /tmp/config.json\n{\n  \"listen\": \":443\",\n  \"tls\": {\n    \"cert\": \"/tmp/cert.pem\",\n    \"key\": \"/tmp/key.pem\"\n  },\n  \"auth\": {\n    \"type\": \"password\",\n    \"password\": \"YourStrongPassword123\"\n  },\n  \"masquerade\": {\n    \"type\": \"proxy\",\n    \"proxy\": {\n      \"url\": \"https://bing.com/\",\n      \"rewriteHost\": true\n    }\n  }\n}\nEOF\nexec hysteria server -c /tmp/config.json"]
