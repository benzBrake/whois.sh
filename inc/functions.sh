#!/usr/bin/env bash

# output help info
__help_info() {
    cat <<EOF
Usage: $(basename $0) [OPTION[=PATTERN]]
whois.sh | whois client written by shell.
Different OPTION has different PATTERN.
Example: $(basename $0) -i doufu.ru
Example: $(basename $0) doufu.ru
OPTIONs and PATTERNs
  -i,-I,-iana,-IANA    get whois infomation from iana
  -h,-H,-host          specify whois server
  -p,-P,-port          specify whois port
Report bugs to github-benzBrake@woai.ru
EOF
}

# trim string
__prep() {
	echo "$1" | sed -e 's/^ *//g' -e 's/ *$//g' | sed -n '1 p'
}

# get tld from domain
function __get_tld() {
	_tld="$(__prep "$@")"
	while :; do echo > /dev/null
		_dc="$(echo $_tld | tr -cd "." | wc -c)"
		if [ $_dc -le 2 ]; then
			break
		fi
		_tld="$(echo $_tld | perl -pe 's/^(.*?\.){1}//')"
	done
	_tlda="$(echo $_tld | perl -pe 's/^(.*?\.){1}//')"
	_tldb="$(echo $_tld | sed 's#.*\.##')"
	if [[ "$_tlda" == "$_tldb" ]]; then
		echo "$_tldb"
	else
		echo "$_tlda"
	fi
}

# detect if string contain {{domain}}
__contain_string() {
    [ -n "$(echo "$1" | grep "$2")" ]
    return $?
}

# ============ 安全验证函数 ============

# 验证域名格式（防止命令注入）
__validate_domain() {
    local domain="$1"
    [[ "$domain" =~ ^[a-zA-Z0-9.-]+$ ]] || return 1
    [[ "$domain" =~ \.\. ]] && return 1
    [[ "$domain" =~ ^\. ]] && return 1
    [[ "$domain" =~ \.$ ]] && return 1
    return 0
}

# 验证 IP 地址格式（IPv4）
__validate_ip() {
    local ip="$1"
    [[ "$ip" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]] || return 1
    return 0
}

# 验证端口号

# 验证 IPv6 地址格式
__validate_ipv6() {
    local ip="$1"
    # 简化的 IPv6 验证：检查是否包含冒号且符合基本格式
    [[ "$ip" =~ : ]] || return 1
    # 检查是否只包含合法的 IPv6 字符（0-9, a-f, A-F, :）
    [[ "$ip" =~ ^[0-9a-fA-F:]+$ ]] || return 1
    # 排除连续的冒号（除非是 :: 缩写）
    local consecutive_colons=$(echo "$ip" | grep -o '::' | wc -l)
    if [[ $consecutive_colons -gt 1 ]]; then
        return 1
    fi
    # 排除 ::: 或更多连续冒号
    [[ "$ip" =~ :::: ]] && return 1
    return 0
}
__validate_port() {
    local port="$1"
    [[ "$port" =~ ^[0-9]+$ ]] || return 1
    [[ "$port" -ge 1 && "$port" -le 65535 ]] || return 1
    return 0
}

# 验证主机名（whois 服务器）
__validate_hostname() {
    local hostname="$1"
    [[ "$hostname" =~ ^[a-zA-Z0-9.-]+$ ]] || return 1
    [[ "$hostname" =~ \.\. ]] && return 1
    [[ "$hostname" =~ ^\. ]] && return 1
    [[ "$hostname" =~ \.$ ]] && return 1
    return 0
}

# 安全转义字符串用于 URL
__escape_url() {
    local string="$1"
    printf '%s' "$string" | perl -MURI::Escape -ne 'print uri_escape($_)' 2>/dev/null || \
    printf '%s' "$string" | sed 's/[^a-zA-Z0-9._-]/%&/g' | sed 's/% /+/g'
}

# 验证文件路径安全（防止路径遍历）
# 支持合法的相对路径（如 inc/../servers.list），但防止遍历到项目根目录之外
__validate_filepath() {
    local filepath="$1"

    # 如果路径不包含 ..，直接通过
    if [[ ! "$filepath" =~ \.\. ]]; then
        return 0
    fi

    # 获取项目根目录（从脚本位置推断）
    local script_dir
    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/.."

    # 尝试规范化路径（使用 realpath 或 readlink -f）
    local normalized_path
    if command -v realpath &>/dev/null; then
        normalized_path="$(realpath -m "$filepath" 2>/dev/null)" || normalized_path="$filepath"
    elif command -v readlink &>/dev/null; then
        normalized_path="$(readlink -f "$filepath" 2>/dev/null)" || normalized_path="$filepath"
    else
        # 备选方案：确保路径不会遍历到根目录之外
        # 计算路径中 .. 的数量，确保不会超出项目根目录
        local dot_dot_count
        dot_dot_count="$(grep -o '\.\.' <<< "$filepath" | wc -l)"
        local dir_count
        dir_count="$(tr -cd '/' <<< "$filepath" | wc -c)"

        # 如果 .. 的数量小于或等于目录层数，则是安全的
        [[ "$dot_dot_count" -le "$dir_count" ]] && return 0
    fi

    # 检查规范化后的路径是否以项目根目录开头
    local real_root
    real_root="$(cd "$script_dir" && pwd)"
    [[ "$normalized_path" == "$real_root"* ]] && return 0

    return 1
}

# ============ RDAP 查询函数 ============

# RDAP 查询
__rdap_query() {
    local domain="$1"
    local server="${2:-}"
    local encoded_domain=$(__escape_url "$domain")

    if [[ -n "$server" ]]; then
        __curl_get "${server}domain/${encoded_domain}"
    else
        return 1
    fi
}

# 从 JSON 中提取字段值（不依赖 jq）
__json_value() {
    local json="$1"
    local key="$2"
    # 匹配键值对，避免匹配嵌套对象中的同名键（使用逗号或大括号作为分隔符）
    echo "$json" | grep -oE "[,{]\s*\"${key}\"[[:space:]]*:[[:space:]]*\"[^\"]*\"" | \
        sed 's/.*"'"${key}"'"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/' | head -1
}

# 从 JSON 中提取对象数组中的特定字段
__json_array_values() {
    local json="$1"
    local key="$2"
    local subkey="${3:-}"

    if [[ -n "$subkey" ]]; then
        echo "$json" | grep -o "\"${key}\"[[:space:]]*:[[:space:]]*\[[^]]*\]" | \
            sed 's/.*\[\(.*\)\].*/\1/' | grep -o '{[^}]*}' | \
            grep "\"${subkey}\"" | sed 's/.*"'${subkey}'"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/'
    else
        echo "$json" | grep -o "\"${key}\"[[:space:]]*:[[:space:]]*\[[^]]*\]" | \
            sed 's/.*\[\(.*\)\].*/\1/' | grep -o '"[^"]*"' | tr -d '"'
    fi
}

# 解析 RDAP JSON 响应为 whois 格式
__rdap_parse() {
    local json="$1"

    # 检查 jq 是否可用
    if command -v jq &>/dev/null; then
        # 使用 jq 解析并格式化输出
        echo "$json" | jq -r '
            # 基本信息
            if .ldhName then "DOMAIN: \(.ldhName)" else empty end,
            if .handle then "Registry ID: \(.handle)" else empty end,

            # 状态
            if .status then "Status: \([.status[] | tostring] | join(", "))" else empty end,

            # 事件时间
            (.events[]? | select(.eventAction == "registration") | "Created: \(.eventDate)"),
            (.events[]? | select(.eventAction == "last changed") | "Updated: \(.eventDate)"),
            (.events[]? | select(.eventAction == "expiration") | "Expires: \(.eventDate)"),

            # 名称服务器
            if .nameservers then "Nameservers:",
                (.nameservers[]? | "  \(.ldhName)")
            else empty end
        ' | grep -v '^$'
    else
        # jq 不可用时的降级处理：使用简单解析并显示原始 JSON
        local domain=$(__json_value "$json" "ldhName")
        local handle=$(__json_value "$json" "handle")

        [[ -n "$domain" ]] && echo "DOMAIN: $domain"
        [[ -n "$handle" ]] && echo "Registry ID: $handle"

        # 提取状态（简单方法）
        local statuses=$(echo "$json" | grep -o '"status"[[:space:]]*:[[:space:]]*\[[^]]*\]' | head -1 | sed 's/.*\[\(.*\)\].*/\1/' | tr -d '"' | tr ',' ', ')
        [[ -n "$statuses" ]] && echo "Status: $statuses"

        # 提取名称服务器
        local nameservers=$(echo "$json" | grep -o '"ldhName"[[:space:]]*:[[:space:]]*"[^"]*"' | grep -v '"ldhName"[[:space:]]*:[[:space:]]*"'$domain'"' | sed 's/.*"ldhName"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/' | head -5)
        if [[ -n "$nameservers" ]]; then
            echo "Nameservers:"
            echo "$nameservers" | while read -r ns; do
                [[ -n "$ns" ]] && echo "  $ns"
            done
        fi

        # 提示安装 jq 以获得更好的输出
        echo "" >&2
        echo "Note: Install 'jq' for formatted RDAP output." >&2
    fi
}
# 查找 API 脚本，支持多级后缀（如 .asso.st, .fr.nf）
# 优先尝试完整后缀，然后回退到单级 TLD
__find_api_script() {
    local domain="$1"
    local api_dir="$2"

    # 获取域名后缀部分（移除第一个部分）
    local suffix=$(echo "$domain" | sed 's/^[^.]*\.//')

    # 先尝试完整后缀（如 asso.st, fr.nf）
    if [[ -f "${api_dir}/${suffix}.sh" ]]; then
        echo "${suffix}.sh"
        return 0
    fi

    # 回退到单级 TLD（如 st, nf）
    local tld=$(__get_tld "$domain")
    if [[ -f "${api_dir}/${tld}.sh" ]]; then
        echo "${tld}.sh"
        return 0
    fi

    return 1
}
