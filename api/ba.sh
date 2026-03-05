#!/usr/bin/env bash
# .ba 域名查询脚本
# 由于 nic.ba 官方只提供网页查询且需要人机交互，
# 本脚本通过 DNS/NS 查询的方式来检测域名是否存在

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

# 验证是否为 .ba 域名
if [[ ! "$DOMAIN" =~ \.ba$ ]]; then
    echo "Error: This script only supports .ba domains." >&2
    exit 1
fi

# 使用智能 DNS 查询（优先 Google DNS API，失败则回退到 nslookup）
__dns_query_ns_smart "$DOMAIN"
