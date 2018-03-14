#!/usr/bin/env bash
DOMAIN=$1
SERVER=$($WHOIS_WORKING_DIR/inc/tcp.sh -host whois.verisign-grs.com -port 43 -data "$DOMAIN")
SERVER=$(echo -e "$SERVER" | grep "Registrar WHOIS Server" | awk '{print $4}' | sed "s#\r##g")
$WHOIS_WORKING_DIR/inc/tcp.sh -host "$SERVER" -port 43 -data "$DOMAIN"
