#!/bin/sh

# Run the validation of the rpki repositories RIRs. 
# $1: Path where the local repository will be stored
# $2: Path of the output file with VRPs
# $3: Path of the output file with ASPAs
run_fort_validation_for_rir_tals() {
	TAL_DIR="$SANDBOX/tals"
	mkdir -p "$TAL_DIR"

	fort --init-tals --tal "$SANDBOX/tals" > /dev/null 2>&1

	start_time=$(date +%s)
	fort \
		--mode "standalone" \
		--tal "$SANDBOX/tals" \
		--local-repository "$1" \
		--output.roa "$2" \
		--output.aspa "$3" 2>/dev/null
	end_time=$(date +%s)
	printf "FORT execution time:       %s seconds\n" "$((end_time - start_time))"
}

# Run the validation of the rpki repositories RIRs. 
# $1: Path where the local repository will be stored
# $2: Path of the output file (including VRPs and ASPAs)
run_routinator_validation_for_rir_tals() {
	start_time=$(date +%s)
	routinator \
		--enable-aspa \
		--fresh \
		--repository-dir "$1" \
		vrps --format json > "$2" 2>/dev/null
	end_time=$(date +%s)
	printf "Routinator execution time:       %s seconds\n" "$((end_time - start_time))"
}

# Divides the Routinator output file into VPRs file and ASPA file, 
# normalizes them, and sorts them so they can be compared.
# $1: Original Routinator file
# $2: VPRs file (normalized and sorted)
# $3: ASPA file (normalized and sorted)
normalize_routinator_data() {
    input_file="$1"
    vrps_output="$2"
    aspa_output="$3"

    grep '^[[:space:]]*{ "asn":' "$input_file" | \
    sed 's/[[:space:]]//g; s/{"asn":"//; s/","prefix":"/,/; s/","maxLength":/,/; s/,"ta":.*//' | \
    sort -V > "$vrps_output"

	grep '{.*"customer":' $input_file | \
	sed 's/[[:space:]]//g; s/.*"customer":"AS//; s/","providers":\["AS/ /; s/","AS/ /g; s/"\],"ta":.*//' | \
	awk '{ printf "\"%s\": [ ", $1; for(i=2; i<=NF; i++) printf "%s%s", $i, (i==NF ? "" : ", "); print " ]" }' | \
	sort -V > "$aspa_output"
}

# Normalize a VPRS output file from FORT in order to be compared.
# $1: Original VRPs file
# $2: Normalized file
normalize_fort_vrps_file() {
    input="$1"
    output="$2"

    # Fort: Skip header and sort
    tail -n +2 "$input" | sort -V > "$output"
}

# Normalize a ASPA output file from Fort in order to be compared.
# $1: Original VRPs file
# $2: Normalized file
normalize_fort_aspa_file() {
    input="$1"
    output="$2"

    # Explanation of the sed command:
    # 1d -> Removes the first line.
    # $d -> Removes the last line ($ represents the end).
    # s/^[[:space:]]*// -> Removes leading spaces or tabs (^) from each line.
    # s/,$// -> Removes the trailing comma (,) ($) from the line.
    sed -e '1d' -e '$d' -e 's/^[[:space:]]*//' -e 's/,$//' "$input" | sort -V > "$output"
}

check_parity () {
	file_name=$(printf "%s%s" "$2" "$4" | tr -d ' ' | tr '[:upper:]' '[:lower:]')
	DIFF_FILE="$SANDBOX/results/$file_name.diff"

	count_elements_file_rp1=$(wc -l < "$1")
	count_elements_file_rp2=$(wc -l < "$3")
	echo "$2: $count_elements_file_rp1"
	echo "$4: $count_elements_file_rp2"

	if diff -q "$1" "$3" > /dev/null; then
    	echo "RESULT: Total parity confirmed (100% identical)."
	else
    	diff -u "$1" "$3" > "$DIFF_FILE"
    	echo "RESULT: WARNING: Discrepancies were detected."
    	echo "See: $DIFF_FILE"
	fi
}