FROM alpine:edge AS builder
RUN apk upgrade&&apk add go git
WORKDIR /data
RUN git clone https://github.com/caddyserver/xcaddy.git --depth 1 
WORKDIR /data/xcaddy/cmd/xcaddy
RUN go run main.go build latest \
--with github.com/caddy-dns/cloudflare
RUN /data/xcaddy/cmd/xcaddy/caddy -v

FROM alpine:edge
COPY --from=builder /data/xcaddy/cmd/xcaddy/caddy /usr/bin/
RUN apk update && \
    apk upgrade && \
    apk add --no-cache tzdata ca-certificates && \
    update-ca-certificates && \
    rm -rf /var/cache/apk/*
CMD ["run", "--config", "/etc/caddy/Caddyfile"]
