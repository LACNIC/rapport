#!/bin/sh

. tools/checks.sh
. rp/$RP.sh

case "$RP" in
	"fort2")
		MAXDEPTH_ARG="--maximum-certificate-depth 13"
		;;
	"routinator")
		MAXDEPTH_ARG="--max-ca-depth 11"
		;;
	"rpki-client")
		MAXDEPTH_ARG="" # Hardcoded
		;;
	"rpki-prover")
		MAXDEPTH_ARG="--max-certificate-path-depth 12"
		;;
	*)
		fail "Test '$TEST' does not support $RP"
		;;
esac

run_barry "$TEST.rd"
run_rp $MAXDEPTH_ARG

check_report fort2       -F "Certificate chain maximum depth exceeded."
check_report rpki-client -F "maximum certificate chain depth exhausted"
# TODO prover & routinator

check_vrp_output \
	"1.0.0.0/8-8 => AS1234" \
	"100::/8-8 => AS1234" \
	"201::/16-16 => AS1234" \
	"202:100::/24-24 => AS1234" \
	"202:201::/32-32 => AS1234" \
	"202:202:100::/40-40 => AS1234" \
	"202:202:201::/48-48 => AS1234" \
	"202:202:202:100::/56-56 => AS1234" \
	"202:202:202:201::/64-64 => AS1234" \
	"202:202:202:202:100::/72-72 => AS1234" \
	"202:202:202:202:201::/80-80 => AS1234" \
	"202:202:202:202:202:100::/88-88 => AS1234" \
	"202:202:202:202:202:201::/96-96 => AS1234" \
	"2.1.0.0/16-16 => AS1234" \
	"2.2.1.0/24-24 => AS1234" \
	"2.2.2.1/32-32 => AS1234" \
	"2.2.2.2/32-32 => AS1234"
check_http_requests \
	"/$TEST/ta.cer 200" \
	"/$TEST/notification.xml 200" \
	"/$TEST/notification.xml.snapshot 200"
check_rsync_requests

######################### Fort-Only #########################

check_fort_cache 0 1 1 13 # 0-C
check_fort_cache_file https
check_fort_cache_cage rrdp \
	"1/1.crl" "1/1.mft" "1/2.cer" "1/2.roa" \
	"2/2.crl" "2/2.mft" "2/3.cer" "2/3.roa" \
	"3/3.crl" "3/3.mft" "3/4.cer" "3/4.roa" \
	"4/4.crl" "4/4.mft" "4/5.cer" "4/5.roa" \
	"5/5.crl" "5/5.mft" "5/6.cer" "5/6.roa" \
	"6/6.crl" "6/6.mft" "6/7.cer" "6/7.roa" \
	"7/7.crl" "7/7.mft" "7/8.cer" "7/8.roa" \
	"8/8.crl" "8/8.mft" "8/9.cer" "8/9.roa" \
	"9/9.crl" "9/9.mft" "9/a.cer" "9/a.roa" \
	"a/a.crl" "a/a.mft" "a/b.cer" "a/b.roa" \
	"b/b.crl" "b/b.mft" "b/c.cer" "b/c.roa" \
	"c/c.crl" "c/c.mft" "c/d.cer" "c/d.roa" \
	"d/d.crl" "d/d.mft" "d/e.cer" "d/e.roa" \
	"e/e.crl" "e/e.mft" \
	"ta/1.cer" "ta/1.roa" "ta/ta.crl" "ta/ta.mft"
check_fort_cache_cage fallback "ta/1.cer" "ta/1.roa" "ta/ta.crl" "ta/ta.mft"
check_fort_cache_file fallback
check_fort_cache_cage fallback "1/1.crl" "1/1.mft" "1/2.cer" "1/2.roa"
check_fort_cache_cage fallback "2/2.crl" "2/2.mft" "2/3.cer" "2/3.roa"
check_fort_cache_cage fallback "3/3.crl" "3/3.mft" "3/4.cer" "3/4.roa"
# ...
check_fort_cache_cage fallback "a/a.crl" "a/a.mft" "a/b.cer" "a/b.roa"
check_fort_cache_cage fallback "b/b.crl" "b/b.mft" "b/c.cer" "b/c.roa"
