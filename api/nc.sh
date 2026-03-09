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

# 解析域名
# 支持: .nc, .asso.nc, .nom.nc
TLD=$(echo "$DOMAIN" | sed 's#.*\.##')
if [[ "$TLD" != "nc" ]]; then
    echo "Error: This script only supports .nc domains." >&2
    exit 1
fi

# 移除 .nc 后缀
REMAINING=$(echo "$DOMAIN" | sed 's#\.nc$##')

# 检查是否有二级后缀
SLD=""
DOMAIN_NAME=""
if echo "$REMAINING" | grep -q '\.'; then
    # 有二级后缀，提取 SLD 和域名
    SLD=$(echo "$REMAINING" | sed 's#.*\.##')
    DOMAIN_NAME=$(echo "$REMAINING" | sed "s#\.${SLD}\$##")
    # 验证 SLD 是否为支持的类型
    if [[ "$SLD" != "asso" && "$SLD" != "nom" ]]; then
        echo "Error: Unsupported second-level domain '.$SLD.nc'. Supported: .nc, .asso.nc, .nom.nc" >&2
        exit 1
    fi
    EXT=".$SLD.nc"
else
    # 没有二级后缀
    DOMAIN_NAME="$REMAINING"
    EXT=".nc"
fi

# URL 编码域名
ENCODED_DOMAIN=$(__escape_url "$DOMAIN_NAME")
ENCODED_EXT=$(__escape_url "$EXT")

RESULT=$(__curl_get "https://www.domaine.nc/whos?domain=${ENCODED_DOMAIN}&ext=${ENCODED_EXT}")

# 检查是否包含域名信息
# 新喀里多尼亚 whois 页面会显示域名信息
if echo "$RESULT" | grep -qi "DOMAINE\|Date de création"; then
    # 提取并显示 whois 信息
    echo "# Domain Information for: $DOMAIN"
    echo "# Source: https://www.domaine.nc/whos"
    echo ""

    # 解析表格结构提取域名信息
    # 先清理 HTML，然后提取有用信息
    echo "$RESULT" | awk '
        BEGIN { in_domain = 0; domain_name = ""; extension = ""; printed_domain = 0 }
        /DOMAINE/ { in_domain = 1 }
        /BENEFICIAIRE/ { in_domain = 0; exit }
        in_domain {
            # 移除所有 HTML 标签
            gsub(/<[^>]*>/, " ")
            # 清理多余空白和 HTML 实体
            gsub(/&nbsp;/, " ")
            gsub(/&amp;/, "&")
            gsub(/&lt;/, "<")
            gsub(/&gt;/, ">")
            gsub(/[[:space:]]+/, " ")
            gsub(/^[[:space:]]|[[:space:]]$/, "")
            if (NF > 0) print
        }
        ' | \
        awk -v full_domain="$DOMAIN" '
        BEGIN { printed_domain = 0 }
        {
            # 清理可能的残留
            gsub(/^[[:space:]]+|[[:space:]]+$/, "")
            if (NF == 0) next
        }
        /^Nom$/ && !printed_domain {
            getline
            domain_name = $0
            gsub(/^[[:space:]]+|[[:space:]]+$/, "", domain_name)
            next
        }
        /^Extension$/ && !printed_domain {
            getline
            extension = $0
            gsub(/^[[:space:]]+|[[:space:]]+$/, "", extension)
            if (domain_name != "" && extension != "") {
                print "Domain: " domain_name "." extension
                printed_domain = 1
            }
            next
        }
        /^Date de création$/ {
            getline
            value = $0
            gsub(/^[[:space:]]+|[[:space:]]+$/, "", value)
            if (value != "" && value !~ /[a-z]/) print "Created: " value
            next
        }
        /^Date de modification$/ {
            getline
            value = $0
            gsub(/^[[:space:]]+|[[:space:]]+$/, "", value)
            if (value != "" && value !~ /[a-z]/) print "Updated: " value
            next
        }
        /^Date d/ {
            getline
            value = $0
            gsub(/^[[:space:]]+|[[:space:]]+$/, "", value)
            if (value != "" && value !~ /[a-z]/) print "Expires: " value
            next
        }
        /^Gestionnaire$/ {
            getline
            value = $0
            gsub(/^[[:space:]]+|[[:space:]]+$/, "", value)
            if (value != "") print "Owner: " value
            next
        }
        /^[a-z0-9]+\.(nc|asso\.nc|nom\.nc)$/ {
            print "  NS: " $0
        }
        '

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
    echo "# Please verify at: https://www.domaine.nc/whos"
    echo "# ========================================"
    echo ""

    __dns_query_ns_smart "$DOMAIN"
fi
