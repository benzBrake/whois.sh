#!/usr/bin/env bash
ARGUMENT="$1"
test -z "$WHOIS_WORKING_DIR" && WHOIS_WORKING_DIR=$(dirname "$0")
test -z "$ARGUMENT" && { echo "Arguments Error."; exit 1;}
function prep ()
{
	echo "$1" | sed -e 's/^ *//g' -e 's/ *$//g' | sed -n '1 p'
}
IP=$(prep "$(echo "$ARGUMENT" | egrep -o '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}')")
DOMAIN=$(echo "$ARGUMENT" | sed 's#.*http.*//##;s#/.*##')
! test -z "$ARGUMENT" && {
	if [[ "$IP" == "$DOMAIN" ]]; then
		whois "$DOMAIN"
	else
		TLD=$(echo $DOMAIN | sed 's#.*\.##')
		if [ -e "${WHOIS_WORKING_DIR}/api/${TLD}.sh" ]; then
			# WEB WHOIS
			RESULT=$("${WHOIS_WORKING_DIR}/api/${TLD}.sh" "$DOMAIN")
		else
			# NON WEB WHOIS
			RESULT=$(whois "$DOMAIN")
			echo "$RESULT" | grep -i "no whois server" > /dev/null
			if [ $? -eq 0 ]; then
				RESULT=$("${WHOIS_WORKING_DIR}/api/getwhois.sh" "$DOMAIN")
			fi
		fi
		echo "$RESULT"
	fi
}