#!/bin/bash
DOMAIN=$(echo $1 | sed 's#\.us\.kg##')
curl -sSL "https://register.us.kg/whois?name=$DOMAIN"