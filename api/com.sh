#!/usr/bin/env bash
DOMAIN=$1
TLD=$(echo $DOMAIN | sed 's#.*\.##')
if [ -z $TLD ]; then
	echo "Domain is illegle."
	exit 1
fi
SLD=$(echo $DOMAIN | sed "s#.${TLD}##" | sed 's#.*\.##')
SDM=$(echo $DOMAIN | sed "s#${SLD}.${TLD}##" | sed 's#\..*##')
if [[ ! -z "$SDM" ]]; then
	# CentralNic SLDs
	if [[ "$SLD" == "br" || "$SLD" == "cn"  || "$SLD" == "co" || "$SLD" == "de" || "$SLD" == "eu" || "$SLD" == "gr" || "$SLD" == "jpn" || "$SLD" == "mex" || "$SLD" == "ru" || "$SLD" == "sa" || "$SLD" == "uk" || "$SLD" == "us" || "$SLD" == "za" ]]; then
		SERVER=whois.centralnic.com
	else
		SERVER=$($WHOIS_WORKING_DIR/inc/tcp.sh -host whois.verisign-grs.com -port 43 -data "$DOMAIN")
		SERVER=$(echo -e "$SERVER" | grep "Registrar WHOIS Server" | awk '{print $4}' | sed "s#\r##g")
	fi
else
	SERVER=$($WHOIS_WORKING_DIR/inc/tcp.sh -host whois.verisign-grs.com -port 43 -data "$DOMAIN")
	SERVER=$(echo -e "$SERVER" | grep "Registrar WHOIS Server" | awk '{print $4}' | sed "s#\r##g")
fi
$WHOIS_WORKING_DIR/inc/tcp.sh -host "$SERVER" -port 43 -data "$DOMAIN"
