# 使用更可靠的构建环境
FROM golang:1.21-alpine AS builder

# 安装必要工具（git + upx可选压缩）
RUN apk add --no-cache \
    git \
    build-base \
    upx

# 编译 xcaddy
WORKDIR /build
RUN git clone https://github.com/caddyserver/xcaddy --depth 1
WORKDIR /build/xcaddy/cmd/xcaddy
RUN go build -o /usr/local/bin/xcaddy

# 使用 xcaddy 构建 Caddy（明确指定版本）
RUN /usr/local/bin/xcaddy build \
    --output /usr/bin/caddy \
    --with github.com/caddy-dns/cloudflare

FROM alpine:latest
RUN apk add --no-cache ca-certificates tzdata
COPY --from=builder /usr/bin/caddy /usr/bin/

ENTRYPOINT ["/caddy"]
CMD ["run", "--config", "/etc/caddy/Caddyfile"]
