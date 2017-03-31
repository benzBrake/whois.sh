#!/usr/bin/env bash
while echo $1 | grep -q ^-; do
	eval $( echo $1 | sed 's/^-//' )=$2
	shift
	shift
done

DOMAIN=$@
! test -z "$host" && HOST=$host
! test -z "$H" && HOST=$H
! test -z "$port" && PORT=$port
! test -z "$P" && PORT=$P
! test -z "$iana" && IANA=$iana
! test -z "$I" && IANA=$I
! test -z "$IANA" && { HOST="whois.iana.org"; PORT=43; DOMAIN=$IANA; }
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
	! test -z "$SERVER" && { echo "$TLD=$SERVER" >> "$WHOIS_WORKING_DIR/servers.list"; }
}
REG_URL=$(echo "$RESULT" | grep remarks | grep http | sed 's#.* ##')
while true
do
ID=$(expr $(date +%N) %  $[1023 - 9  + 1] + 9)
	if [ -z "$SERVER" ]; then
		echo "This TLD has no whois server."
		! test -z "$REG_URL" && { echo "You can look through more infomation at $REG_URL"; }
		break
	else
		eval "exec $ID<>/dev/tcp/$SERVER/43"
		eval "echo -e '$DOMAIN\r\n'>&$ID"
		eval "cat <&$ID"
		eval "exec $ID<&-"
		eval "exec $ID>&-"
		break
	fi
done