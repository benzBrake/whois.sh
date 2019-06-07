#!/usr/bin/env bash
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
function __prep()
{
	echo "$1" | sed -e 's/^ *//g' -e 's/ *$//g' | sed -n '1 p'
}