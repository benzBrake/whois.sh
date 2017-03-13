#!/usr/bin/env bash
DOMAIN=$1
test -z "$DOMAIN" && { echo "Arguments Error."; exit 1;}
if [ -f servers.list ]; then
	. servers.list
fi
TLD=$(echo $DOMAIN | sed 's#.*\.##')
if [ -f "$WHOIS_WORKING_DIR/servers.list" ]; then
	. "$WHOIS_WORKING_DIR/servers.list"
fi
SERVER=$(eval echo '$'$TLD)
test -z "$SERVER" && {
	RESULT=$(curl -s "https://www.iana.org/whois?q=$DOMAIN")
	SERVER=$(echo "$RESULT" | grep "whois:" | sed 's#.* ##')
	echo "$TLD=$SERVER" >> "$WHOIS_WORKING_DIR/servers.list"
}
REG_URL=$(echo "$RESULT" | grep remarks | grep http | sed 's#.* ##')
if [ -z "$SERVER" ]; then
	echo "This TLD has no whois server."
	! test -z "$REG_URL" && { echo "You can look through more infomation at $REG_URL"; }
else
	exec 99<>/dev/tcp/"$SERVER"/43
	echo -e "$DOMAIN\r\n">&99
	cat <&99
	exec 99<&-
	exec 99>&-
fi