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

TLD=$(echo "$DOMAIN" | sed 's#.*\.##')
if [[ -z "$TLD" ]]; then
    echo "Error: Invalid domain format." >&2
    exit 1
fi

SLD=$(echo "$DOMAIN" | sed "s#.${TLD}##" | sed 's#.*\.##')
SDM=$(echo "$DOMAIN" | sed "s#${SLD}.${TLD}##" | sed 's#\..*##')

SERVER=""
if [[ -n "$SDM" ]]; then
    # CentralNic SLDs
    if [[ "$SLD" == "br" || "$SLD" == "cn" || "$SLD" == "co" || "$SLD" == "de" || "$SLD" == "eu" || "$SLD" == "gr" || "$SLD" == "jpn" || "$SLD" == "mex" || "$SLD" == "ru" || "$SLD" == "sa" || "$SLD" == "uk" || "$SLD" == "us" || "$SLD" == "za" ]]; then
        SERVER="whois.centralnic.com"
    else
        echo "Error: This sub-domain is not supported." >&2
        exit 1
    fi
else
    # 从 Verisign 获取注册商 WHOIS 服务器
    RESULTS=$("$WHOIS_WORKING_DIR/inc/tcp.sh" -host whois.verisign-grs.com -port 43 -data "$DOMAIN")
    SERVER=$(echo -e "$RESULTS" | grep "Registrar WHOIS Server" | awk '{print $4}' | sed "s#\r##g")
    if [[ -z "$SERVER" ]]; then
        echo -e "$RESULTS"
        exit 0
    fi
fi

# 验证服务器地址
if ! __validate_hostname "$SERVER"; then
    echo "Error: Invalid whois server address." >&2
    exit 1
fi

# 查询最终结果
"$WHOIS_WORKING_DIR/inc/tcp.sh" -host "$SERVER" -port 43 -data "$DOMAIN"
