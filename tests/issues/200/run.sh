#!/bin/sh

# Variant: In step 3, the notification's session and serial do not
# change, but the notification does have new data.

. "tools/checks.sh"
. "tests/fort-cache/checks.sh"
. "rp/$RP.sh"

APACHEDIR="sandbox/apache2/8443/content/$TEST"

# Step 1 (Setup)

run_barry "rd1"
run_rp --rsync.enabled=false
check_vrps "1.1.1.0/24-24 => AS64501"
check_http_requests \
	"/$TEST/ta.cer 200" \
	"/$TEST/notification.xml 200" \
	"/$TEST/snapshot.xml 200"
check_rsync_requests # None

check_fort_cache 0 2
check_fort_cache_file "https://localhost:8443/$TEST/ta.cer"
check_fort_cache_cage_begin "https://localhost:8443/$TEST/notification.xml"
check_fort_cache_rrdp_step "1" "1" \
	"ta/1.roa" "ta/ta.crl" "ta/ta.mft"
check_fort_cache_rrdp_fallback "1" "rsync://localhost:8873/rpki/$TEST/ta/ta.mft" \
	"ta/1.roa" "ta/ta.crl" "ta/ta.mft"
check_fort_cache_cage_end

# Step 2 ("Phase 1" in the bug report)

new_step
create_delta "rd2"
# Back up the RRDP XMLs for the next cycle
mkdir -p "sandbox/tmp"
cp "$APACHEDIR/notification.xml" "sandbox/tmp/notification.xml.bkp"
cp "$APACHEDIR/snapshot.xml" "sandbox/tmp/snapshot.xml.bkp"
mv "$APACHEDIR/delta-rd2.xml" "sandbox/tmp/delta-rd2.xml.bkp"
# Remove the delta
sed -i"" 's#<delta .*/>##g' "$APACHEDIR/notification.xml"
# Break the snapshot's hash
sed -i"" 's/hash=".*"/hash="aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"/' "$APACHEDIR/notification.xml"

run_rp --rsync.enabled=false
# Snapshot downloaded but rejected, fallback used
check_vrps "1.1.1.0/24-24 => AS64501"
check_http_requests \
	"/$TEST/ta.cer 304" \
	"/$TEST/notification.xml 200" \
	"/$TEST/snapshot.xml 200"
check_rsync_requests # None
check_logfile fort2 -F "TRE: https://localhost:8443/$TEST/snapshot.xml: Snapshot 'https://localhost:8443/$TEST/snapshot.xml' does not match its expected hash."

check_fort_cache 0 2
check_fort_cache_file "https://localhost:8443/$TEST/ta.cer"
check_fort_cache_cage_begin "https://localhost:8443/$TEST/notification.xml"
# The snapshot blew up; Fort throws away the steps, but preserves the fallback,
# since it still works.
check_fort_cache_rrdp_fallback "1" "rsync://localhost:8873/rpki/$TEST/ta/ta.mft" \
	"ta/1.roa" "ta/ta.crl" "ta/ta.mft"
check_fort_cache_cage_end

# Step 3 ("Phase 2" in the bug report)

new_step
# Restore RRDP XMLs for Barry
cp "sandbox/tmp/notification.xml.bkp" "$APACHEDIR/notification.xml"
cp "sandbox/tmp/snapshot.xml.bkp" "$APACHEDIR/snapshot.xml"
mv "sandbox/tmp/delta-rd2.xml.bkp" "$APACHEDIR/delta-rd2.xml"
create_delta "rd3" # Barry
# Remove the deltas
sed -i"" 's#<delta .*/>##g' "$APACHEDIR/notification.xml"
rm "$APACHEDIR"/delta-*.xml

run_rp --rsync.enabled=false
check_http_requests \
	"/$TEST/ta.cer 304" \
	"/$TEST/notification.xml 200" \
	"/$TEST/snapshot.xml 200"
check_rsync_requests # None
check_vrps "1.3.3.0/24-24 => AS64503"

check_fort_cache 0 2
check_fort_cache_file "https://localhost:8443/$TEST/ta.cer"
check_fort_cache_cage_begin "https://localhost:8443/$TEST/notification.xml"
check_fort_cache_rrdp_step "1" "2" \
	"ta/3.roa" "ta/ta.crl" "ta/ta.mft"
check_fort_cache_rrdp_fallback "1" "rsync://localhost:8873/rpki/$TEST/ta/ta.mft" \
	"ta/3.roa" "ta/ta.crl" "ta/ta.mft"
check_fort_cache_cage_end
