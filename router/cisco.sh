#!/bin/sh

. tools/checks.sh

cisco_send_cmd() {
    printf "%b\r" "$1" | nc -w 1 localhost 5000 > /dev/null
}

cisco_get_output() {
    printf "%b\r" "$1" | nc -w 3 localhost 5000 | tr -cd '[:print:]\n'
}

cisco_validate_prefix() {
    PREFIX_VERSION="$1"
    CMD="$2"
    shift 2
    LOG_DIR="$SANDBOX/log"
    LOG_FILE="$LOG_DIR/cisco_${PREFIX_VERSION}_prefix_validation.log"

    mkdir -p "$LOG_DIR"

    #echo "[*] Getting RPKI ${PREFIX_VERSION} data..."

    TABLE=$(cisco_get_output "$CMD")
    
    # Basic verification that we received data
    if ! echo "$TABLE" | grep -q "Network"; then
        fail "[ERROR] The prefix table could not be read (Cisco offline?)"
    fi
    
    FAILED=0

    ck_inc
    # Retrieve the table output only once to be efficient.
    {
        while [ "$#" -gt 0 ]; do
            NET="$1"
            MASK="$2"
            MLEN="$3"
            AS="$4"

            PATTERN="${NET}/${MASK}[[:space:]]*${MLEN}[[:space:]]*${AS}"

            if echo "$TABLE" | grep -qE "$PATTERN"; then
                echo "[OK] Found: ${NET}/${MASK} (Max: ${MLEN}, AS: ${AS})"
            else
                echo "[ERROR] Not found: ${NET}/${MASK} (Max: ${MLEN}, AS: ${AS})"
                FAILED=$((FAILED + 1))
            fi

            shift 4
        done
    } >> "$LOG_FILE"

    if [ "$FAILED" -eq 0 ]; then
        return 0
    else
        fail "Some prefixes were not found in the Cisco table. See: $LOG_FILE"
    fi
}

cisco_validate_ipv4_prefix(){
    cisco_validate_prefix "ipv4" "show ip bgp rpki table" "$@"
}

cisco_validate_ipv6_prefix(){
    cisco_validate_prefix "ipv6" "show bgp ipv6 rpki table" "$@"
}

cisco_start() {
    #CISCO_IMAGE="router/csr1000v-universalk9.16.6.1.qcow2"
    BRIDGE="br-lab"
    RTR_SERVER_IP="10.0.0.1"       # IP of br-lab interface
    ROUTER_IP="10.0.0.2"     # IP address that we will assign to the Cisco
    NETMASK="255.255.255.0"
    CONSOLE_PORT=5000


    if [ -z "$CISCO_IMAGE" ]; then
        fail "[ERROR] CISCO_IMAGE is not defined or empty. Execution aborted."
    fi
    #echo "[*] Starting CSR1000v..."

    # Optimizations applied:
    # -cpu host: Uses the native instructions of your Intel/NVIDIA processor.
    # -smp 4: Distributes the load across 4 cores to speed up boot times.
    # cache=writeback: Speeds up disk access (like GNS3).
    kvm -m 4096 \
        -cpu host,migratable=off,+invtsc \
        -smp 4,sockets=1,cores=4,threads=1 \
        -netdev bridge,id=net0,br=$BRIDGE \
        -device virtio-net-pci,netdev=net0 \
        -drive file="$CISCO_IMAGE",if=virtio,cache=writeback,format=qcow2 \
        -nographic \
        -nodefaults \
        -serial telnet:localhost:$CONSOLE_PORT,server,nowait 2>/dev/null &
    export CISCO_PID=$!

    # Wait for the console port to become available
    while ! nc -z localhost $CONSOLE_PORT 2>/dev/null; do
        sleep 2
    done
 
    #echo "[*] Monitoring boot process..."

    while true; do
        # WE SEND ENTER TO WAKE UP THE CONSOLE
        # We send an Enter key (\r) and capture the clean response all at once.
        CLEAN_DATA=$(printf "\r" | nc -w 2 localhost $CONSOLE_PORT | tr -cd '[:print:]\n')

        if echo "$CLEAN_DATA" | grep -qi "Router>" || echo "$CLEAN_DATA" | grep -qi "Router#"; then
            #echo "\n[*] Prompt detected."
            #echo "[*] Setting Cisco CSR1000v Router..."
        
            cisco_send_cmd "enable"
            cisco_send_cmd "configure terminal"
        
            # Disable services that generate noise in the logs
            cisco_send_cmd "no service config"
            cisco_send_cmd "no ip domain-lookup"
        
            # Configuration of the interface connected to br-lab
            cisco_send_cmd "interface GigabitEthernet1"
            cisco_send_cmd "ip address $ROUTER_IP $NETMASK"
            cisco_send_cmd "no shutdown"
            cisco_send_cmd "exit"
        
            # COnfiguration of the RTR Server
            cisco_send_cmd "router bgp 65000"
            cisco_send_cmd "bgp rpki server tcp $RTR_SERVER_IP port 8323 refresh 30"
            cisco_send_cmd "exit"
        
            # Save the image as .qcow2 so that the next startup is instant.
            cisco_send_cmd "do write memory"
            cisco_send_cmd "end"
        
            break
        fi

        # Visual feedback to know that the script is still processing
        #printf "."
        sleep 3
    done

    #echo "[*] Cisco started."
}

cisco_stop() {
    if [ -z "$CISCO_PID" ]; then
        echo "[ERROR] Cisco PID not found."
        return 1
    fi
    
    # Try to end the process smoothly
    kill "$CISCO_PID" 2>/dev/null
    
    # Wait a moment and check if it's still alive before forcing it
    sleep 2
    if kill -0 "$CISCO_PID" 2>/dev/null; then
        echo "[WARN] Process not stopped, running kill -9..."
        kill -9 "$CISCO_PID" 2>/dev/null
    fi

    CISCO_PID=""
    return 0
}