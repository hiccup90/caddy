# 构建阶段
FROM alpine:latest AS builder

# 安装编译依赖（使用 --no-cache 减小体积）
RUN apk add --no-cache --update \
    go \
    git \
    build-base

# 编译 xcaddy
WORKDIR /build
RUN git clone https://github.com/caddyserver/xcaddy.git --depth 1
WORKDIR /build/xcaddy/cmd/xcaddy
RUN go build -o /usr/local/bin/xcaddy

# 使用 xcaddy 构建自定义 caddy
RUN /usr/local/bin/xcaddy build latest \
    --with github.com/caddy-dns/cloudflare

# 最终镜像
FROM alpine:latest

# 安装最小依赖
RUN apk add --no-cache \
    ca-certificates \
    tzdata

# 从构建阶段复制二进制文件
COPY --from=builder /usr/bin/caddy /usr/bin/caddy

# 设置时区（可选）
ENV TZ=Asia/Shanghai

# 验证版本
RUN caddy version

# 启动命令
CMD ["caddy", "run", "--config", "/etc/caddy/Caddyfile", "--adapter", "caddyfile"]
