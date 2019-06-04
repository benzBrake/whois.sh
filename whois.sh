#!/usr/bin/env bash
# function defined start
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
function prep ()
{
	echo "$1" | sed -e 's/^ *//g' -e 's/ *$//g' | sed -n '1 p'
}
# function defined end
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
TLD=$(echo $DOMAIN | sed 's#.*\.##')
if [[ $(echo $domain | grep -v ":") ]] && [[ $TLD == $DOMAIN ]]; then
	echo "Domain is illegle."
	exit 1
fi
test -z "$WHOIS_WORKING_DIR" && WHOIS_WORKING_DIR=$(dirname "$0")
IPV4=$(prep "$(echo "$DOMAIN" | egrep -o '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}')")
IPV6=$(prep "$(echo "$DOMAIN" | egrep -o "([0-9a-fA-F]{0,4}:){1,7}([0-9a-fA-F]){0,4}")")
DOMAIN=$(echo "$DOMAIN" | sed 's#.*http.*//##;s#/.*##')
WHOIS="$WHOIS_WORKING_DIR/inc/getwhois.sh"
! test -z "$DOMAIN" && {
	if [[ "$IPV4" == "$DOMAIN" ]]; then
		"$WHOIS_WORKING_DIR/inc/ip.sh" "$DOMAIN"
	elif [[ "$IPV6" == "$DOMAIN" ]]; then
		echo "IPv6 support is unavaliable."
	else
		test -z "$PORT" && {
			PORT=43
		}
		if [ -z "$SERVER" ]; then
			# Built-in whois order
			TLD=$(echo $DOMAIN | sed 's#.*\.##')
			if [ -e "${WHOIS_WORKING_DIR}/api/${TLD}.sh" ]; then
				# Api first
				RESULT=$("${WHOIS_WORKING_DIR}/api/${TLD}.sh" "$DOMAIN")
			else
				RESULT=$("$WHOIS" $DOMAIN)
				# .com whois hack
				echo "$RESULT" | grep -i 'with "xxx"' > /dev/null
				test $? -eq 0 && {
					RESULT=$("$WHOIS" "domain $DOMAIN")
				}
			fi
		else
			# Specify whois server
			RESULT=$("$WHOIS" -h $SERVER -p $PORT $DOMAIN)
			echo "$RESULT"
		fi
	fi
	echo "$RESULT"
}
