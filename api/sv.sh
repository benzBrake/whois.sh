#!/usr/bin/env bash
# SV Domain Registry - https://svnet.sv/
# 设置工作目录
WHOIS_WORKING_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/.."
source "$WHOIS_WORKING_DIR/inc/functions.sh"
source "$WHOIS_WORKING_DIR/inc/curl.sh"

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
STEP1_RESULT=$(__curl_post "https://svnet.sv/accion/procesos.php" "key=Buscar&ID=1&nombre=${KEYWORD}")

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

# 检查是否为保留域名
RESERVED_CHECK=$(echo "$STEP1_RESULT" | grep -i "es reservado por SVNet")
if [[ -n "$RESERVED_CHECK" ]]; then
    # 提取保留信息并清理格式
    RESERVED_MSG=$(echo "$STEP1_RESULT" | grep -oP 'Este nombre de dominio:.*?es reservado[^<]*' | sed 's/<[^>]*>//g; s/[[:space:]]\+/ /g; s/^[[:space:]]//; s/[[:space:]]$//')
    if [[ -n "$RESERVED_MSG" ]]; then
        html_entity_decode() {
            local text="$1"
            text=$(echo "$text" | sed 's/&aacute;/á/g; s/&eacute;/é/g; s/&iacute;/í/g; s/&oacute;/ó/g; s/&uacute;/ú/g')
            text=$(echo "$text" | sed 's/&ntilde;/ñ/g; s/&Ntilde;/Ñ/g')
            text=$(echo "$text" | sed 's/&amp;/\&/g')
            echo "$text"
        }
        echo "$(html_entity_decode "$RESERVED_MSG")"
    else
        echo "Status: reserved (domain name is reserved by SVNet)"
    fi
    exit 0
fi

if [[ -z "$DOMAIN_ID" ]]; then
    # 未找到域名 ID，可能域名不存在或查询失败
    echo "Status: unknown (domain not found in registry)"
    exit 0
fi

# 第二步：使用域名 ID 查询 whois 信息
STEP2_RESULT=$(__curl_post "https://svnet.sv/accion/procesos.php" "key=Whois&ID=${DOMAIN_ID}")

# HTML 实体解码函数
html_entity_decode() {
    local text="$1"
    # 常见的 HTML 实体字符
    text=$(echo "$text" | sed 's/&aacute;/á/g; s/&eacute;/é/g; s/&iacute;/í/g; s/&oacute;/ó/g; s/&uacute;/ú/g')
    text=$(echo "$text" | sed 's/&Aacute;/Á/g; s/&Eacute;/É/g; s/&Iacute;/Í/g; s/&Oacute;/Ó/g; s/&Uacute;/Ú/g')
    text=$(echo "$text" | sed 's/&ntilde;/ñ/g; s/&Ntilde;/Ñ/g')
    text=$(echo "$text" | sed 's/&uuml;/ü/g; s/&Uuml;/Ü/g')
    text=$(echo "$text" | sed 's/&amp;/\&/g; s/&lt;/</g; s/&gt;/>/g; s/&quot;/"/g; s/&nbsp;/ /g')
    echo "$text"
}

# 解析 HTML 表格并格式化输出
# HTML 结构: <tr><td>Label:</td><td>Value</td></tr>
parse_whois_html() {
    local html="$1"

    # 提取状态信息（在表格之前）
    local status=$(echo "$html" | grep -oP 'se encuentra <h4>.*?<span class="badge[^>]*>\K[^<]+' | head -1)
    if [[ -n "$status" ]]; then
        echo "Estado: $(html_entity_decode "$status")"
        echo
    fi

    # 提取表格中的每一行
    echo "$html" | grep -oP '<tr[^>]*>.*?</tr>' | while read -r tr; do
        # 提取第一个 td（标签）
        local label=$(echo "$tr" | grep -oP '<td[^>]*>.*?</td>' | head -1 | sed 's/<[^>]*>//g; s/&nbsp;/ /g; s/^[[:space:]]\+//; s/[[:space:]]\+$//')
        # 提取第二个 td（值）
        local value=$(echo "$tr" | grep -oP '<td[^>]*>.*?</td>' | tail -1 | sed 's/<[^>]*>//g; s/&nbsp;/ /g; s/^[[:space:]]\+//; s/[[:space:]]\+$//')

        if [[ -n "$label" && -n "$value" ]]; then
            # 移除标签末尾的冒号（如果有）
            label=$(echo "$label" | sed 's/:$//')
            # 解码 HTML 实体
            label=$(html_entity_decode "$label")
            value=$(html_entity_decode "$value")
            # 输出格式化的字段
            echo "$label: $value"
        fi
    done
}

# 解析并输出 whois 信息
parse_whois_html "$STEP2_RESULT"
