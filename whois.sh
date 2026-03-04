#!/usr/bin/env bash
# Load functions
test -z "$WHOIS_WORKING_DIR" && WHOIS_WORKING_DIR=$(dirname "$0")
source "$WHOIS_WORKING_DIR/inc/functions.sh"

# 安全的参数解析（移除危险的 eval）
while [[ $# -gt 0 && $1 =~ ^- ]]; do
    key="$1"
    case "$key" in
        -h|-H|-host|--host)
            SERVER="$2"
            shift 2
            ;;
        -p|-P|-port|--port)
            PORT="$2"
            shift 2
            ;;
        -i|-I|-iana|--iana)
            IANA="$2"
            shift 2
            ;;
        *)
            echo "Unknown option: $1" >&2
            __help_info
            exit 1
            ;;
    esac
done

# 剩余参数作为域名
DOMAIN="$*"

# 设置默认值
PORT="${PORT:-43}"

# 处理 IANA 查询
if [[ -n "$IANA" ]]; then
    SERVER="whois.iana.org"
    DOMAIN="$IANA"
fi

# 验证必需参数
if [[ -z "$DOMAIN" ]]; then
    echo "Error: No domain specified." >&2
    echo "====================================="
    __help_info
    exit 1
fi

# 提取 TLD
TLD=$(echo "$DOMAIN" | sed 's#.*\.##')

# 域名格式验证
if [[ $(echo "$DOMAIN" | grep -v ":") ]] && [[ "$TLD" == "$DOMAIN" ]]; then
    echo "Error: Invalid domain format." >&2
    exit 1
fi

# 验证域名安全性（防止命令注入）
if ! __validate_domain "$DOMAIN"; then
    echo "Error: Invalid domain format or potentially dangerous input." >&2
    exit 1
fi

# 验证服务器名称（如果提供）
if [[ -n "$SERVER" ]] && ! __validate_hostname "$SERVER"; then
    echo "Error: Invalid server hostname." >&2
    exit 1
fi

# 验证端口号（如果提供）
if ! __validate_port "$PORT"; then
    echo "Error: Invalid port number. Port must be between 1 and 65535." >&2
    exit 1
fi

# Extract and prepare IPv4, IPv6, and DOMAIN in a more efficient way
IPV4=$(__prep "$(grep -oE '[0-9]{1,3}(\.[0-9]{1,3}){3}' <<< "$DOMAIN")")
IPV6=$(__prep "$(grep -oE '([0-9a-fA-F]{0,4}:){1,7}([0-9a-fA-F]{0,4})' <<< "$DOMAIN")")
DOMAIN=$(__prep "$DOMAIN")
__WHOIS_BIN="$WHOIS_WORKING_DIR/inc/getwhois.sh"

if [[ -n "$DOMAIN" ]]; then
    if [[ "$IPV4" == "$DOMAIN" ]]; then
        # IP 地址查询
        "$WHOIS_WORKING_DIR/inc/ip.sh" "$DOMAIN"
    elif [[ "$IPV6" == "$DOMAIN" ]]; then
        echo "IPv6 support is unavailable."
    else
        # 域名查询
        if [[ -z "$SERVER" ]]; then
            # 使用内置 whois 顺序
            TLD=$(__get_tld "$DOMAIN")
            if [[ -f "${WHOIS_WORKING_DIR}/api/${TLD}.sh" ]]; then
                # 优先使用 API
                RESULT=$("${WHOIS_WORKING_DIR}/api/${TLD}.sh" "$DOMAIN")
            else
                # 使用标准 whois 查询
                RESULT=$("$__WHOIS_BIN" "$DOMAIN")
                # .com whois hack - 使用更安全的方式
                if echo "$RESULT" | grep -qi 'with "xxx"'; then
                    RESULT=$("$__WHOIS_BIN" "domain $DOMAIN")
                fi
            fi
        else
            # 指定 whois 服务器 - 使用安全的参数传递
            RESULT=$("$__WHOIS_BIN" -h "$SERVER" -p "$PORT" "$DOMAIN")
            echo "$RESULT"
        fi
    fi
    # 只有在非自定义服务器的情况下才输出 RESULT
    if [[ -z "$SERVER" ]]; then
        echo "$RESULT"
    fi
fi
