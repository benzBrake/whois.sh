#!/usr/bin/env bash
# 设置工作目录
WHOIS_WORKING_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/.."
source "$WHOIS_WORKING_DIR/inc/functions.sh"
source "$WHOIS_WORKING_DIR/inc/dns.sh"
source "$WHOIS_WORKING_DIR/inc/curl.sh"

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

RESULT=$(__curl_post "https://whois.telecoms.gov.bb/search/" "Domain=${DOMAIN}")

# 检查是否显示 "No results found"
if echo "$RESULT" | grep -qi "No results found"; then
    __dns_query_ns_smart "$DOMAIN"
else
    # 提取表格中的 whois 信息
    TABLE_CONTENT=$(echo "$RESULT" | sed -n '/<table class="results">/,/<\/table>/p' | \
        sed 's/<[^>]*>//g' | sed 's/&nbsp;/ /g' | sed '/^$/d')

    if [[ -n "$TABLE_CONTENT" ]]; then
        echo "$TABLE_CONTENT"
        echo ""
        __dns_query_ns_smart "$DOMAIN"
    else
        # 无法解析，返回原始响应中的关键信息
        echo "$RESULT" | grep -i "domain\|status\|registrant\|nameserver" | head -20
    fi
fi
