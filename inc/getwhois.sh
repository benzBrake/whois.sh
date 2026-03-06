#!/usr/bin/env bash
# shellcheck source=functions.sh
source "$(dirname "${BASH_SOURCE[0]}")/functions.sh"
# 设置工作目录
if [[ -z "$WHOIS_WORKING_DIR" ]]; then
    WHOIS_WORKING_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/.."
fi

# 安全的参数解析
while [[ $# -gt 0 && $1 =~ ^- ]]; do
    key="$1"
    case "$key" in
        -h|-host|--host)
            SERVER="$2"
            shift 2
            ;;
        -p|-port|--port)
            PORT="$2"
            shift 2
            ;;
        *)
            echo "Unknown option: $1" >&2
            exit 1
            ;;
    esac
done

# 剩余参数作为域名
DOMAIN="$*"

# 设置默认值
PORT="${PORT:-43}"
SERVER="${SERVER:-}"

# 验证必需参数
if [[ -z "$DOMAIN" ]]; then
    echo "Error: No domain specified." >&2
    exit 1
fi

# 验证域名安全性
if ! __validate_domain "$DOMAIN"; then
    echo "Error: Invalid domain format." >&2
    exit 1
fi

if [[ -z "$SERVER" ]]; then
    # 自动检测 whois 服务器
    TLD=$(__get_tld "$DOMAIN")

    # 验证 TLD 安全性
    if ! __validate_hostname "$TLD"; then
        echo "Error: Invalid TLD." >&2
        exit 1
    fi

    # 规范化域名
    DOMAIN=$(echo "$DOMAIN" | sed "s/.$TLD//" | sed 's/.*\.//g').$TLD

    # 从本地缓存读取服务器（兼容 Windows CRLF 和 Unix LF）
    if [[ -f "$WHOIS_WORKING_DIR/servers.list" ]]; then
        _line=$(grep "^${TLD}=" "$WHOIS_WORKING_DIR/servers.list" 2>/dev/null | tr -d '\r' || true)
        if [[ -n "$_line" ]]; then
            SERVER=${_line#*=}
            SERVER=$(echo "$SERVER" | tr -d '\r')
        else
            # 如果二级域名没有匹配，尝试回退到单级 TLD
            # 例如：org.sz -> sz
            FALLBACK_TLD=$(echo "$TLD" | sed 's/.*\.//')
            if [[ "$FALLBACK_TLD" != "$TLD" ]]; then
                _line=$(grep "^${FALLBACK_TLD}=" "$WHOIS_WORKING_DIR/servers.list" 2>/dev/null | tr -d '\r' || true)
                if [[ -n "$_line" ]]; then
                    SERVER=${_line#*=}
                    SERVER=$(echo "$SERVER" | tr -d '\r')
                fi
            fi
        fi
    fi

    # 检查是否为非法域名
    if [[ "$SERVER" == "illigle" ]]; then
        echo "Error: Domain is not supported or illegal." >&2
        exit 1
    fi

    # 检查是否为 URL 格式（需要网页访问的 whois 服务）
    # 改用 DNS 查询作为替代方案
    if [[ "$SERVER" == url:* ]]; then
        REG_URL="${SERVER#url:}"
        # 使用 DNS 查询并显示官方查询地址
        source "$WHOIS_WORKING_DIR/inc/dns.sh"
        __dns_query_with_url_hint "$DOMAIN" "$REG_URL"
        exit 0
    fi

    # 检查是否为 NS 格式（使用指定的 NS 服务器查询）
    if [[ "$SERVER" == ns:* ]]; then
        NS_SERVER="${SERVER#ns:}"
        # 使用指定的 NS 服务器进行 DNS 查询
        source "$WHOIS_WORKING_DIR/inc/dns.sh"
        __dns_query_via_ns "$DOMAIN" "$NS_SERVER"
        exit 0
    fi

    # 如果没有找到服务器，从 IANA 查询
    if [[ -z "$SERVER" ]]; then
        # 使用 URL 编码防止注入
        ENCODED_DOMAIN=$(__escape_url "$DOMAIN")
        RESULT=$(curl -s "https://www.iana.org/whois?q=${ENCODED_DOMAIN}")
        SERVER=$(echo "$RESULT" | grep "whois:" | sed 's#.* ##' | tr -d ' ')

        # 验证从 IANA 获取的服务器地址
        if [[ -n "$SERVER" ]] && __validate_hostname "$SERVER"; then
            # 安全地写入文件（验证路径）
            if __validate_filepath "$WHOIS_WORKING_DIR/servers.list"; then
                echo "${TLD}=${SERVER}" >> "$WHOIS_WORKING_DIR/servers.list" 2>/dev/null || true
            fi
        else
            SERVER=""
        fi
    fi

    # 尝试获取注册 URL
    REG_URL=$(echo "$RESULT" | grep remarks | grep http | sed 's#.* ##' | tr -d ' ')
fi

# 执行 whois 查询
if [[ -n "$SERVER" ]]; then
    # 检查是否为 RDAP 服务器
    if [[ "$SERVER" == rdap://* ]]; then
        # 使用 RDAP 查询
        "$WHOIS_WORKING_DIR/inc/rdap.sh" "$DOMAIN" "$SERVER"
        exit $?
    fi

    # 验证服务器地址
    if ! __validate_hostname "$SERVER"; then
        echo "Error: Invalid whois server address." >&2
        exit 1
    fi

    # 检查是否为 URL 模板
    if __contain_string "$SERVER" "%domain%"; then
        # 使用 URL 编码防止注入
        ENCODED_DOMAIN=$(__escape_url "$DOMAIN")
        CURL_URL=${SERVER//%domain%/${ENCODED_DOMAIN}}
        RESULT=$(curl -sSL "$CURL_URL")
    else
        # 验证端口号
        if ! __validate_port "$PORT"; then
            echo "Error: Invalid port number." >&2
            exit 1
        fi
        RESULT=$("$WHOIS_WORKING_DIR/inc/tcp.sh" -host "$SERVER" -port "$PORT" -data "$DOMAIN")
    fi
    echo "$RESULT"
else
    # 没有找到 whois 服务器
    if [[ -z "$REG_URL" ]]; then
        # 标记为非法域名
        if __validate_filepath "$WHOIS_WORKING_DIR/servers.list"; then
            echo "${TLD}=illigle" >> "$WHOIS_WORKING_DIR/servers.list" 2>/dev/null || true
        fi
        echo "Error: This domain TLD is not supported or illegal." >&2
    else
        echo -e "This TLD has no whois server, but you can access the whois database at:\n${REG_URL}"
    fi
fi
