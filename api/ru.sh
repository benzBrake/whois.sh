#!/usr/bin/env bash
SERVER=whois.ripn.net
DOMAIN=$1
TLD=$(echo $DOMAIN | sed 's#.*\.##')
if [ -z $TLD ]; then
	echo "Domain is illegle."
	exit 1
fi
SLD=$(echo $DOMAIN | sed "s#.${TLD}##" | sed 's#.*\.##')
SDM=$(echo $DOMAIN | sed "s#${SLD}.${TLD}##" | sed 's#\..*##')
if [[ -z  $SDM ]];then
	DOMAIN="$SLD.$TLD"
else
	DOMAIN="$SDM.$SLD.$TLD"
	[[ $SLD == "com" ]] && SERVER=whois.reg.ru
	[[ $SLD == "net" ]] && SERVER=whois.nic.net.ru
        [[ $SLD == "org" ]] && SERVER=whois.nic.net.ru
	[[ $SLD == "msk" ]] && SERVER=whois.regtime.net
	[[ $SLD == "spb" ]] && SERVER=whois.nic.ru
	[[ $SLD == "pp" ]] && SERVER=whois.nic.ru
	[[ $SLD == "sochi" ]] && SERVER=whois.nic.ru
fi
$WHOIS_WORKING_DIR/inc/tcp.sh -host $SERVER -port 43 -data $DOMAIN
