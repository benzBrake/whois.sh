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

RESULT=$(__curl_get "https://www.nic.cu/dom_det.php?domsrch=${DOMAIN}")

# 检查页面是否包含实际的域名数据
if echo "$RESULT" | grep -q "<td.*>.*${DOMAIN}.*</td>"; then
    echo "# Domain Information for: $DOMAIN"
    echo "# Source: https://www.nic.cu"
    echo ""

    # 提取并显示 whois 信息
    # 使用 sed 先将所有 <td> 标签替换为分隔符，然后提取内容
    echo "$RESULT" | sed 's/<td[^>]*>/|TD|/g' | \
        sed 's/<\/td>/|\/TD|/g' | \
        tr '\n' ' ' | \
        sed 's/|TD|/\n/g' | \
        sed 's/|\/TD|//g' | \
        sed 's/<[^>]*>//g' | \
        sed 's/&nbsp;/ /g' | \
        sed 's/&aacute;/á/g; s/&eacute;/é/g; s/&iacute;/í/g; s/&oacute;/ó/g; s/&uacute;/ú/g; s/&ntilde;/ñ/g' | \
        sed 's/^[[:space:]]*//; s/[[:space:]]*$//' | \
        sed '/^$/d' | \
        awk -v domain="$DOMAIN" '
        BEGIN {
            label = ""
        }
        {
            content = $0
            gsub(/^[[:space:]]+/, "", content)
            gsub(/[[:space:]]+$/, "", content)

            # 如果内容以冒号结尾，则是标签
            if (content ~ /:$/) {
                label = content
            } else if (label != "" && content != "" && content !~ /^(td|<)/) {
                # 这是值，如果标签包含关键字则输出
                if (label ~ /Dominio|Organización|Dirección|Nombre|Teléfono|Fax|IP|Email|Ciudad|País/) {
                    print label " " content
                }
                label = ""
            }
        }
        ' | head -30

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
    echo "# Please verify at: https://www.nic.cu/dom_det.php?domsrch=${DOMAIN}"
    echo "# ========================================"
    echo ""

    __dns_query_ns_smart "$DOMAIN"
fi
