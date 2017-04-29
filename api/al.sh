#!/usr/bin/env bash
DOMAIN=$1
RESULT=$(curl -s "https://albaniandomains.al/whmcs/whois.php?domain=$DOMAIN")
if [ -z "$(echo "$RESULT" | grep registered)" ]; then
	echo "Congratulations, $DOMAIN is available!"
else
	echo "Sorry, $DOMAIN is already registered. "
	echo "$RESULT" | grep Nameserver | sed 's#\s*<br />\s*##g'
fi
