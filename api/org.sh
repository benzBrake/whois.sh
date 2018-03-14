#!/usr/bin/env bash
DOMAIN=$1
SERVER="whois.pir.org"
$WHOIS_WORKING_DIR/inc/tcp.sh -host "$SERVER" -port 43 -data "$DOMAIN"
