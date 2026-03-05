#!/usr/bin/env bash
# Azote.org .fr.nf 域名查询
WHOIS_WORKING_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/.."
exec "${WHOIS_WORKING_DIR}/api/azote_common.sh" "$@"
