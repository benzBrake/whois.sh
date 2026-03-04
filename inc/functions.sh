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
    echo "$string" | perl -MURI::Escape -ne 'print uri_escape($_)' 2>/dev/null || \
    echo "$string" | sed 's/[^a-zA-Z0-9._-]/%&/g' | sed 's/% /+/g'
}

# 验证文件路径安全（防止路径遍历）
__validate_filepath() {
    local filepath="$1"
    [[ "$filepath" =~ \.\. ]] && return 1
    return 0
}