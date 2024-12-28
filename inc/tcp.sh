#!/usr/bin/env bash
while [[ $1 =~ ^- ]]; do
    declare "${1#-}"="$2"
    shift 2
done
[[ -z $host || -z $port || -z $data ]] && exit
while :; do
    ID=$((RANDOM % (1023 - 9 + 1) + 9))
    exec {ID}<>/dev/tcp/$host/$port
    echo -e "$data\r\n" >&$ID
    cat <&$ID
    exec {ID}<&-
    exec {ID}>&-
    break
done