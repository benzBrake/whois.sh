#!/usr/bin/env bash
while echo $1 | grep -q ^-; do
	eval $( echo $1 | sed 's/^-//' )=$2
	shift
	shift
done
test -z "$host" && exit
HOST=$host
test -z "$port" && exit
PORT=$port
test -z "$data" && exit
DATA=$data
while true
do
	ID=$(expr $(date +%N) %  $[1023 - 9  + 1] + 9)
	eval "exec $ID<>/dev/tcp/$HOST/$PORT"
	eval "echo -e '$DATA\r\n'>&$ID"
	eval "cat <&$ID"
	eval "exec $ID<&-"
	eval "exec $ID>&-"
	break
done