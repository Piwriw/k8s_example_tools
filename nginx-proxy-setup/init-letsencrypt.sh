#!/bin/bash

# Nginx HTTPS 反向代理 - Let's Encrypt 证书初始化脚本
# 用法: ./init-letsencrypt.sh YOUR_DOMAIN YOUR_EMAIL

if [ $# -lt 2 ]; then
    echo "用法: $0 <域名> <邮箱>"
    echo "示例: $0 example.com admin@example.com"
    exit 1
fi

DOMAIN=$1
EMAIL=$2
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "=== 初始化 Let's Encrypt 证书 ==="
echo "域名: $DOMAIN"
echo "邮箱: $EMAIL"

# 创建目录
mkdir -p "$SCRIPT_DIR/certbot/conf"
mkdir -p "$SCRIPT_DIR/certbot/www"

# 1. 先用临时配置启动 nginx（仅 HTTP，用于证书验证）
echo "[1/4] 生成临时 nginx 配置..."
cat > "$SCRIPT_DIR/nginx/conf.d/default.conf" <<EOF
server {
    listen 80;
    server_name $DOMAIN;

    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
    }
}
EOF

echo "[2/4] 启动 nginx（仅 HTTP 模式）..."
cd "$SCRIPT_DIR"
docker compose up -d nginx
sleep 5

# 2. 申请证书
echo "[3/4] 申请 Let's Encrypt 证书..."
docker compose run --rm --entrypoint "certbot" certbot certonly \
    --webroot \
    --webroot-path=/var/www/certbot \
    --email "$EMAIL" \
    --agree-tos \
    --no-eff-email \
    -d "$DOMAIN"

if [ $? -ne 0 ]; then
    echo "证书申请失败！请检查："
    echo "  1. 域名 $DOMAIN 是否已解析到本机 IP"
    echo "  2. 80 端口是否对外开放"
    exit 1
fi

# 3. 替换为正式配置
echo "[4/4] 生成正式 nginx 配置..."
cat > "$SCRIPT_DIR/nginx/conf.d/default.conf" <<EOF
server {
    listen 80;
    server_name $DOMAIN;

    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
    }

    location / {
        return 301 https://\$host\$request_uri;
    }
}

server {
    listen 443 ssl;
    server_name $DOMAIN;

    ssl_certificate /etc/letsencrypt/live/$DOMAIN/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$DOMAIN/privkey.pem;

    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;

    # gzip 压缩
    gzip on;
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript image/svg+xml;
    gzip_min_length 1024;
    gzip_comp_level 6;

    # 代理缓冲区
    proxy_buffer_size 16k;
    proxy_buffers 4 64k;
    proxy_busy_buffers_size 128k;

    location /assets/ {
        proxy_pass http://host.docker.internal:30080;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;

        # 静态资源浏览器缓存 7 天
        expires 7d;
        add_header Cache-Control "public, immutable";
    }

    location / {
        proxy_pass http://host.docker.internal:30080;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;

        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }
}
EOF

# 4. 重启 nginx 加载正式配置
echo "重启 nginx..."
docker compose up -d --force-recreate nginx

echo ""
echo "=== 完成！==="
echo "HTTPS 反向代理已启动："
echo "  HTTPS: https://$DOMAIN"
echo "  后端:  http://host.docker.internal:30080"
echo ""
echo "证书自动续期已配置（certbot 容器每 12 小时检查续期）"
