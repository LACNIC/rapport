#!/bin/sh

. tools/checks.sh
. rp/$RP.sh


# Stage 1: Normal, simple run

echo "  Step 1"
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

check_fort_cache 0 2
check_fort_cache_file "https://localhost:8443/$TEST/ta.cer"
check_fort_cache_cage_begin "https://localhost:8443/$TEST/notification.xml"
check_fort_cache_rrdp_step "1" "1" \
	"A/A.crl" "A/A.mft" "A/A.roa" \
	"B/B.crl" "B/B.mft" "B/B.roa" \
	"C/C1.roa" "C/C.crl" "C/C.mft" \
	"D/D.crl" "D/D.mft" "D/D.roa" \
	"E/E.crl" "E/E.mft" "E/E.roa" \
	"ta/A.cer" "ta/B.cer" "ta/C.cer" "ta/D.cer" "ta/E.cer" \
	"ta/ta.crl" "ta/ta.mft"
check_fort_cache_rrdp_fallback \
	"1" "rsync://localhost:8873/rpki/$TEST/ta" \
	"ta/A.cer" "ta/B.cer" "ta/C.cer" "ta/D.cer" "ta/E.cer" \
	"ta/ta.crl" "ta/ta.mft"
check_fort_cache_rrdp_fallback \
	"1" "rsync://localhost:8873/rpki/$TEST/A" \
	"A/A.crl" "A/A.mft" "A/A.roa"
check_fort_cache_rrdp_fallback \
	"1" "rsync://localhost:8873/rpki/$TEST/B" \
	"B/B.crl" "B/B.mft" "B/B.roa"
check_fort_cache_rrdp_fallback \
	"1" "rsync://localhost:8873/rpki/$TEST/C" \
	"C/C1.roa" "C/C.crl" "C/C.mft"
check_fort_cache_rrdp_fallback \
	"1" "rsync://localhost:8873/rpki/$TEST/D" \
	"D/D.crl" "D/D.mft" "D/D.roa"
check_fort_cache_rrdp_fallback \
	"1" "rsync://localhost:8873/rpki/$TEST/E" \
	"E/E.crl" "E/E.mft" "E/E.roa"
check_fort_cache_cage_end

# TODO cleanup properly
rm "$SANDBOX/rrdp/"*

# Stage 2: Some ROAs change

echo "  Step 2"
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

check_fort_cache 0 2
check_fort_cache_file "https://localhost:8443/$TEST/ta.cer"
check_fort_cache_cage_begin "https://localhost:8443/$TEST/notification.xml"
check_fort_cache_rrdp_step "1" "2" \
	"A/A.crl" "A/A.mft" "A/A.roa" \
	"B/B.crl" "B/B.mft" "B/B.roa" \
	"C/C1.roa" "C/C2.roa" "C/C.crl" "C/C.mft" \
	"D/D.crl" "D/D.mft" \
	"F/F.crl" "F/F.mft" "F/F.roa" \
	"ta/A.cer" "ta/B.cer" "ta/C.cer" "ta/D.cer" "ta/F.cer" \
	"ta/ta.crl" "ta/ta.mft"
check_fort_cache_rrdp_fallback "1" "rsync://localhost:8873/rpki/$TEST/ta" \
	"ta/A.cer" "ta/B.cer" "ta/C.cer" "ta/D.cer" "ta/F.cer" "ta/ta.crl" "ta/ta.mft"
check_fort_cache_rrdp_fallback "1" "rsync://localhost:8873/rpki/$TEST/A" "A/A.crl" "A/A.mft" "A/A.roa"
check_fort_cache_rrdp_fallback "1" "rsync://localhost:8873/rpki/$TEST/B" "B/B.crl" "B/B.mft" "B/B.roa"
check_fort_cache_rrdp_fallback "1" "rsync://localhost:8873/rpki/$TEST/C" "C/C1.roa" "C/C2.roa" "C/C.crl" "C/C.mft"
check_fort_cache_rrdp_fallback "1" "rsync://localhost:8873/rpki/$TEST/D" "D/D.crl" "D/D.mft"
check_fort_cache_rrdp_fallback "1" "rsync://localhost:8873/rpki/$TEST/F" "F/F.crl" "F/F.mft" "F/F.roa"
check_fort_cache_cage_end

# TODO cleanup properly
rm "$SANDBOX/rrdp/"*

# Stage 3: Both RRDP and rsync die, RP needs to fallback

echo "  Step 3"
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
#	"rpki/$TEST/ta.cer" \
#	"rpki/"

# Nothing changes
check_fort_cache 0 2
check_fort_cache_file "https://localhost:8443/$TEST/ta.cer"
check_fort_cache_cage_begin "https://localhost:8443/$TEST/notification.xml"
check_fort_cache_rrdp_step "1" "2" \
	"A/A.crl" "A/A.mft" "A/A.roa" \
	"B/B.crl" "B/B.mft" "B/B.roa" \
	"C/C1.roa" "C/C2.roa" "C/C.crl" "C/C.mft" \
	"D/D.crl" "D/D.mft" \
	"F/F.crl" "F/F.mft" "F/F.roa" \
	"ta/A.cer" "ta/B.cer" "ta/C.cer" "ta/D.cer" "ta/F.cer" \
	"ta/ta.crl" "ta/ta.mft"
check_fort_cache_rrdp_fallback "1" "rsync://localhost:8873/rpki/$TEST/ta" \
	"ta/A.cer" "ta/B.cer" "ta/C.cer" "ta/D.cer" "ta/F.cer" "ta/ta.crl" "ta/ta.mft"
check_fort_cache_rrdp_fallback "1" "rsync://localhost:8873/rpki/$TEST/A" "A/A.crl" "A/A.mft" "A/A.roa"
check_fort_cache_rrdp_fallback "1" "rsync://localhost:8873/rpki/$TEST/B" "B/B.crl" "B/B.mft" "B/B.roa"
check_fort_cache_rrdp_fallback "1" "rsync://localhost:8873/rpki/$TEST/C" "C/C1.roa" "C/C2.roa" "C/C.crl" "C/C.mft"
check_fort_cache_rrdp_fallback "1" "rsync://localhost:8873/rpki/$TEST/D" "D/D.crl" "D/D.mft"
check_fort_cache_rrdp_fallback "1" "rsync://localhost:8873/rpki/$TEST/F" "F/F.crl" "F/F.mft" "F/F.roa"
check_fort_cache_cage_end

# TODO cleanup properly
rm "$SANDBOX/rrdp/"*

# Stage 4: RRDP and rsync come back, RP recovers via delta

echo "  Step 4"
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

check_fort_cache 0 2
check_fort_cache_file "https://localhost:8443/$TEST/ta.cer"
check_fort_cache_cage_begin "https://localhost:8443/$TEST/notification.xml"
check_fort_cache_rrdp_step "1" "3" "A/A.crl" "A/A.mft" "A/A.roa" "ta/A.cer" "ta/ta.crl" "ta/ta.mft"
check_fort_cache_rrdp_fallback "1" "rsync://localhost:8873/rpki/$TEST/ta" "ta/A.cer" "ta/ta.crl" "ta/ta.mft"
check_fort_cache_rrdp_fallback "1" "rsync://localhost:8873/rpki/$TEST/A" "A/A.crl" "A/A.mft" "A/A.roa"
check_fort_cache_cage_end
