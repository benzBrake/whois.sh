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

# 创建临时 cookie 文件
COOKIE_FILE=$(mktemp)

HTML_CONTENT=$(__curl_get "https://grweb.ics.forth.gr/public/whois?lang=en")

# 提取 CSRF token（使用简单可靠的方法）
CSRF_TOKEN=$(echo "$HTML_CONTENT" | sed -n 's/.*name="_csrf"[[:space:]]*value="\([^"]*\)".*/\1/p' | head -1)

if [[ -z "$CSRF_TOKEN" ]]; then
    echo "Error: Failed to get CSRF token." >&2
    rm -f "$COOKIE_FILE"
    exit 1
fi
RESULT=$(__curl_post "https://grweb.ics.forth.gr/public/whois/query?lang=en" "_csrf=${CSRF_TOKEN}&domain=${DOMAIN}&Submit=")

# 检查页面是否包含域名数据
if echo "$RESULT" | grep -qi "${DOMAIN}"; then
    # 提取并显示 whois 信息
    echo "# Domain Information for: $DOMAIN"
    echo "# Source: https://grweb.ics.forth.gr/public/whois"
    echo ""

    # 提取状态
    STATUS=$(echo "$RESULT" | grep -o '<strong>[^<]*</strong>' | sed 's/<[^>]*>//g' | head -1)
    if [[ -n "$STATUS" ]]; then
        echo "$STATUS" | sed 's/'"${DOMAIN}"'\s*:\s*/Status: /'
    fi

    # 按 list-group-item 分割并提取每一项的信息（包括域名信息和注册商信息）
    echo "$RESULT" | sed 's/<li class="list-group-item">/\n---ITEM---\n/g' | \
        awk '
        BEGIN {
            item = "";
            label = "";
            value = "";
            section = ""
        }
        /---ITEM---/ {
            if (label != "" && value != "") {
                print label ": " value
            }
            label = ""
            value = ""
            next
        }
        /card-heading/ {
            # 检测新的卡片标题（域名信息或注册商信息）
            match($0, />([^<]+)</, arr)
            if (arr[1] !~ /^[[:space:]]*$/) {
                section = arr[1]
                gsub(/^[[:space:]]+/, "", section)
                gsub(/[[:space:]]+$/, "", section)
                # 如果是新的部分，打印分隔线
                if (section != "" && section !~ /Domain Information/) {
                    print "\n[" section "]"
                }
            }
        }
        /col-form-label/ {
            # 提取标签
            match($0, />([^<]+)</, arr)
            if (arr[1] !~ /^[[:space:]]*$/) {
                label = arr[1]
                gsub(/^[[:space:]]+/, "", label)
                gsub(/[[:space:]]+$/, "", label)
            }
        }
        /text-color/ {
            # 提取值（可能有多行）
            match($0, />([^<]+)</, arr)
            if (arr[1] !~ /^[[:space:]]*$/ && arr[1] !~ /^[[:space:]]*\/[[:space:]]*$/) {
                if (value == "") {
                    value = arr[1]
                } else {
                    value = value ", " arr[1]
                }
                gsub(/^[[:space:]]+/, "", value)
                gsub(/[[:space:]]+$/, "", value)
            }
        }
        END {
            if (label != "" && value != "") {
                print label ": " value
            }
        }' 2>/dev/null

    echo ""
    __dns_query_ns_smart "$DOMAIN"
else
    # 没有查询到 whois 信息
    echo "# ========================================"
    echo "# No whois information found for $DOMAIN"
    echo "# Possible reasons:"
    echo "#   1. Domain is available for registration"
    echo "#   2. Domain information is hidden/protected"
    echo "#   3. The registry website may be unavailable"
    echo "# Please verify at: https://grweb.ics.forth.gr/public/whois"
    echo "# ========================================"
    echo ""

    __dns_query_ns_smart "$DOMAIN"
fi
