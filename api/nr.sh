#!/usr/bin/env bash
# 设置工作目录
WHOIS_WORKING_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/.."
source "$WHOIS_WORKING_DIR/inc/functions.sh"
source "$WHOIS_WORKING_DIR/inc/dns.sh"

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

# 解析域名
# 支持: .nr, .net.nr, .biz.nr, .info.nr, .org.nr, .com.nr
TLD="${DOMAIN##*.}"
if [[ "$TLD" != "nr" ]]; then
    echo "Error: This script only supports .nr domains." >&2
    exit 1
fi

# 移除 .nr 后缀，使用 bash 参数扩展
REMAINING="${DOMAIN%.nr}"

# 检查是否有二级后缀
SLD=""
DOMAIN_NAME=""
if [[ "$REMAINING" == *.* ]]; then
    # 有二级后缀，提取 SLD 和域名
    SLD="${REMAINING##*.}"
    DOMAIN_NAME="${REMAINING%.*}"
    # 验证 SLD 是否为支持的类型
    if [[ "$SLD" != "net" && "$SLD" != "biz" && "$SLD" != "info" && "$SLD" != "org" && "$SLD" != "com" ]]; then
        echo "Error: Unsupported second-level domain '.$SLD.nr'. Supported: .nr, .net.nr, .biz.nr, .info.nr, .org.nr, .com.nr" >&2
        exit 1
    fi
    TLD_PARAM="${SLD}.nr"
else
    # 没有二级后缀
    DOMAIN_NAME="$REMAINING"
    TLD_PARAM="nr"
fi

# 域名只包含字母数字和连字符，不需要 URL 编码
ENCODED_DOMAIN="$DOMAIN_NAME"

# 查询 .nr whois 接口
RESULT=$(curl -s "https://www.cenpac.net.nr/dns/whois.html?subdomain=${ENCODED_DOMAIN}&tld=${TLD_PARAM}&whois=Submit" \
    -H 'User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36' \
    -H 'Accept-Language: en-US,en;q=0.9' \
    -H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8')

# 检查是否包含域名信息
if echo "$RESULT" | grep -q "Domain Name:"; then
    echo "# Domain Information for: $DOMAIN"
    echo "# Source: https://www.cenpac.net.nr/dns/whois.html"
    echo ""

    # 解析 HTML 表格提取域名信息
    # 标签和值在不同行，需要特殊处理
    echo "$RESULT" | sed 's/<td[^>]*>/\n/g' | \
        sed 's/<\/td>/\n/g' | \
        sed 's/<[^>]*>//g' | \
        sed 's/&nbsp;/ /g' | \
        sed 's/^[[:space:]]*//; s/[[:space:]]*$//' | \
        awk -v domain="$DOMAIN" '
        BEGIN {
            current_label = ""
            skip_empty = 0
            in_section = "main"
        }

        /Domain Name:/ && current_label == "" {
            print "Domain Name: " domain
            skip_empty = 1
            next
        }

        /Organisation:/ {
            current_label = "org"
            skip_empty = 1
            next
        }

        /Address:/ {
            if (current_label != "addr") {
                current_label = "addr"
                addr_count = 0
            }
            skip_empty = 1
            next
        }

        /City:/ {
            current_label = "city"
            skip_empty = 1
            next
        }

        /Country:/ {
            current_label = "country"
            skip_empty = 1
            next
        }

        /ZIP:/ {
            current_label = ""
            skip_empty = 1
            next
        }

        /Phone:/ {
            current_label = "phone"
            skip_empty = 1
            next
        }

        /Fax:/ {
            current_label = "fax"
            skip_empty = 1
            next
        }

        /Handle:/ {
            current_label = "handle"
            skip_empty = 1
            next
        }

        /First Name:/ {
            current_label = "fname"
            skip_empty = 1
            next
        }

        /Last Name:/ {
            current_label = "lname"
            skip_empty = 1
            next
        }

        /Title:/ {
            current_label = "title"
            skip_empty = 1
            next
        }

        /Email:/ {
            current_label = "email"
            skip_empty = 1
            next
        }

        /Administrative Contact/ {
            print "\n# Administrative Contact"
            current_label = ""
            skip_empty = 1
            next
        }

        /Technical Contact/ {
            print "\n# Technical Contact"
            current_label = ""
            skip_empty = 1
            next
        }

        /Billing Details/ {
            print "\n# Billing Details"
            current_label = ""
            skip_empty = 1
            next
        }

        /Registration/ && !/Registration Date:/ {
            print "\n# Registration"
            current_label = ""
            skip_empty = 1
            next
        }

        /Registration Date:/ {
            current_label = "created"
            skip_empty = 1
            next
        }

        /Start Domain:/ {
            current_label = ""
            skip_empty = 1
            next
        }

        /Expiration:/ {
            current_label = "expires"
            skip_empty = 1
            next
        }

        /Record Modification/ {
            current_label = ""
            skip_empty = 1
            next
        }

        /Modifier/ {
            current_label = ""
            skip_empty = 1
            next
        }

        {
            # 处理值
            line = $0
            gsub(/^[[:space:]]+|[[:space:]]+$/, "", line)

            # 跳过空行和特殊值
            if (line == "" || line == "NR" || line == "modify" || line == "Submit") {
                if (skip_empty) {
                    next
                }
            }

            # 处理当前标签的值
            if (current_label == "org" && line != "" && line != "NR") {
                print "Organisation: " line
                current_label = ""
            } else if (current_label == "addr" && line != "" && line != "NR") {
                if (addr_count == 0) {
                    print "Address: " line
                    addr_count++
                } else if (line != "") {
                    print "         " line
                }
            } else if (current_label == "city" && line != "") {
                print "City: " line
                current_label = ""
            } else if (current_label == "country" && line != "") {
                print "Country: " line
                current_label = ""
            } else if (current_label == "phone" && line != "") {
                print "Phone: " line
                current_label = ""
            } else if (current_label == "fax" && line != "") {
                print "Fax: " line
                current_label = ""
            } else if (current_label == "handle" && line != "") {
                gsub(/ *\(modify\)/, "", line)
                if (line != "") {
                    print "Handle: " line
                }
                current_label = ""
            } else if (current_label == "fname" && line != "") {
                printf "Name: %s", line
            } else if (current_label == "lname" && line != "") {
                print " " line
                current_label = ""
            } else if (current_label == "title" && line != "") {
                print "Name: " line
                current_label = ""
            } else if (current_label == "email" && line != "") {
                print "Email: " line
                current_label = ""
            } else if (current_label == "created" && line != "") {
                print "Created: " line
                current_label = ""
            } else if (current_label == "expires" && line != "") {
                print "Expires: " line
                current_label = ""
            }

            skip_empty = 0
        }
        ' | head -50

    echo ""
    __dns_query_ns_simple "$DOMAIN"
else
    # 没有查询到 whois 信息
    echo "# ========================================"
    echo "# No whois information found for $DOMAIN"
    echo "# Possible reasons:"
    echo "#   1. Domain is available for registration"
    echo "#   2. Domain information is hidden/protected"
    echo "#   3. The registry website may be unavailable"
    echo "# Please verify at: https://www.cenpac.net.nr/dns/whois.html"
    echo "# ========================================"
    echo ""

    __dns_query_ns_smart "$DOMAIN"
fi
