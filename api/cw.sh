#!/usr/bin/env bash
# 设置工作目录
WHOIS_WORKING_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/.."
source "$WHOIS_WORKING_DIR/inc/functions.sh"
source "$WHOIS_WORKING_DIR/inc/dns.sh"

# 验证参数
DOMAIN="$1"
if [[ -z "$DOMAIN" ]]; then
    echo "Error: No domain specified." >&2
    exit 1
fi

# 验证域名安全性
if ! __validate_domain "$DOMAIN"; then
    echo "Error: Invalid domain format." >&2
    exit 1
fi

# 使用 URL 编码防止注入
ENCODED_DOMAIN=$(__escape_url "$DOMAIN")

# 查询 .cw whois API
RESULT=$(curl -s "https://cw.whois.testing.za.net/api/check?domain=${ENCODED_DOMAIN}" \
    -H 'Accept: application/json' \
    -H 'Connection: keep-alive')

# 检查 API 响应是否有效
if ! echo "$RESULT" | grep -q '"registered"'; then
    echo "# Error: Invalid API response for $DOMAIN"
    __dns_query_ns_smart "$DOMAIN"
    exit 1
fi

# 解析 JSON 响应
REGISTERED=$(echo "$RESULT" | grep -o '"registered":[^,}]*' | cut -d':' -f2)

if [[ "$REGISTERED" == "true" ]]; then
    # 域名已注册，提取详细信息
    echo "# Domain Information for: $DOMAIN"
    echo "# Source: https://cw.whois.testing.za.net"
    echo ""
    echo "STATUS: registered"
    __dns_query_ns_simple "$DOMAIN"
else
    echo "# ========================================"
    echo "# Domain $DOMAIN is available for registration"
    echo "# Source: https://cw.whois.testing.za.net"
    echo "# Note: Data is periodically synced from official registry,"
    echo "#       availability is not guaranteed."
    echo "# ========================================"
    echo ""
    echo "STATUS: available"
fi
