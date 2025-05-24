#到 https://hub.docker.com/_/caddy/tags 查找合适的builder镜像tag
#为了更小的体积，我选择builder-alpine
FROM caddy:builder-alpine AS builder

RUN xcaddy build \
#到 https://caddyserver.com/download 寻找所需要的插件添加到此处 记得前面加上--with
#我的域名由Cloudflare提供DNS服务 所以添加caddy-dns/cloudflare插件
#顺手加上其他需要的插件 比如Webdav
#   --with github.com/mholt/caddy-webdav \
    --with github.com/caddy-dns/cloudflare

#叠加所需的原始镜像，alpine挺好的
FROM caddy:alpine

COPY --from=builder /usr/bin/caddy /usr/bin/caddy
