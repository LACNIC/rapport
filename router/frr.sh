#!/bin/sh

. tools/checks.sh

frr_validate_prefix_table () {
    # We capture the table only once to avoid multiple calls to vtysh
    table=$(vtysh -c "show rpki prefix-table")
    failed=0
    LOG_DIR="$SANDBOX/log"
    LOG_FILE="$LOG_DIR/frr_prefix_validation.log"

    mkdir -p "$LOG_DIR"

    #echo "===>TABLE: $table"
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
    CONFIG_FILE="router/frr.conf"
    
    # Force the removal of any previous RPKI sessions in RAM
    # This ensures that the bgpd process closes old sockets.
    vtysh -c "conf t" -c "no rpki" >/dev/null 2>&1
    
    # Load the new configuration from the file
    # We remove error redirection to see if something specific is failing
    if vtysh -f "$CONFIG_FILE" >/dev/null 2>&1; then
        
        # Force manual startup (some versions require this after a 'no rpki')
        vtysh -c "rpki start" >/dev/null 2>&1
        
        # Sync to disk
        vtysh -c "write memory" >/dev/null 2>&1
        return 0
    else
        fail "[ERROR] FRR load failed."
    fi
}

frr_reset () {
    # Borrar la configuración de ruteo activa
    _as=$(vtysh -c "show running-config" | grep "router bgp" | awk '{print $3}')
    [ -n "$_as" ] && vtysh -c "conf t" -c "no router bgp $_as" >/dev/null 2>&1
    
    # Borrar RPKI específicamente
    vtysh -c "conf t" -c "no rpki" >/dev/null 2>&1
    
    # Sincronizar para que el archivo /etc/frr/frr.conf también quede limpio
    vtysh -c "write memory" >/dev/null 2>&1
    
    return 0
}

#frr_start () {
#    CONFIG_RTR="router/frr.conf"
#    cat "$CONFIG_RTR" > "/etc/frr/frr.conf"
#    
#    if sudo /usr/lib/frr/frrinit.sh start >/dev/null 2>&1; then
#        return 0
#    else
#        fail "[ERROR] FRR restart failed."
#    fi
#}

#frr_stop () {
#    if sudo /usr/lib/frr/frrinit.sh stop >/dev/null 2>&1; then
#        return 0
#    else
#        fail "[ERROR] FRR could not be stopped."
#    fi
#}