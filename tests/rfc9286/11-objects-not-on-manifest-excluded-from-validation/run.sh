#!/bin/sh

. tools/checks.sh
. rp/$RP.sh

run_barry rd1

cp "sandbox/rsyncd/content/$TEST/ca/valid-1-1.roa" \
   "sandbox/rsyncd/content/$TEST/ca/roa-unlisted.roa"

run_rp

check_vrps \
   "2.1.0.0/24-24 => AS20001" \
   "2.1.1.0/24-24 => AS20001" \
   "3.1.0.0/24-24 => AS30001" \
   "3.1.1.0/24-24 => AS30001"