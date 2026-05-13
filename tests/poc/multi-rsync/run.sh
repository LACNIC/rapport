#!/bin/sh

. tools/checks.sh
. rp/$RP.sh


run_barry "step1.rd" --rrdp-uri "" --rrdp-path ""
run_rp
check_vrps \
	"101::/16-16 => AS1234" "1.1.0.0/16-16 => AS1234" \
	"201::/16-16 => AS1234" "2.1.0.0/16-16 => AS1234" \
	"301::/16-16 => AS1234" "3.1.0.0/16-16 => AS1234" \
	"401::/16-16 => AS1234" "4.1.0.0/16-16 => AS1234" \
	"501::/16-16 => AS1234" "5.1.0.0/16-16 => AS1234"
check_rsync_requests "rpki/$TEST/ta.cer" "rpki/"
check_http_requests


new_step
run_barry "step2.rd" --rrdp-uri "" --rrdp-path ""
run_rp
check_vrps \
	"101::/16-16 => AS1234" "1.1.0.0/16-16 => AS1234" \
	"2.22.0.0/16-16 => AS1234" "222::/16-16 => AS1234" \
	"301::/16-16 => AS1234" "302::/16-16 => AS1234" \
	"3.1.0.0/16-16 => AS1234" "3.2.0.0/16-16 => AS1234" \
	"601::/16-16 => AS1234" "6.1.0.0/16-16 => AS1234"
check_rsync_requests "rpki/$TEST/ta.cer" "rpki/"
check_http_requests


cp -p  "$(rp_tal_path)" "$SANDBOX/../tmp.tal"
new_step
cp -p  "$SANDBOX/../tmp.tal" "$(rp_tal_path)"
rm -rf "sandbox/rsyncd/content/$TEST"/*
run_rp
check_rsync_requests "rpki/$TEST/ta.cer" "rpki/"
check_http_requests
check_vrps \
	"101::/16-16 => AS1234" "1.1.0.0/16-16 => AS1234" \
	"2.22.0.0/16-16 => AS1234" "222::/16-16 => AS1234" \
	"301::/16-16 => AS1234" "302::/16-16 => AS1234" \
	"3.1.0.0/16-16 => AS1234" "3.2.0.0/16-16 => AS1234" \
	"601::/16-16 => AS1234" "6.1.0.0/16-16 => AS1234"

new_step
mv     "$SANDBOX/../tmp.tal" "$(rp_tal_path)"
cp -rp "$SANDBOX/../step$((STEP-2))/rsyncd/content/$TEST"/*  "sandbox/rsyncd/content/$TEST"
run_barry "step4.rd" --rrdp-uri "" --rrdp-path ""
run_rp
check_vrps "101::/16-16 => AS1234" "1.1.0.0/16-16 => AS1234"
check_http_requests
check_rsync_requests "rpki/$TEST/ta.cer" "rpki/"
