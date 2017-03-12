#!/usr/bin/env bash
DOMAIN=$1
test -z "$DOMAIN" && { echo "Arguments Error."; exit 1;}
RESULT=$(curl -s "https://www.iana.org/whois?q=$DOMAIN")
REG_URL=$(echo "$RESULT" | grep remarks | grep http | sed 's#.* ##')
SERVER=$(echo "$RESULT" | grep "whois:" | sed 's#.* ##')
if [ -z "$SERVER" ]; then
	echo -e "This TLD has no whois server.\nYou can look through more infomation at $REG_URL"
else
	exec 99<>/dev/tcp/"$SERVER"/43
	echo -e "$DOMAIN\r\n">&99
	cat <&99
	exec 99<&-
	exec 99>&-
fi