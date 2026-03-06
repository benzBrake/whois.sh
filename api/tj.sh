#!/usr/bin/env bash
# TJ Domain Registry - http://www.nic.tj/
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

# 提取域名关键字（去掉 .tj 后缀）
KEYWORD=$(echo "$DOMAIN" | sed 's/\.tj$//' | sed 's/\.$//')
if [[ -z "$KEYWORD" ]]; then
    echo "Error: Invalid domain format." >&2
    exit 1
fi

# 查询 .TJ 域名的 WHOIS 信息
RESULT=$(curl -s "http://www.nic.tj/cgi/whois2?domain=${KEYWORD}")

# 检查是否包含 "no records found" 表示域名未注册
if echo "$RESULT" | grep -qi "no records found"; then
    echo "Status: available"
else
    # 域名已注册，提取并格式化输出
    # 1. 移除 HTML 标签
    # 2. 移除 CSS 样式（包含 { } 的行，或包含常见 CSS 属性的行）
    # 3. 移除空行
    echo "$RESULT" | \
        sed 's/<[^>]*>//g' | \
        sed 's/&nbsp;/ /g' | \
        awk '/\{|\}/ {next} /font-family|font-size|text-align|text-transform|vertical-align|padding-top|width:|border-bottom/ {next} /^[[:space:]]*$/ {next} {gsub(/^[[:space:]]+|[[:space:]]+$/, ""); if (length($0) > 0) print}'
fi
