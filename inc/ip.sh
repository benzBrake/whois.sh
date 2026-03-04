#!/usr/bin/env bash
# 获取脚本所在目录的绝对路径
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/functions.sh"
# 获取域名/IP参数
DOMAIN="$*"

# 验证参数
if [[ -z "$DOMAIN" ]]; then
    echo "Error: No IP address specified." >&2
    exit 1
fi

# 验证 IP 地址格式
if ! __validate_ip "$DOMAIN" 2>/dev/null; then
    echo "Error: Invalid IP address format." >&2
    exit 1
fi

# 获取项目根目录（脚本所在目录的父目录）
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# 从 IANA 查询 whois 服务器（安全的方式）
RESULT=$("$SCRIPT_DIR/tcp.sh" -host "whois.iana.org" -port "43" -data "$DOMAIN")

# 提取 IP 前缀
PREFIX=$(echo "$DOMAIN" | sed 's#\..*##')

# 确保缓存文件存在
if [[ ! -e "${PROJECT_ROOT}/prefix.list" ]]; then
    touch "${PROJECT_ROOT}/prefix.list" 2>/dev/null || true
fi

# 从缓存读取处理器
HANDLER=""
if [[ -f "${PROJECT_ROOT}/prefix.list" ]]; then
    HANDLER=$(grep "PREFIX${PREFIX}=" "${PROJECT_ROOT}/prefix.list" 2>/dev/null | sed "s#^.*=##" || echo "")
fi

# 如果没有缓存，从结果中提取
if [[ -z "$HANDLER" ]]; then
    HANDLER=$(echo -e "$RESULT" | grep 'whois:' | sed 's#^[^ ]* *##' | tr -d ' ')

    if [[ -z "$HANDLER" ]]; then
        echo "Error: This IP address is not supported." >&2
        exit 1
    fi

    # ARIN 的特殊处理
    if [[ "$HANDLER" == "whois.arin.net" ]]; then
        HANDLER="whois.apnic.net"
    fi

    # 安全地写入缓存
    if __validate_filepath "${PROJECT_ROOT}/prefix.list" 2>/dev/null; then
        echo "PREFIX${PREFIX}=${HANDLER}" >> "${PROJECT_ROOT}/prefix.list" 2>/dev/null || true
    fi
fi

# 使用安全的参数传递调用 tcp.sh
RESULT=$("$SCRIPT_DIR/tcp.sh" -host "$HANDLER" -port "43" -data "$DOMAIN")
echo -e "$RESULT"
