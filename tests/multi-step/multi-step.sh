#!/bin/sh

. tools/checks.sh
. rp/$RP.sh


# Stage 1: Normal, simple run

echo "$TEST: Step 1"
run_barry "step1.rd"
run_rp

check_vrp_output \
	"101::/16-16 => AS1234" "1.1.0.0/16-16 => AS1234" \
	"201::/16-16 => AS1234" "2.1.0.0/16-16 => AS1234" \
	"301::/16-16 => AS1234" "3.1.0.0/16-16 => AS1234" \
	"401::/16-16 => AS1234" "4.1.0.0/16-16 => AS1234" \
	"501::/16-16 => AS1234" "5.1.0.0/16-16 => AS1234"
check_http_requests \
	"/$TEST/ta.cer 200" \
	"/$TEST/notification.xml 200" \
	"/$TEST/notification.xml.snapshot 200"
check_rsync_requests

check_fort_cache 0 1 1 7
check_fort_cache_file https
check_fort_cache_cage rrdp \
	"A/A.crl" "A/A.mft" "A/A.roa" \
	"B/B.crl" "B/B.mft" "B/B.roa" \
	"C/C.crl" "C/C.mft" "C/C1.roa" \
	"D/D.crl" "D/D.mft" "D/D.roa" \
	"E/E.crl" "E/E.mft" "E/E.roa" \
	"ta/A.cer" "ta/B.cer" "ta/C.cer" "ta/D.cer" "ta/E.cer" "ta/ta.crl" "ta/ta.mft"
check_fort_cache_file fallback
check_fort_cache_cage fallback \
	"ta/A.cer" "ta/B.cer" "ta/C.cer" "ta/D.cer" "ta/E.cer" "ta/ta.crl" "ta/ta.mft"
check_fort_cache_cage fallback "A/A.crl" "A/A.mft" "A/A.roa"
check_fort_cache_cage fallback "B/B.crl" "B/B.mft" "B/B.roa"
check_fort_cache_cage fallback "C/C.crl" "C/C.mft" "C/C1.roa"
check_fort_cache_cage fallback "D/D.crl" "D/D.mft" "D/D.roa"
check_fort_cache_cage fallback "E/E.crl" "E/E.mft" "E/E.roa"

# Stage 2: Some ROAs change

echo "$TEST: Step 2"
create_delta "step2.rd"
run_rp

check_vrp_output \
	"101::/16-16 => AS1234" "1.1.0.0/16-16 => AS1234" \
	"2.22.0.0/16-16 => AS1234" "222::/16-16 => AS1234" \
	"301::/16-16 => AS1234" "302::/16-16 => AS1234" \
	"3.1.0.0/16-16 => AS1234" "3.2.0.0/16-16 => AS1234" \
	"601::/16-16 => AS1234" "6.1.0.0/16-16 => AS1234"
check_http_requests \
	"/$TEST/ta.cer 304" \
	"/$TEST/notification.xml 200" \
	"/$TEST/delta-step2.rd.xml 200"
check_rsync_requests

check_fort_cache 0 1 1 8
check_fort_cache_file https
check_fort_cache_cage rrdp \
	"A/A.crl" "A/A.mft" "A/A.roa" \
	"B/B.crl" "B/B.mft" "B/B.roa" \
	"C/C.crl" "C/C.mft" "C/C1.roa" "C/C2.roa" \
	"D/D.crl" "D/D.mft" \
	"F/F.crl" "F/F.mft" "F/F.roa" \
	"ta/A.cer" "ta/B.cer" "ta/C.cer" "ta/D.cer" "ta/F.cer" "ta/ta.crl" "ta/ta.mft"
check_fort_cache_file fallback
#check_fort_cache_cage fallback TODO
#	"ta/A.cer" "ta/B.cer" "ta/C.cer" "ta/D.cer" "ta/F.cer" "ta/ta.crl" "ta/ta.mft"
check_fort_cache_cage fallback "A/A.crl" "A/A.mft" "A/A.roa"
check_fort_cache_cage fallback "B/B.crl" "B/B.mft" "B/B.roa"
check_fort_cache_cage fallback "C/C.crl" "C/C.mft" "C/C1.roa" "C/C2.roa"
#check_fort_cache_cage fallback "D/D.crl" "D/D.mft" TODO
check_fort_cache_cage fallback "E/E.crl" "E/E.mft" "E/E.roa"
check_fort_cache_cage fallback "F/F.crl" "F/F.mft" "F/F.roa"

# Stage 3: Both RRDP and rsync die, RP needs to fallback

echo "$TEST: Step 3"
mv "sandbox/apache2/content/$TEST" "$SANDBOX/tmp-apache2"
mv "sandbox/rsyncd/content/$TEST" "$SANDBOX/tmp-rsync"
run_rp

check_vrp_output \
	"101::/16-16 => AS1234" "1.1.0.0/16-16 => AS1234" \
	"2.22.0.0/16-16 => AS1234" "222::/16-16 => AS1234" \
	"301::/16-16 => AS1234" "302::/16-16 => AS1234" \
	"3.1.0.0/16-16 => AS1234" "3.2.0.0/16-16 => AS1234" \
	"601::/16-16 => AS1234" "6.1.0.0/16-16 => AS1234"
check_http_requests \
	"/$TEST/ta.cer 404" \
	"/$TEST/notification.xml 404"
#check_rsync_requests \
#	"rpki/multi-step/ta.cer" \
#	"rpki/"
# TODO
check_rsync_requests "rpki/"

# Nothing changes
check_fort_cache 0 1 1 8
check_fort_cache_file https
check_fort_cache_cage rrdp \
	"A/A.crl" "A/A.mft" "A/A.roa" \
	"B/B.crl" "B/B.mft" "B/B.roa" \
	"C/C.crl" "C/C.mft" "C/C1.roa" "C/C2.roa" \
	"D/D.crl" "D/D.mft" \
	"F/F.crl" "F/F.mft" "F/F.roa" \
	"ta/A.cer" "ta/B.cer" "ta/C.cer" "ta/D.cer" "ta/F.cer" "ta/ta.crl" "ta/ta.mft"
check_fort_cache_file fallback
#check_fort_cache_cage fallback TODO
#	"ta/A.cer" "ta/B.cer" "ta/C.cer" "ta/D.cer" "ta/F.cer" "ta/ta.crl" "ta/ta.mft"
check_fort_cache_cage fallback "A/A.crl" "A/A.mft" "A/A.roa"
check_fort_cache_cage fallback "B/B.crl" "B/B.mft" "B/B.roa"
check_fort_cache_cage fallback "C/C.crl" "C/C.mft" "C/C1.roa" "C/C2.roa"
#check_fort_cache_cage fallback "D/D.crl" "D/D.mft" TODO
check_fort_cache_cage fallback "E/E.crl" "E/E.mft" "E/E.roa"
check_fort_cache_cage fallback "F/F.crl" "F/F.mft" "F/F.roa"

# Stage 4: RRDP and rsync come back, RP recovers via delta

echo "$TEST: Step 4"
mv "$SANDBOX/tmp-apache2" "sandbox/apache2/content/$TEST"
mv "$SANDBOX/tmp-rsync" "sandbox/rsyncd/content/$TEST"
create_delta "step4.rd"
run_rp

check_vrp_output "101::/16-16 => AS1234" "1.1.0.0/16-16 => AS1234"
check_http_requests \
	"/$TEST/ta.cer 304" \
	"/$TEST/notification.xml 200" \
	"/$TEST/delta-step4.rd.xml 200"
check_rsync_requests

check_fort_cache 0 1 1 8
check_fort_cache_file https
check_fort_cache_cage rrdp \
	"A/A.crl" "A/A.mft" "A/A.roa" \
	"ta/A.cer" "ta/ta.crl" "ta/ta.mft"
check_fort_cache_file fallback
#check_fort_cache_cage fallback "ta/A.cer" "ta/ta.crl" "ta/ta.mft" TODO
check_fort_cache_cage fallback "A/A.crl" "A/A.mft" "A/A.roa"
check_fort_cache_cage fallback "B/B.crl" "B/B.mft" "B/B.roa"
check_fort_cache_cage fallback "C/C.crl" "C/C.mft" "C/C1.roa" "C/C2.roa"
#check_fort_cache_cage fallback "D/D.crl" "D/D.mft" TODO
check_fort_cache_cage fallback "E/E.crl" "E/E.mft" "E/E.roa"
check_fort_cache_cage fallback "F/F.crl" "F/F.mft" "F/F.roa"
