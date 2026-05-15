#!/bin/sh

. tools/checks.sh
. rp/$RP.sh

ASID="16842752"
PROVIDERS=3999
FILE_RD="tests/$CATEGORY/$TEST/rd"

ASPA=$(awk -v id="$ASID" -v n="$PROVIDERS" 'BEGIN {
    printf "%s:[", id
    for (i=1; i<=n; i++) {
        printf "%s%s", i, (i==n ? "" : ",")
    }
    print "]"
}')

#printf "%s\n" "$ASPA"

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

check_vrps
check_aspas $ASPA 

stop_rp