#!/usr/bin/env bash
# Load functions
test -z "$WHOIS_WORKING_DIR" && WHOIS_WORKING_DIR=$(dirname "$0")
source "$WHOIS_WORKING_DIR/inc/functions.sh"
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
	__help_info
	exit 1
}
TLD=$(echo $DOMAIN | sed 's#.*\.##')
if [[ $(echo $domain | grep -v ":") ]] && [[ $TLD == $DOMAIN ]]; then
	echo "Domain is illegle."
	exit 1
fi
IPV4=$(__prep "$(echo "$DOMAIN" | egrep -o '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}')")
IPV6=$(__prep "$(echo "$DOMAIN" | egrep -o "([0-9a-fA-F]{0,4}:){1,7}([0-9a-fA-F]){0,4}")")
DOMAIN=$(__prep "$DOMAIN")
__WHOIS_BIN="$WHOIS_WORKING_DIR/inc/getwhois.sh"
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
			TLD=$(__get_tld $DOMAIN)
			if [ -e "${WHOIS_WORKING_DIR}/api/${TLD}.sh" ]; then
				# Api first
				RESULT=$("${WHOIS_WORKING_DIR}/api/${TLD}.sh" "$DOMAIN")
			else
				RESULT=$("$__WHOIS_BIN" $DOMAIN)
				# .com whois hack
				echo "$RESULT" | grep -i 'with "xxx"' > /dev/null
				test $? -eq 0 && {
					RESULT=$("$__WHOIS_BIN" "domain $DOMAIN")
				}
			fi
		else
			# Specify whois server
			RESULT=$("$__WHOIS_BIN" -h $SERVER -p $PORT $DOMAIN)
			echo "$RESULT"
		fi
	fi
	echo "$RESULT"
}
