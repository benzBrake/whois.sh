#!/usr/bin/env bash
DOMAIN=$1
RESULT=$(curl -s -d "name=$DOMAIN" https://www.nic.tt/cgi-bin/search.pl | grep '<tr><td>Domain Name</td>' | sed 's#</td></tr> <tr><td>#\n#g;s#</td> <td>#:#g;s#<[^<>]*>##g;s#&nbsp##g')
echo "$RESULT"