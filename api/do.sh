#!/bin/bash
DOMAIN=$1
TLD=$(echo $DOMAIN | sed 's#^.*\.##')
SLD=$(echo $DOMAIN | sed 's#\.'$TLD'$##;s#^.*\.##')
DOM=$(echo $DOMAIN | sed 's#\.'$TLD'$##;s#\.'$SLD'$##;')
if [ "$SLD" == "com" ] || [ "$SLD" == "net" ] || [ "$SLD" == "web" ] || [ "$SLD" == "edu" ] || [ "$SLD" == "org" ] || [ "$SLD" == "art" ] || [ "$SLD" == "sld" ]; then
	if [ "$SLD" != "$DOM" ]; then
		TLD="${SLD}.${TLD}"
		DOMAIN="$DOM"
	else
		DOMAIN="$SLD"
	fi
else
	DOMAIN="$SLD"
fi
RESULT=$(curl -s -d "dns_answer=&T1=${DOMAIN}&do=${TLD}&B1=Query" "http://www.nic.do/whoisingles.php3")
TEMP=$(echo "$RESULT" | grep available)
if [ ! -z "$TEMP" ]; then
	echo "The domain name $DOMAIN.$TLD is available."
else
	echo $RESULT | sed 's#<br />#\n#g;s#<[^<>]*>##g;s#&nbsp;##g'
fi