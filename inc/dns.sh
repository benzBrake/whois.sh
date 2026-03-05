#!/usr/bin/env bash
# DNS 查询模块
# 提供通用的 DNS 查询函数

# ============ DNS 查询函数 ============

# 使用 nslookup 查询 NS 记录
# 参数: $1 - 域名
# 返回: NS 记录列表（每行一个）
__dns_query_nslookup() {
    local domain="$1"
    nslookup -type=ns "$domain" 2>/dev/null | grep -i "nameserver" | awk '{print $NF}'
}

# 使用 Google DNS API 查询 NS 记录
# 参数: $1 - 域名
# 返回: JSON 格式的 DNS 响应
__dns_query_google_api() {
    local domain="$1"
    curl -s "https://dns.google/resolve?name=${domain}&type=NS" 2>/dev/null
}

# 从 Google DNS API 响应中提取状态
# 参数: $1 - JSON 响应
# 返回: DNS 状态码 (0=NOERROR, 3=NXDOMAIN)
__dns_google_status() {
    local json="$1"
    echo "$json" | grep -o '"Status":[0-9]' | sed 's/"Status"://'
}

# 从 Google DNS API 响应中提取 NS 记录
# 参数: $1 - JSON 响应
# 返回: NS 记录列表（每行一个）
__dns_google_extract_ns() {
    local json="$1"
    echo "$json" | grep -o '"data":"[^"]*"' | sed 's/"data":"//g;s/"$//g'
}

# 智能查询 NS 记录（优先使用 Google DNS API，失败则回退到 nslookup）
# 参数: $1 - 域名
# 输出格式:
#   STATUS: registered|available
#   NS: ns1.example.com
#   NS: ns2.example.com
__dns_query_ns_smart() {
    local domain="$1"
    local dns_response
    local dns_status

    # 尝试使用 Google DNS API
    dns_response="$(__dns_query_google_api "$domain")"

    if [[ -n "$dns_response" ]]; then
        dns_status="$(__dns_google_status "$dns_response")"

        if [[ "$dns_status" == "0" ]]; then
            # 域名存在，输出 NS 记录
            local ns_records
            ns_records="$(__dns_google_extract_ns "$dns_response")"

            if [[ -n "$ns_records" ]]; then
                echo "STATUS: registered"
                echo "$ns_records" | while read -r ns; do
                    [[ -n "$ns" ]] && echo "NS: $ns"
                done
            else
                echo "STATUS: registered (no nameservers configured)"
            fi
            return 0
        elif [[ "$dns_status" == "3" ]]; then
            # 域名不存在
            echo "STATUS: available"
            return 0
        fi
    fi

    # Google DNS API 失败，回退到 nslookup
    local ns_output
    ns_output="$(__dns_query_nslookup "$domain")"

    if [[ -n "$ns_output" ]]; then
        echo "STATUS: registered"
        echo "$ns_output" | while read -r ns; do
            [[ -n "$ns" ]] && echo "NS: $ns"
        done
    else
        echo "STATUS: available"
    fi
}

# 简单查询 NS 记录（仅使用 nslookup）
# 参数: $1 - 域名
# 输出格式:
#   NS: ns1.example.com
#   NS: ns2.example.com
__dns_query_ns_simple() {
    local domain="$1"
    local ns_output
    ns_output="$(__dns_query_nslookup "$domain")"

    if [[ -n "$ns_output" ]]; then
        echo "$ns_output" | while read -r ns; do
            [[ -n "$ns" ]] && echo "NS: $ns"
        done
    fi
}

# 带 URL 提示的 DNS 查询（用于无 whois 服务器的域名）
# 参数: $1 - 域名, $2 - 注册局 URL（可选）
# 输出格式:
#   提示信息
#   空行
#   DNS 查询结果
__dns_query_with_url_hint() {
    local domain="$1"
    local reg_url="${2:-}"
    local tld="${domain##*.}"

    echo "# ========================================"
    echo "# NOTE: This TLD does not provide a standard whois service"
    echo "# The following results are based on DNS queries only"
    echo "# Please refer to the official registry website for accurate information"
    if [[ -n "$reg_url" ]]; then
        echo "# Official query URL: $reg_url"
    fi
    echo "# ========================================"
    echo ""

    __dns_query_ns_smart "$domain"
}
