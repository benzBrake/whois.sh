#!/usr/bin/env bash
# output help info
__help_info() {
    cat <<EOF
Usage: $(basename $0) [OPTION[=PATTERN]]
whois.sh | whois client written by shell.
Different OPTION has different PATTERN.
Example: $(basename $0) -i doufu.ru
Example: $(basename $0) doufu.ru
OPTIONs and PATTERNs
  -i,-I,-iana,-IANA    get whois infomation from iana
  -h,-H,-host          specify whois server
  -p,-P,-port          specify whois port
Report bugs to github-benzBrake@woai.ru
EOF
}

# trim string
__prep() {
	echo "$1" | sed -e 's/^ *//g' -e 's/ *$//g' | sed -n '1 p'
}

# get tld from domain
function __get_tld() {
	_tld="$(__prep "$@")"
	while :; do echo > /dev/null
		_dc="$(echo $_tld | tr -cd "." | wc -c)"
		if [ $_dc -le 2 ]; then
			break
		fi
		_tld="$(echo $_tld | perl -pe 's/^(.*?\.){1}//')"
	done
	_tlda="$(echo $_tld | perl -pe 's/^(.*?\.){1}//')"
	_tldb="$(echo $_tld | sed 's#.*\.##')"
	if [[ "$_tlda" == "$_tldb" ]]; then
		echo "$_tldb"
	else
		echo "$_tlda"
	fi
}

# detect if string contain {{domain}}
__contain_string() {
    [ -n "$(echo "$1" | grep "$2")" ]
    return $?
}