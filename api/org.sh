#!/usr/bin/env bash
DOMAIN=$1
TLD=$(echo $DOMAIN | sed 's#.*\.##')
if [ -z $TLD ]; then
	echo "Domain is illegle."
	exit 1
fi
SLD=$(echo $DOMAIN | sed "s#.${TLD}##" | sed 's#.*\.##')
SDM=$(echo $DOMAIN | sed "s#${SLD}.${TLD}##" | sed 's#\..*##')
SERVER="whois.pir.org"
if [[ ! -z "$SDM" ]]; then
	if [[ "$SLD" == "eu" ]]; then
		SERVER=whois.eu.org
	elif [[ "$SLD" == "us" ]]; then
		SERVER=whois.centralnic.com
	fi
fi
$WHOIS_WORKING_DIR/inc/tcp.sh -host "$SERVER" -port 43 -data "$DOMAIN"