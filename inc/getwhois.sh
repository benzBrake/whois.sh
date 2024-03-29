#!/usr/bin/env bash
source "$WHOIS_WORKING_DIR/inc/functions.sh"
while echo $1 | grep -q ^-; do
	eval $( echo $1 | sed 's/^-//' )=$2
	shift
	shift
done

PORT=43
! test -z "$host" && SERVER=$host
! test -z "$h" && SERVER=$h
! test -z "$port" && PORT=$port
! test -z "$p" && PORT=$p
DOMAIN=$@
test -z "$DOMAIN" && {
	echo "Arguments Error.";
	exit 1;
}
test -z "$SERVER" && {
	TLD=$(__get_tld $DOMAIN)
	# Remove useless sub domain from domain
	DOMAIN=$(echo $DOMAIN | sed "s/.$TLD//" | sed 's/.*\.//g').$TLD
	if [ -f "$WHOIS_WORKING_DIR/servers.list" ]; then
		_line=$(grep "^$TLD=" "$WHOIS_WORKING_DIR/servers.list")
		if [ -n "$_line" ]; then
			SERVER="$(echo $_line | awk -F'=' '{print $2}')"
		fi
	fi
	# Skip illigle domain
	if [[ "$SERVER" == "illigle" ]]; then
		echo "Domain is illigle."
		exit 1
	fi
	# Get whois server from iana
	test -z "$SERVER" && {
		RESULT=$(curl -s "https://www.iana.org/whois?q=$DOMAIN")
		SERVER=$(echo "$RESULT" | grep "whois:" | sed 's#.* ##')
		! test -z "$SERVER" && { echo "$TLD=$SERVER" >> "$WHOIS_WORKING_DIR/servers.list"; }
	}
	# Get Registry's Home Page
	REG_URL=$(echo "$RESULT" | grep remarks | grep http | sed 's#.* ##')
}

if [ ! -z "$SERVER" ]; then
	RESULT=$($WHOIS_WORKING_DIR/inc/tcp.sh -host $SERVER -port $PORT -data $DOMAIN)
	echo "$RESULT"
else
	if [[ -z "$REG_URL" ]]; then
		echo "$TLD=illigle" >> "$WHOIS_WORKING_DIR/servers.list";
		echo "Domain is illigle."
	else
		echo -e "This TLD has no whois server, but you can access the whois database at\n$REG_URL"
	fi
fi
