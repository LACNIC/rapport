#!/bin/sh

. tools/checks.sh

# --- Settings ---
RPKI_DIR="/tmp/rpki"
TAL_DIR="$RPKI_DIR/tals"
CACHE_ROUTINATOR="$RPKI_DIR/cache-routinator"
CACHE_FORT="$RPKI_DIR/cache-fort"
RESULTS_DIR="$SANDBOX/results"

OUT_ROUTINATOR="$RESULTS_DIR/routinator-mixed.txt"
OUT_VRPS_ROUTINATOR="$RESULTS_DIR/routinator-vrps.txt.sorted"
OUT_ASPA_ROUTINATOR="$RESULTS_DIR/routinator-aspas.txt.sorted"

OUT_VRPS_FORT="$RESULTS_DIR/fort-vrps.txt"
OUT_ASPA_FORT="$RESULTS_DIR/fort-aspas.txt"

DIFF_VRPS_FILE="$RESULTS_DIR/fort-vs-routinator-vrps.diff"
DIFF_ASPA_FILE="$RESULTS_DIR/fort-vs-routinator-aspas.diff"

mkdir -p "$TAL_DIR"
mkdir -p "$CACHE_ROUTINATOR"
mkdir -p "$CACHE_FORT"
mkdir -p "$RESULTS_DIR"

rm -rf "$CACHE_ROUTINATOR"/*
rm -rf "$CACHE_FORT"/*
rm -f "$RESULTS_DIR"/*


echo "==========================================="
echo " Benchmarking Analysis: FORT vs Routinator "
echo "==========================================="

echo "[*] Getting RPKI TAs..."
fort --init-tals --tal "$TAL_DIR" > /dev/null 2>&1

# Executing Routinator
start_routinator=$(date +%s)
routinator --enable-aspa --fresh --repository-dir "$CACHE_ROUTINATOR" vrps --format json > "$OUT_ROUTINATOR" 2>/dev/null &
PID_ROUTINATOR=$!

# Executing FORT
start_fort=$(date +%s)
fort --mode standalone --local-repository "$CACHE_FORT" --tal "$TAL_DIR" --output.roa "$OUT_VRPS_FORT" --output.aspa "$OUT_ASPA_FORT" 2>/dev/null &
PID_FORT=$!

echo "[*] Validators running in parallel..."

# Synchronization and measurement
wait $PID_ROUTINATOR
end_routinator=$(date +%s)
runtime_routinator=$((end_routinator - start_routinator))

wait $PID_FORT
end_fort=$(date +%s)
runtime_fort=$((end_fort - start_fort))

echo "---------------------------------------------------------"
echo " EXECUTION TIME RESULTS"
echo "---------------------------------------------------------"
printf "FORT:       %s seconds\n" "$runtime_fort"
printf "Routinator: %s seconds\n" "$runtime_routinator"


# Asymmetric Normalization
echo "---------------------------------------------------------"
echo "[*] Normalizing outputs for comparison..."

# We separate, normalize, and sort Routinator output
normalize_routinator_data "$OUT_ROUTINATOR" "$OUT_VRPS_ROUTINATOR" "$OUT_ASPA_ROUTINATOR"

# We clean FORT files
normalize_fort_vrps_file "$OUT_VRPS_FORT" "$OUT_VRPS_FORT.sorted"
normalize_fort_aspa_file "$OUT_ASPA_FORT" "$OUT_ASPA_FORT.sorted"


# Parity Report
count_vrps_routinator=$(wc -l < "$OUT_VRPS_ROUTINATOR")
count_vrps_fort=$(wc -l < "$OUT_VRPS_FORT.sorted")
echo "VRPs (Routinator): $count_vrps_routinator"
echo "VRPs (FORT): $count_vrps_fort"

count_aspa_routinator=$(wc -l < "$OUT_ASPA_ROUTINATOR")
count_aspa_fort=$(wc -l < "$OUT_ASPA_FORT.sorted")
echo "ASPAs (Routinator): $count_aspa_routinator"
echo "ASPAs (FORT): $count_aspa_fort"

echo "---------------------------------------------------------"

if diff -q "$OUT_VRPS_ROUTINATOR" "$OUT_VRPS_FORT.sorted" > /dev/null; then
    echo "VRPs RESULT: Total parity confirmed (100% identical)."
else
    
    diff -u "$OUT_VRPS_ROUTINATOR" "$OUT_VRPS_FORT.sorted" > "$DIFF_VRPS_FILE"
    echo "VRPs RESULT: WARNING: Discrepancies were detected."
    echo "See: $DIFF_VRPS_FILE"
fi

if diff -q "$OUT_ASPA_ROUTINATOR" "$OUT_ASPA_FORT.sorted" > /dev/null; then
    echo "ASPAs RESULT: Total parity confirmed (100% identical)."
else
    
    diff -u "$OUT_ASPA_ROUTINATOR" "$OUT_ASPA_FORT.sorted" > "$DIFF_ASPA_FILE"
    echo "ASPAs RESULT: WARNING: Discrepancies were detected."
    echo "See: $DIFF_ASPA_FILE"
fi

echo "========================================================="