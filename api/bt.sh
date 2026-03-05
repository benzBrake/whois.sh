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

# 提取域名关键字（去掉 .bt 后缀）
KEYWORD=$(echo "$DOMAIN" | sed 's/\.bt$//' | sed 's/\.$//')
if [[ -z "$KEYWORD" ]]; then
    echo "Error: Invalid domain format." >&2
    exit 1
fi

# 查询 .bt 官方 whois 网页
# 域名关键字只包含安全字符，无需 URL 编码
RESULT=$(curl -s "https://www.nic.bt/search?query=${KEYWORD}&ext=.bt" \
    -H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8' \
    -H 'User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36' \
    -H 'Connection: keep-alive')

# 检查是否包含域名详情信息（说明已注册）
if echo "$RESULT" | grep -qi "Domain Name :"; then
    # 移除 HTML 标签并格式化输出
    echo "$RESULT" | sed 's/<[^>]*>//g' | \
        sed 's/&nbsp;/ /g' | \
        grep -E "Domain Name|Registrar|Registration Date|Renewal Date|Expiration Date|Customer Name|Address|PostalCode|Phone|Email|Country|Name|Fax" | \
        sed 's/^[[:space:]]*//'

    echo ""
    __dns_query_ns_simple "$DOMAIN"
else
    # 没有查询到 whois 信息
    # 尝试 DNS 查询判断域名状态
    echo "# ========================================"
    echo "# No whois information found for $DOMAIN"
    echo "# Possible reasons:"
    echo "#   1. Domain is available for registration"
    echo "#   2. Domain information is hidden/protected"
    echo "#   3. The registry website may be unavailable"
    echo "# Please verify at: https://www.nic.bt/search?query=${KEYWORD}&ext=.bt"
    echo "# ========================================"
    echo ""

    __dns_query_ns_smart "$DOMAIN"
fi
