#!/bin/sh

# Issue #119 -- AIA caIssuers: very long URI (potential buffer overflow)
#
# RFC 3986 does not define a maximum URI length, but implementations are
# expected to handle or reject excessively long values gracefully. A
# malicious certificate could embed a caRepository URI of arbitrary length
# since the field is an IA5String with no explicit upper bound enforced by
# the ASN.1 definition in RFC 6487.

. tools/checks.sh
. rp/$RP.sh

FILE_RD="$SRCDIR/rd"

# Write the rd file in segments. The long URI segment is piped directly
# to the file so it never enters a shell variable or execve() argument.
printf 'ta.cer\n' > "$FILE_RD"
printf '\tca.cer\n' >> "$FILE_RD"
printf '\t\troute.roa\n' >> "$FILE_RD"
printf '\t\tca.mft\n' >> "$FILE_RD"
printf '\t\tca.crl\n' >> "$FILE_RD"
printf '\tta.mft\n' >> "$FILE_RD"
printf '\tta.crl\n' >> "$FILE_RD"
printf '\n' >> "$FILE_RD"
printf '[node: route.roa]\n' >> "$FILE_RD"
printf 'obj.content.encapContentInfo.eContent.ipAddrBlocks = [ 1.1.0.0/24 ]\n' >> "$FILE_RD"
printf 'obj.content.encapContentInfo.eContent.asId = 64512\n' >> "$FILE_RD"
printf '\n' >> "$FILE_RD"
printf '[node: ca.cer]\n' >> "$FILE_RD"
printf 'obj.tbsCertificate.extensions.aia.extnValue.0.accessLocation.value = rsync://localhost:8873/rpki/%s/' \
    "$TEST" >> "$FILE_RD"
head -c 65536 /dev/zero | tr '\0' 'A' >> "$FILE_RD"
printf '\n' >> "$FILE_RD"

run_barry
run_rp

check_vrps

check_logfile fort1 -E "Unable to concatenate '[^']*' \(might be truncated\) to path '[^']*': Path too long \([0-9]+ > 4096\)"
