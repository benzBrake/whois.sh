#!/usr/bin/env bash
# .gw 域名查询脚本
# 通过 registar.nic.gw 提供的 HTTP API 查询

# 设置工作目录
WHOIS_WORKING_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/.."
source "$WHOIS_WORKING_DIR/inc/functions.sh"

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

# 验证是否为 .gw 域名
if [[ ! "$DOMAIN" =~ \.gw$ ]]; then
    echo "Error: This script only supports .gw domains." >&2
    exit 1
fi

# 提取域名主体（去掉 .gw 后缀）
DOMAIN_BASE="${DOMAIN%.gw}"

# 构建 API URL
API_URL="https://registar.nic.gw/whois/${DOMAIN_BASE}.gw/"

# 发起 HTTP 请求
HTTP_RESPONSE=$(curl -s -w "\n%{http_code}" "$API_URL" 2>/dev/null)

# 分离响应体和状态码
HTTP_BODY=$(echo "$HTTP_RESPONSE" | head -n -1)
HTTP_STATUS=$(echo "$HTTP_RESPONSE" | tail -n 1)

if [[ "$HTTP_STATUS" == "404" ]]; then
    # 域名不存在
    echo "DOMAIN: $DOMAIN"
    echo "STATUS: available"
elif [[ "$HTTP_STATUS" == "200" ]]; then
    # 域名存在，提取 whois 数据
    # 先移除 HTML 注释中的内容（已废弃的数据）
    echo "$HTTP_BODY" | sed -n '/<article class="post">/,/<\/article>/p' | \
    sed -e '/<!--/,/-->/d' \
        -e 's/<fieldset>/\n##FIELDSET##\n/g' \
        -e 's/<\/fieldset>//g' \
        -e 's/<span>/\n##SECTION##/g' \
        -e 's/<\/span>//g' \
        -e 's/<label>/\nLABEL:/g' \
    | awk '
    BEGIN {
        section = ""
        pending_label = ""
    }
    /^##SECTION##/ {
        sub(/^##SECTION##/, "")
        if (NF > 0) {
            if (section != "") print ""
            section = $0
            gsub(/^[[:space:]]+|[[:space:]]+$/, "", section)
            print section ":"
        }
        next
    }
    /^##FIELDSET##/ {
        next
    }
    /^LABEL:/ {
        # 处理 LABEL:xxx:</label> 行
        sub(/^LABEL:/, "")
        sub(/<\/label>.*/, "")
        gsub(/^[[:space:]]+|[[:space:]]+$/, "")
        # 移除 label 末尾的冒号（HTML 中已有）
        gsub(/:$/, "", $0)
        pending_label = $0
        # 读取下一行获取值
        getline
        value = $0
        # 移除剩余的 HTML 标签和实体
        gsub(/<[^>]*>/, "", value)
        gsub(/&nbsp;/, "", value)
        gsub(/^[[:space:]]+|[[:space:]]+$/, "", value)

        if (pending_label != "" && value != "" && value !~ /^LABEL:/) {
            print "  " pending_label ": " value
        }
        next
    }
    '
    echo ""
else
    # 其他错误状态码
    echo "Error: HTTP $HTTP_STATUS - Unable to query whois information." >&2
    exit 1
fi
