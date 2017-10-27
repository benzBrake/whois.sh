#!/usr/bin/env bash
help_info() {
	echo "Usage: $(basename $0) [OPTION[=PATTERN]]"
	echo "whois.sh | whois client written by shell."
	echo "Different OPTION has different PATTERN."
	echo "Example: $(basename $0) -i doufu.ru"
	echo "Example: $(basename $0) doufu.ru"
	echo ""
	echo "OPTIONs and PATTERNs"
	echo "  -i,-I,-iana,-IANA		get whois infomation from iana"
	echo "  -h,-H,-host			specify whois server"
	echo "  -p,-P,-port			specify whois port"
	echo ""
	echo "Report bugs to github-benzBrake@woai.ru"
}
while echo $1 | grep -q ^-; do
	eval $( echo $1 | sed 's/^-//' )=$2
	shift
	shift
done

PORT=43
! test -z "$host" && SERVER=$host
! test -z "$H" && SERVER=$H
! test -z "$h" && SERVER=$h
! test -z "$port" && PORT=$port
! test -z "$P" && PORT=$P
! test -z "$p" && PORT=$p
DOMAIN=$@
! test -z "$iana" && IANA=$iana
! test -z "$I" && IANA=$I
! test -z "$i" && IANA=$i
! test -z "$IANA" && {
	SERVER="whois.iana.org";
	DOMAIN=$IANA;
}
test -z "$DOMAIN" && {
	echo "Arguments Error."
	echo "====================================="
	help_info
	exit 1
}
test -z "$WHOIS_WORKING_DIR" && WHOIS_WORKING_DIR=$(dirname "$0")
function prep ()
{
	echo "$1" | sed -e 's/^ *//g' -e 's/ *$//g' | sed -n '1 p'
}
IP=$(prep "$(echo "$DOMAIN" | egrep -o '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}')")
DOMAIN=$(echo "$DOMAIN" | sed 's#.*http.*//##;s#/.*##')
if [ -n "$(command -v whois)" ]; then
	WHOIS="whois"
else
	WHOIS="$WHOIS_WORKING_DIR/api/getwhois.sh"
fi
! test -z "$DOMAIN" && {
	if [[ "$IP" == "$DOMAIN" ]]; then
		"$WHOIS_WORKING_DIR/api/ip.sh" "$DOMAIN"
	else
		test -z "$PORT" && {
			PORT=43
		}
		if [ -z "$SERVER" ]; then
			RESULT=$("$WHOIS" $DOMAIN)
		else
			RESULT=$("$WHOIS" -h $SERVER -p $PORT $DOMAIN)
		fi
		echo "$RESULT" | grep -i 'with "xxx"' > /dev/null
		test $? -eq 0 && {
			RESULT=$("$WHOIS" "domain $DOMAIN")
		}
		echo "$RESULT" | grep -i "no whois server" > /dev/null
		test $? -eq 0 && test "$WHOIS" == "whois" && {
			RESULT=$("${WHOIS_WORKING_DIR}/api/getwhois.sh" "$DOMAIN")
		}
		echo "$RESULT" | grep -i "no whois server" > /dev/null
		TLD=$(echo $DOMAIN | sed 's#.*\.##')
		test $? -eq 0 && test -e "${WHOIS_WORKING_DIR}/api/${TLD}.sh" && {
			# WEB WHOIS
			RESULT=$("${WHOIS_WORKING_DIR}/api/${TLD}.sh" "$DOMAIN")
		}
		echo "$RESULT"
	fi
}
