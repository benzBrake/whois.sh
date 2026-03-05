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

# 提取域名关键字（去掉 .al 后缀）
KEYWORD=$(echo "$DOMAIN" | sed 's/\.al$//' | sed 's/\.$//')
if [[ -z "$KEYWORD" ]]; then
    echo "Error: Invalid domain format." >&2
    exit 1
fi

# 查询 .al 官方 whois 网页
RESULT=$(curl -s 'https://cctld.akep.al//whois.al.local/web_root/index.php?c=whois' \
    -X POST \
    -H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8' \
    -H 'Content-Type: application/x-www-form-urlencoded' \
    -H 'Origin: https://cctld.akep.al' \
    -H 'Referer: https://cctld.akep.al//whois.al.local/web_root/index.php?c=whois' \
    -H 'Connection: keep-alive' \
    --data-urlencode "domain=${DOMAIN}")

# 解析 HTML 响应判断域名状态
# 优先检查明确的域名状态语句（如 "Domain xxx is registered"）
if echo "$RESULT" | grep -qi "Domain.*is registered"; then
    echo "Status: registered"
    __dns_query_ns_simple "$DOMAIN"
elif echo "$RESULT" | grep -qi "Domain.*is available\|Domain.*not registered\|Domain.*is free\|no match"; then
    echo "Status: available"
elif echo "$RESULT" | grep -qi "Domain.*taken\|Domain.*unavailable"; then
    echo "Status: registered"
    __dns_query_ns_simple "$DOMAIN"
else
    # 解析失败，返回原始响应的部分内容
    echo "$RESULT" | grep -i "domain\|status\|available\|registered" | head -20
fi
