#!/bin/sh

. tools/checks.sh
. rp/$RP.sh


PROVIDERS=4001
FILE_RD="tests/$CATEGORY/$TEST/rd"

echo "ta.cer" > "$FILE_RD"
echo "\tca.cer" >> "$FILE_RD"
echo "\t\taspa.asa" >> "$FILE_RD"
echo "\n" >> "$FILE_RD"
echo "[node: aspa.asa]" >> "$FILE_RD"
echo "obj.content.encapContentInfo.eContent.providers = [" >> "$FILE_RD"
seq 1 $PROVIDERS | awk '{ print "\t" $1 "," }' >> "$FILE_RD"
echo "]" >> "$FILE_RD"

run_barry
run_rp

check_logfile fort1 -F "Too many providers: $PROVIDERS > 4000"

check_vrps
check_aspas

stop_rp