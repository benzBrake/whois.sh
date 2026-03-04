#!/usr/bin/env bash
# RDAP (Registration Data Access Protocol) 查询模块
# 用于通过 HTTP/JSON 查询域名信息

# 加载依赖
WHOIS_WORKING_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/.."
source "$WHOIS_WORKING_DIR/inc/functions.sh"

# RDAP 查询函数
rdap_query() {
    local domain="$1"
    local server="$2"  # 格式: rdap://server/path/

    # 验证输入
    if [[ -z "$domain" ]]; then
        echo "Error: No domain specified." >&2
        return 1
    fi

    if ! __validate_domain "$domain"; then
        echo "Error: Invalid domain format." >&2
        return 1
    fi

    # 提取 RDAP 服务器 URL（将 rdap:// 替换为 https://）
    local rdap_url="${server#rdap://}"
    rdap_url="https://${rdap_url}"

    # 执行 RDAP 查询
    local rdap_json
    rdap_json=$(__rdap_query "$domain" "$rdap_url")

    if [[ -z "$rdap_json" ]]; then
        echo "Error: RDAP query failed." >&2
        return 1
    fi

    # 检查是否为错误响应（使用 jq）
    if command -v jq &>/dev/null; then
        local error_code=$(echo "$rdap_json" | jq -r '.errorCode // empty')
        if [[ -n "$error_code" ]]; then
            local error_title=$(echo "$rdap_json" | jq -r '.title // "Unknown error"')
            echo "Error ${error_code}: ${error_title}" >&2

            # 404 表示域名可能可用
            if [[ "$error_code" == "404" ]]; then
                echo "Status: available"
            fi
            return 1
        fi
    fi

    # 解析并输出 whois 格式结果
    __rdap_parse "$rdap_json"
}

# 如果直接执行此脚本
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    if [[ $# -lt 2 ]]; then
        echo "Usage: $0 <domain> <rdap_server>" >&2
        echo "Example: $0 google.dev rdap://pubapi.registry.google/rdap/" >&2
        exit 1
    fi

    rdap_query "$1" "$2"
fi
