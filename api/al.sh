#!/usr/bin/env bash
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

# 提取域名关键字（去掉 .al 后缀）
KEYWORD=$(echo "$DOMAIN" | sed 's/\.al$//' | sed 's/\.$//')
if [[ -z "$KEYWORD" ]]; then
    echo "Error: Invalid domain format." >&2
    exit 1
fi

# 使用 URL 编码防止注入
ENCODED_KEYWORD=$(__escape_url "$KEYWORD")

# 查询 name.al 官方 API
RESULT=$(curl -s "https://name.al/api/namesuggestions/keyword-availability/${ENCODED_KEYWORD}?tlds=al" \
    -H 'Accept: application/json, text/plain, */*' \
    -H 'User-Agent: Mozilla/5.0')

# 解析 JSON 响应
AVAILABILITY=$(echo "$RESULT" | sed -n 's/.*"availability":"\([^"]*\)".*/\1/p' | head -1)

# 输出结果
if [[ "$AVAILABILITY" == "available" ]]; then
    echo "Status: available"
elif [[ "$AVAILABILITY" == "unavailable" ]]; then
    echo "Status: registered"

    # 查询 NS 记录
    NS_OUTPUT=$(nslookup -type=ns "$DOMAIN" 2>/dev/null)

    # 提取每条 NS 记录并多行输出
    echo "$NS_OUTPUT" | grep -i "nameserver" | awk '{print "NS: " $NF}'
else
    # 解析失败，返回原始响应
    echo "$RESULT"
fi
