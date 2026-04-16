#!/bin/sh

. tools/checks.sh

bird_validate_aspa() {
    table="aspa_table"
    errors=0
    LOG_DIR="$SANDBOX/log"
    LOG_FILE="$LOG_DIR/bird_${table}_validation.log"

    mkdir -p "$LOG_DIR"

    # Retrieve the table output only once to be efficient.
    bird_output=$(birdc show route table "$table" all)

    {
        while [ "$#" -gt 0 ]; do
            input="$1"
            
            # Parse the input "customer:[p1, p2]"
            # Extract Customer (what comes before the colon)
            customer=$(echo "$input" | cut -d':' -f1)
            # Extract Providers and clean brackets and commas
            expected_provs=$(echo "$input" | cut -d'[' -f2 | tr -d '],')

            # Extract the provider for that Customer from the BIRD output
            # We search for the Customer line and obtain the following line containing aspa_providers
            actual_provs=$(echo "$bird_output" | \
                grep -A 3 "^$customer " | \
                grep "aspa_providers:" | \
                sed 's/.*aspa_providers: //')

            # Comparison
            # We normalize spacing to avoid indentation errors
            expected_norm=$(echo $expected_provs)
            actual_norm=$(echo $actual_provs)

            if [ -n "$actual_norm" ] && [ "$expected_norm" = "$actual_norm" ]; then
                echo "[OK] Found ASPA: Customer $customer with providers [$actual_norm]"
            else
                echo "[ERROR] Not found ASPA: Expected $customer:[$expected_norm], but found [$actual_norm]"
                errors=$((errors + 1))
            fi

            shift 1
        done
    } >> "$LOG_FILE"

    if [ "$errors" -eq 0 ]; then
        return 0
    else
        fail "ASPA validation failed. See: $LOG_FILE"
    fi
}

bird_validate_prefixes() {
    table="$1"
    shift 1
    errors=0
    LOG_DIR="$SANDBOX/log"
    LOG_FILE="$LOG_DIR/bird_${table}_validation.log"

    mkdir -p "$LOG_DIR"

    # Retrieve the table output only once to be efficient.
    bird_output=$(birdc show route table "$table")

    ck_inc
    {
        while [ "$#" -gt 0 ]; do
            ip="$1"
            len="$2"
            maxlen="$3"
            as="$4"

            # We construct the exact pattern: "1.2.0.0/16-16 AS1234"
            pattern="${ip}/${len}-${maxlen} AS${as}"

            # We look for the pattern in the saved output
            if printf "%s\n" "$bird_output" | grep -qF "$pattern"; then
                echo "[OK] Found: $pattern in $table"
            else
                echo "[ERROR] Not found: $pattern in $table"
                errors=$((errors + 1))
            fi

            # We shift the arguments 4 positions to the next group
            shift 4
        done
    } >> "$LOG_FILE"

    if [ "$errors" -eq 0 ]; then
        return 0
    else
        fail "Some prefixes were not found in the BIRD table. See: $LOG_FILE"
    fi
}

bird_validate_ipv4_prefixes() {
    bird_validate_prefixes "ipv4_prefix_table" "$@"
}

bird_validate_ipv6_prefixes() {
    bird_validate_prefixes "ipv6_prefix_table" "$@"
}

bird_start() {
    CONFIG_FILE="router/bird.conf"
    socket="/run/bird/bird.ctl"

    # We start the process by loading the configuration
    bird -c "$CONFIG_FILE"

    # 2. Wait for the socket to be created and respond
    timeout=15
    connected=1
    
    while [ "$timeout" -gt 0 ]; do
        # Intentamos un comando simple para ver si el socket responde
        if birdc show status > /dev/null 2>&1; then
            connected=0
            break
        fi
        sleep 1
        timeout=$((timeout - 1))
    done

    if [ "$connected" -ne 0 ]; then
        fail "BIRD failed to start or socket $socket is unreachable after 15s."
    fi

    # 3. Force the refresh now that we know the socket is ready
    birdc restart my_rpki > /dev/null

    # 4. Additional wait for the initial data load from the RTR cache
    sleep 2
}

bird_stop() {
    socket="/run/bird/bird.ctl"

    if [ -S "$socket" ]; then
        birdc down > /dev/null
        
        # Wait for the process to finish
        timeout=5
        while [ -S "$socket" ] && [ "$timeout" -gt 0 ]; do
            sleep 1
            timeout=$((timeout - 1))
        done
    fi
}