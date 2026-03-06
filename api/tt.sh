#!/usr/bin/env bash
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

# 使用 URL 编码防止注入
ENCODED_DOMAIN=$(__escape_url "$DOMAIN")
RESULT=$(__curl_post "https://www.nic.tt/cgi-bin/search.pl" "name=${ENCODED_DOMAIN}" | grep '<tr><td>Domain Name</td>' | sed 's#</td></tr> <tr><td>#\n#g;s#</td> <td>#:#g;s#<[^<>]*>##g;s#&nbsp##g')
echo "$RESULT"
