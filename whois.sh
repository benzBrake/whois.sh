#!/usr/bin/env bash
while echo $1 | grep -q ^-; do
	eval $( echo $1 | sed 's/^-//' )=$2
	shift
	shift
done

ARGUMENT=$@
! test -z "$host" && HOST=$host
! test -z "$H" && HOST=$H
! test -z "$port" && PORT=$port
! test -z "$P" && PORT=$P
! test -z "$iana" && IANA=$iana
! test -z "$I" && IANA=$I
! test -z "$IANA" && { HOST="whois.iana.org"; PORT=43; ARGUMENT=$IANA; }

test -z "$ARGUMENT" && { echo "Arguments Error."; exit 1;}
test -z "$WHOIS_WORKING_DIR" && WHOIS_WORKING_DIR=$(dirname "$0")
function prep ()
{
	echo "$1" | sed -e 's/^ *//g' -e 's/ *$//g' | sed -n '1 p'
}
IP=$(prep "$(echo "$ARGUMENT" | egrep -o '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}')")
DOMAIN=$(echo "$ARGUMENT" | sed 's#.*http.*//##;s#/.*##')
if [ -n "$(command -v whois)" ]; then
	WHOIS="whois"
else
	WHOIS="$WHOIS_WORKING_DIR/api/getwhois.sh"
fi
! test -z "$ARGUMENT" && {
	if [[ "$IP" == "$DOMAIN" ]]; then
		"$WHOIS" "$DOMAIN"
	else
		if [ "$HOST" != "" ] && [ "$PORT" != "" ]; then
			"$WHOIS" -h $HOST -p $PORT $DOMAIN
		else
			TLD=$(echo $DOMAIN | sed 's#.*\.##')
			if [ -e "${WHOIS_WORKING_DIR}/api/${TLD}.sh" ]; then
				# WEB WHOIS
				RESULT=$("${WHOIS_WORKING_DIR}/api/${TLD}.sh" "$DOMAIN")
			else
				# NON WEB WHOIS
				RESULT=$("$WHOIS" "$DOMAIN")
				if [ $? -ne 0 ]; then
					RESULT=$("${WHOIS_WORKING_DIR}/api/getwhois.sh" "$DOMAIN")
				fi
				echo "$RESULT" | grep -i "no whois server" > /dev/null
				test $? -eq 0 && test "$WHOIS" == "whois" && {
					RESULT=$("${WHOIS_WORKING_DIR}/api/getwhois.sh" "$DOMAIN")
				}
			fi
		fi
		echo "$RESULT"
	fi
}