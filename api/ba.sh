#!/usr/bin/env bash
# .ba 域名查询脚本
# 由于 nic.ba 官方只提供网页查询且需要人机交互，
# 本脚本通过 DNS/NS 查询的方式来检测域名是否存在

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

# 验证是否为 .ba 域名
if [[ ! "$DOMAIN" =~ \.ba$ ]]; then
    echo "Error: This script only supports .ba domains." >&2
    exit 1
fi

# 使用公共 DNS API 查询 NS 记录（使用 Google DNS API）
# Google DNS API: https://dns.google/resolve
# 域名只包含安全字符，无需 URL 编码

DNS_QUERY_URL="https://dns.google/resolve?name=${DOMAIN}&type=NS"

# 获取 DNS 响应（JSON 格式）
DNS_RESPONSE=$(curl -s "$DNS_QUERY_URL" 2>/dev/null)

# 检查是否有 NS 记录
# Status 0 = NOERROR, 3 = NXDOMAIN
DNS_STATUS=$(echo "$DNS_RESPONSE" | grep -o '"Status":[0-9]' | sed 's/"Status"://')

if [[ "$DNS_STATUS" == "0" ]]; then
    # 域名存在，提取 NS 记录
    NS_RECORDS=$(echo "$DNS_RESPONSE" | grep -o '"data":"[^"]*"' | sed 's/"data":"//g;s/"$//g')

    if [[ -n "$NS_RECORDS" ]]; then
        # 域名已注册，输出 whois 格式的结果
        echo "DOMAIN: $DOMAIN"
        echo "STATUS: registered"
        echo ""
        echo "Nameservers:"
        echo "$NS_RECORDS" | while read -r ns; do
            [[ -n "$ns" ]] && echo "  $ns"
        done
    else
        # 没有找到 NS 记录，可能是未配置或刚注册
        echo "DOMAIN: $DOMAIN"
        echo "STATUS: registered (no nameservers configured)"
    fi
elif [[ "$DNS_STATUS" == "3" ]]; then
    # 域名不存在
    echo "DOMAIN: $DOMAIN"
    echo "STATUS: available"
else
    # DNS 查询失败，尝试使用 nslookup 作为备用方案
    NS_OUTPUT=$(nslookup -type=ns "$DOMAIN" 2>/dev/null)

    if echo "$NS_OUTPUT" | grep -qi "nameserver"; then
        echo "DOMAIN: $DOMAIN"
        echo "STATUS: registered"
        echo ""
        echo "Nameservers:"
        echo "$NS_OUTPUT" | grep -i "nameserver" | awk '{print "  " $NF}'
    else
        echo "DOMAIN: $DOMAIN"
        echo "STATUS: unknown (query failed)"
    fi
fi
