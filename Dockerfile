# === 阶段 1: 构建阶段 (Builder) ===
FROM golang:alpine AS builder

# 必须声明这些 ARG，才能接收 Workflow 传进来的版本号
ARG CADDY_VERSION=latest
ARG CLOUDFLARE_REF
ARG DYNAMICDNS_REF

RUN apk add --no-cache git
RUN go install github.com/caddyserver/xcaddy/cmd/xcaddy@latest

# 这里使用 Workflow 传进来的上游版本构建
RUN xcaddy build ${CADDY_VERSION} \
    --with github.com/caddy-dns/cloudflare@${CLOUDFLARE_REF} \
    --with github.com/mholt/caddy-dynamicdns@${DYNAMICDNS_REF}

# === 阶段 2: 运行阶段 (Runner) ===
FROM alpine:edge

# 拷贝构建好的 caddy 二进制文件到系统路径
COPY --from=builder /go/caddy /usr/bin/caddy

# 安装必要的运行时依赖 (tzdata 用于设置时区, ca-certificates 用于 HTTPS 访问)
RUN apk add --no-cache \
    tzdata \
    ca-certificates \
    && update-ca-certificates

# 准备配置目录
RUN mkdir -p /data

# 设置工作目录
WORKDIR /data

# 启动命令
ENTRYPOINT ["caddy"]
CMD ["run", "--config", "/data/Caddyfile", "--adapter", "caddyfile", "--watch"]

