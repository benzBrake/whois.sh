#!/usr/bin/env bash
DOMAIN=$1
RESULT=$(curl -s -d "key=getConsulta&dominio=$DOMAIN" "http://nic.sv/ajax/procesa.php" | sed 's#<[^<>]*table[^<>]*>##g;s#\s*</td>\s*</tr>\s*<tr>\s*<td[^<>]*>\s*#\n#g;s#</td>\s*<td[^<>]*># #g;s#<[^<>]*>##g;s#&nbsp;##g;s#^\s##g')
echo "$RESULT" | grep "$DOMAIN" > /dev/null
if [ $? -ne 0 ]; then
	echo -e "está dísponible.\nDomain is available."
else
	echo "$RESULT"
fi