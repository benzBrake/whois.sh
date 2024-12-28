#!/usr/bin/env bash
# shellcheck source=functions.sh
source "$WHOIS_WORKING_DIR/inc/functions.sh"

while [[ $1 =~ ^- ]]; do
    declare "${1#-}=$2"
    shift 2
done

PORT=43
SERVER=${host:-${h:-}}
PORT=${port:-${p:-$PORT}}
DOMAIN=$@

[[ -z "$DOMAIN" ]] && { echo "Arguments Error."; exit 1; }

if [[ -z "$SERVER" ]]; then
    TLD=$(__get_tld "$DOMAIN")
	DOMAIN=$(echo "$DOMAIN" | sed "s/.$TLD//" | sed 's/.*\.//g').$TLD
    if [[ -f "$WHOIS_WORKING_DIR/servers.list" ]]; then
		_line=$(grep "^$TLD=" "$WHOIS_WORKING_DIR/servers.list")
        [[ -n "$_line" ]] && SERVER=${_line#*=}
		fi
	if [[ "$SERVER" == "illigle" ]]; then
		echo "Domain is illigle."
		exit 1
	fi

    if [[ -z "$SERVER" ]]; then
		RESULT=$(curl -s "https://www.iana.org/whois?q=$DOMAIN")
		SERVER=$(echo "$RESULT" | grep "whois:" | sed 's#.* ##')
        [[ -n "$SERVER" ]] && echo "$TLD=$SERVER" >> "$WHOIS_WORKING_DIR/servers.list"
	fi

    REG_URL=$(echo "$RESULT" | grep remarks | grep http | sed 's#.* ##')
fi

if [[ -n "$SERVER" ]]; then
	if __contain_string "$SERVER" "%domain%"; then
        CURL_URL=${SERVER//%domain%/$DOMAIN}
        RESULT=$(curl -sSL "$CURL_URL")
    else
        RESULT=$("$WHOIS_WORKING_DIR/inc/tcp.sh" -host "$SERVER" -port "$PORT" -data "$DOMAIN")
    fi
    echo "$RESULT"
else
    if [[ -z "$REG_URL" ]]; then
        echo "$TLD=illigle" >> "$WHOIS_WORKING_DIR/servers.list"
        echo "Domain is illigle."
    else
        echo -e "This TLD has no whois server, but you can access the whois database at\n$REG_URL"
    fi
fi