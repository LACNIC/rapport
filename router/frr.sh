#!/bin/sh

. tools/checks.sh

frr_validate_prefix_table () {
    # We capture the table only once to avoid multiple calls to vtysh
    table=$(vtysh -c "show rpki prefix-table")
    failed=0
    LOG_DIR="$SANDBOX/log"
    LOG_FILE="$LOG_DIR/frr_prefix_validation.log"

    mkdir -p "$LOG_DIR"

    ck_inc
    {
        # Process the arguments in blocks of 4
        while [ "$#" -ge 4 ]; do
            ip="$1"
            len="$2"
            max="$3"
            as="$4"

            # We constructed a pattern that searches for the IP address, range, and AS on the same line.
            # Pattern explanation:
            # 1. Search for the IP address.
            # 2. Followed by spaces, then the format "LEN - MAX".
            # 3. Followed by spaces and the AS.
            if echo "$table" | grep -Eq "^$ip +$len - +$max +$as$"; then
                echo "[OK] Found: $ip | Range: $len-$max | AS: $as"
            else
                # Intento de búsqueda más flexible si los espacios varían
                if echo "$table" | grep -F "$ip" | grep -q "$len - $max.*$as"; then
                    echo "[OK] Found: $ip | Range: $len-$max | AS: $as"
                else
                    echo "[ERROR] Not found: $ip | Range: $len-$max | AS: $as"
                    failed=$(($failed + 1))
                fi
            fi

            # Shift 4 positions to read the next prefix
            shift 4
        done
    } >> "$LOG_FILE"

    if [ "$failed" -eq 0 ]; then
        return 0
    else
        fail "Some prefixes were not found in the FFR table. See: $LOG_FILE"
    fi
}

frr_load_and_restart () {
    CONFIG_RTR="router/frr.conf"
    cat "$CONFIG_RTR" > "/etc/frr/frr.conf"
    
    if sudo /usr/lib/frr/frrinit.sh restart >/dev/null 2>&1; then
        return 0
    else
        fail "[ERROR] FRR restart failed."
    fi
}

frr_stop () {
    if sudo /usr/lib/frr/frrinit.sh stop >/dev/null 2>&1; then
        return 0
    else
        fail "[ERROR] FRR could not be stopped."
    fi
}