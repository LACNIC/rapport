#!/bin/sh

. tools/benchmk.sh

RPKI_DIR="/tmp/rpki"
CACHE_ROUTINATOR="$RPKI_DIR/cache-routinator"
CACHE_FORT="$RPKI_DIR/cache-fort"
RESULTS_DIR="$SANDBOX/results"

mkdir -p "$CACHE_ROUTINATOR"
mkdir -p "$CACHE_FORT"
mkdir -p "$RESULTS_DIR"

rm -rf "$CACHE_ROUTINATOR"/*
rm -rf "$CACHE_FORT"/*
rm -f "$RESULTS_DIR"/*

# Validators running in parallel
run_fort_validation_for_rir_tals "$CACHE_FORT" "$RESULTS_DIR/fort-vrps.txt" "$RESULTS_DIR/fort-aspa.txt" &
PID_FORT=$!

run_routinator_validation_for_rir_tals "$CACHE_ROUTINATOR" "$RESULTS_DIR/routinator-mixed.txt" &
PID_ROUTINATOR=$!

wait $PID_FORT $PID_ROUTINATOR

# Normilizing outputs for comparition
normalize_routinator_data \
    "$RESULTS_DIR/routinator-mixed.txt" \
    "$RESULTS_DIR/routinator-vrps.sorted" \
    "$RESULTS_DIR/routinator-aspa.sorted"

normalize_fort_vrps_file \
    "$RESULTS_DIR/fort-vrps.txt" \
    "$RESULTS_DIR/fort-vrps.sorted"

normalize_fort_aspa_file \
    "$RESULTS_DIR/fort-aspa.txt" \
    "$RESULTS_DIR/fort-aspa.sorted"

# Generating parity report
check_parity \
    "$RESULTS_DIR/fort-vrps.sorted" "VPRs FORT" \
    "$RESULTS_DIR/routinator-vrps.sorted" "VPRs Routinator"
check_parity \
    "$RESULTS_DIR/fort-aspa.sorted" "ASPAs FORT" \
    "$RESULTS_DIR/routinator-aspa.sorted" "ASPAs Routinator"