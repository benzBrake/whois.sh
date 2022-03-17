#!/usr/bin/env bash
# output help info
__help_info() {
	echo "Usage: $(basename $0) [OPTION[=PATTERN]]"
	echo "whois.sh | whois client written by shell."
	echo "Different OPTION has different PATTERN."
	echo "Example: $(basename $0) -i doufu.ru"
	echo "Example: $(basename $0) doufu.ru"
	echo ""
	echo "OPTIONs and PATTERNs"
	echo "  -i,-I,-iana,-IANA		get whois infomation from iana"
	echo "  -h,-H,-host			specify whois server"
	echo "  -p,-P,-port			specify whois port"
	echo ""
	echo "Report bugs to github-benzBrake@woai.ru"
}
# remove blank
function __prep()
{
	echo "$1" | sed -e 's/^ *//g' -e 's/ *$//g' | sed -n '1 p'
}
# Get tld from domain
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