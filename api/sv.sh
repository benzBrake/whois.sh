#!/usr/bin/env bash
# SV Domain Registry - https://svnet.sv/
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

# 提取域名关键字（去掉 .sv 后缀和二级后缀）
# 例如: google.com.sv -> google, test.sv -> test
KEYWORD=$(echo "$DOMAIN" | sed 's/\.com\.sv$//' | sed 's/\.org\.sv$//' | sed 's/\.edu\.sv$//' | sed 's/\.gob\.sv$//' | sed 's/\.sv$//')
if [[ -z "$KEYWORD" ]]; then
    echo "Error: Invalid domain format." >&2
    exit 1
fi

# 构建目标完整域名（用于匹配返回结果）
TARGET_DOMAIN="$DOMAIN"

# 第一步：查询域名状态，获取可能的域名 ID
STEP1_RESULT=$(curl -s \
    -X POST \
    -H 'User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:148.0) Gecko/20100101 Firefox/148.0' \
    -H 'Accept: */*' \
    -H 'Content-Type: application/x-www-form-urlencoded' \
    -H 'Origin: https://svnet.sv' \
    -H 'Connection: keep-alive' \
    -H 'Referer: https://svnet.sv/' \
    -d "key=Buscar" \
    -d "ID=1" \
    -d "nombre=${KEYWORD}" \
    "https://svnet.sv/accion/procesos.php")

# 从返回的 HTML 中查找目标域名
# 匹配格式: <strong>domain.sv</strong><button ... onClick="Whois(ID)">
# 提取域名 ID（注意 onClick 是大小写敏感的）
DOMAIN_ID=$(echo "$STEP1_RESULT" | grep -oE '<strong>'"${TARGET_DOMAIN}"'</strong>[^<]*<button[^>]*onClick="Whois\([0-9]+\)">' | grep -oE '[0-9]+' | head -1)

# 检查域名是否在 "Dominios Disponibles" (可用域名) 列表中
AVAILABLE_CHECK=$(echo "$STEP1_RESULT" | grep -o '<strong>'"${TARGET_DOMAIN}"'</strong>[^<]*<button[^>]*btn-success' | head -1)

if [[ -n "$AVAILABLE_CHECK" ]]; then
    # 域名可用
    echo "Status: available"
    exit 0
fi

if [[ -z "$DOMAIN_ID" ]]; then
    # 未找到域名 ID，可能域名不存在或查询失败
    echo "Status: unknown (domain not found in registry)"
    exit 0
fi

# 第二步：使用域名 ID 查询 whois 信息
STEP2_RESULT=$(curl -s \
    -X POST \
    -H 'User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:148.0) Gecko/20100101 Firefox/148.0' \
    -H 'Accept: */*' \
    -H 'Content-Type: application/x-www-form-urlencoded' \
    -H 'Origin: https://svnet.sv' \
    -H 'Connection: keep-alive' \
    -H 'Referer: https://svnet.sv/' \
    -d "key=Whois" \
    -d "ID=${DOMAIN_ID}" \
    "https://svnet.sv/accion/procesos.php")

# 移除 HTML 标签，格式化输出
echo "$STEP2_RESULT" | \
    sed 's/<br>/\n/g' | \
    sed 's/<[^>]*>//g' | \
    sed 's/&nbsp;/ /g' | \
    sed 's/&amp;/\&/g' | \
    sed 's/&lt;/</g' | \
    sed 's/&gt;/>/g' | \
    sed '/^[[:space:]]*$/d' | \
    sed 's/^[[:space:]]\+//' | \
    sed 's/[[:space:]]\+$//'
