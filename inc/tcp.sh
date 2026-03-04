#!/usr/bin/env bash
source "$(dirname "${BASH_SOURCE[0]}")/functions.sh"
# 安全的参数解析
while [[ $# -gt 0 && $1 =~ ^- ]]; do
    key="$1"
    case "$key" in
        -host|--host)
            HOST="$2"
            shift 2
            ;;
        -port|--port)
            PORT="$2"
            shift 2
            ;;
        -data|--data)
            DATA="$2"
            shift 2
            ;;
        *)
            shift
            ;;
    esac
done

# 验证必需参数
if [[ -z "$HOST" || -z "$PORT" || -z "$DATA" ]]; then
    exit 1
fi

# 验证主机名
if ! __validate_hostname "$HOST" 2>/dev/null; then
    exit 1
fi

# 验证端口号
if ! __validate_port "$PORT" 2>/dev/null; then
    exit 1
fi

# 验证数据（域名、IPv4 或 IPv6）
if ! __validate_domain "$DATA" 2>/dev/null; then
    # 允许 IP 地址
    if ! __validate_ip "$DATA" 2>/dev/null; then
        # 允许 IPv6 地址
        if ! __validate_ipv6 "$DATA" 2>/dev/null; then
            exit 1
        fi
    fi
fi

# 安全的 TCP 连接
while :; do
    ID=$((RANDOM % (1023 - 9 + 1) + 9))
    # 使用安全的变量引用
    if exec {ID}<>/dev/tcp/"$HOST"/"$PORT" 2>/dev/null; then
        echo -e "${DATA}\r\n" >&"$ID"
        cat <&"$ID"
        exec {ID}<&-
        exec {ID}>&-
    fi
    break
done
