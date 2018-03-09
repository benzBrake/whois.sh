#!/usr/bin/env bash
DOMAIN="$@"
RESULT=$($WHOIS_WORKING_DIR/inc/tcp.sh -host whois.iana.org -port 43 -data $DOMAIN)
PREFIX=$(echo "$DOMAIN" | sed 's#\..*##')
! test -e "${WHOIS_WORKING_DIR}/prefix.list" && touch "${WHOIS_WORKING_DIR}/prefix.list"
HANDLER=$(cat $WHOIS_WORKING_DIR/prefix.list | grep "PREFIX${PREFIX}" | sed "s#^.*=##")
test -z "$HANDLER" && {
	HANDLER=$(echo -e "$RESULT" | grep 'whois:' | sed 's#^[^ ]* *##')
	test -z "$HANDLER" && {
		echo "Do not support this ip address."
		exit -1
	}
	echo "PREFIX${PREFIX}=${HANDLER}" >> "$WHOIS_WORKING_DIR/prefix.list"
}
RESULT=$($WHOIS_WORKING_DIR/inc/tcp.sh -host $HANDLER -port 43 -data $DOMAIN)
echo -e "$RESULT"