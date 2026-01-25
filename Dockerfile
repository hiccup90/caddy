# === 阶段 1: 构建阶段 (Builder) ===
FROM golang:alpine AS builder

# 必须声明这个 ARG，才能接收 Workflow 传进来的版本号
ARG CADDY_VERSION=latest

RUN apk add --no-cache git
RUN go install github.com/caddyserver/xcaddy/cmd/xcaddy@latest

# 这里使用 ${CADDY_VERSION} 代替固定字符串
RUN xcaddy build ${CADDY_VERSION} \
    --with github.com/caddy-dns/cloudflare \
    --with github.com/mholt/caddy-dynamicdns

# === 阶段 2: 运行阶段 (Runner) ===
FROM alpine:edge

# 拷贝构建好的 caddy 二进制文件到系统路径
COPY --from=builder /go/caddy /usr/bin/caddy

# 安装必要的运行时依赖 (tzdata 用于设置时区, ca-certificates 用于 HTTPS 访问)
RUN apk add --no-cache \
    tzdata \
    ca-certificates \
    && update-ca-certificates

# 准备配置目录和软链接
RUN mkdir -p /etc/caddy /data && \
    ln -sf /data/caddyfile.txt /etc/caddy/Caddyfile

# 设置工作目录
WORKDIR /data


# 启动命令
ENTRYPOINT ["caddy"]
CMD ["run", "--config", "/etc/caddy/Caddyfile", "--adapter", "caddyfile"]

