# === 阶段 1: 构建阶段 ===
FROM golang:alpine AS builder

# 安装构建 Caddy 所需的 xcaddy 工具
RUN go install github.com/caddyserver/xcaddy/cmd/xcaddy@latest

# 直接构建，无需手动 clone 源码
# xcaddy 会自动下载最新版 Caddy 源码并集成插件
RUN xcaddy build \
    --with github.com/caddy-dns/cloudflare \
    --with github.com/mholt/caddy-dynamicdns

# 可选：输出版本
RUN /data/xcaddy/cmd/xcaddy/caddy -v


# === 阶段 2: 运行阶段 ===
FROM alpine:edge

# 拷贝构建后的 Caddy 二进制
COPY --from=builder /data/xcaddy/cmd/xcaddy/caddy /usr/bin/

# 安装运行时依赖
RUN apk update && \
    apk upgrade && \
    apk add --no-cache tzdata ca-certificates && \
    update-ca-certificates && \
    rm -rf /var/cache/apk/*


# 建立软链接：让 Caddy 使用 /data/caddyfile.txt 作为配置文件
RUN mkdir -p /etc/caddy /data && \
    ln -sf /data/caddyfile.txt /etc/caddy/Caddyfile

# 设置工作目录（可选）
WORKDIR /etc/caddy

# 设置容器启动命令，读取软链接配置
ENTRYPOINT ["caddy"]
CMD ["run", "--config", "/etc/caddy/Caddyfile", "--adapter", "caddyfile"]

