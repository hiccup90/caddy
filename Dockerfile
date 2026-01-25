# === 阶段 1: 构建阶段 (Builder) ===
FROM golang:alpine AS builder

# 安装构建工具 git
RUN apk add --no-cache git

# 安装 xcaddy 工具
RUN go install github.com/caddyserver/xcaddy/cmd/xcaddy@latest

# 使用 xcaddy 构建 Caddy，集成 Cloudflare DNS 和 DDNS 插件
# 默认 build latest，产生的二进制文件在当前目录名为 caddy
RUN xcaddy build \
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

