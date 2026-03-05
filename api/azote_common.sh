#!/usr/bin/env bash
# Azote.org 免费域名查询通用脚本
# 被 fr.nf.sh, asso.st.sh, infos.st.sh, biz.st.sh 调用

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

# 根据传入的域名确定后缀
# 支持: .fr.nf, .asso.st, .infos.st, .biz.st
SUPPORTED_EXTENSIONS=("fr.nf" "asso.st" "infos.st" "biz.st")
EXT=""
DOMAIN_NAME=""

for ext in "${SUPPORTED_EXTENSIONS[@]}"; do
    if echo "$DOMAIN" | grep -q "\.${ext}\$"; then
        EXT=".$ext"
        DOMAIN_NAME=$(echo "$DOMAIN" | sed "s/\\.${ext//./\\.}$//")
        break
    fi
done

if [[ -z "$EXT" ]]; then
    echo "Error: Unsupported domain extension. Supported: .fr.nf, .asso.st, .infos.st, .biz.st" >&2
    exit 1
fi

# URL 编码域名（域名通常只包含字母数字和连字符，不需要复杂编码）
# 直接使用域名即可，因为 azote.org 支持简单域名
ENCODED_DOMAIN=$(echo "$DOMAIN_NAME" | tr -d '\n\r')

# 查询 azote.org 接口
RESULT=$(curl -s "https://azote.org/verifications-${ENCODED_DOMAIN}.html" \
    -H 'User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36' \
    -H 'Accept-Language: en-US,en;q=0.9' \
    -H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8')

# 提取当前域名状态
# 搜索包含域名的行
SEARCH_LINE=$(echo "$RESULT" | grep "${DOMAIN_NAME}${EXT}")

DOMAIN_STATUS=""
if echo "$SEARCH_LINE" | grep -q ">Pris<"; then
    DOMAIN_STATUS="Pris"
elif echo "$SEARCH_LINE" | grep -q ">Libre<"; then
    DOMAIN_STATUS="Libre"
fi

if [[ -z "$DOMAIN_STATUS" ]]; then
    echo "# ========================================"
    echo "# Unable to determine domain status"
    echo "# Domain: $DOMAIN"
    echo "# Please verify at: https://azote.org/verifications-${ENCODED_DOMAIN}.html"
    echo "# ========================================"
    echo ""
    __dns_query_ns_smart "$DOMAIN"
    exit 0
fi

# 显示域名信息
echo "# Domain Information for: $DOMAIN"
echo "# Source: https://azote.org"
echo ""

if [[ "$DOMAIN_STATUS" == "Pris" ]]; then
    echo "Status: REGISTERED"
    echo "Domain: $DOMAIN"
    echo ""
    echo "# This domain is already registered (Pris = Taken)"
    echo ""

    # 尝试 DNS 查询获取更多信息
    __dns_query_ns_simple "$DOMAIN"
else
    echo "Status: AVAILABLE"
    echo "Domain: $DOMAIN"
    echo ""
    echo "# This domain is available for registration (Libre = Free)"
    echo "# Register at: https://azote.org/enregistrer-${ENCODED_DOMAIN}${EXT}.html"
fi
