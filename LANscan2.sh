#!/bin/bash

# IP check function
check_ip() {
    local ip="$1"
    ping -c 1 -W 1 "$ip" >/dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo "$ip is available."
        local mac_address=$(ip neigh show | grep "$ip" | awk '{print $5}')
        if [ -n "$mac_address" ]; then
            echo "Mac address for $ip: $mac_address"
        fi
    fi
}

main() {
    local network_range="$1"
    local max_processes="$2"
    
    # Validating network range in the format 0-9{3}+octet
    if ! [[ "$network_range" =~ ^([0-9]+\.){3}[0-9]+$ ]]; then
        echo "NOT a valid network range. Specify in the format 'x.x.x.x'." >&2
        exit 1
    fi

    # Get the last octet of the given IP address
    local last_octet=$(echo "$network_range" | awk -F '.' '{print $4}')

    # Generate IPs in the given range
    for i in {1..255}; do
        local ip="${network_range%.*}.$((last_octet + i))"
        check_ip "$ip" &
        # Wait if the number of processes reaches the upper limit
        local num_processes=$(jobs -p | wc -l)
        if [ "$num_processes" -ge "$max_processes" ]; then
            wait -n
        fi
    done
    wait
}

# Input validation
if [ "$#" -ne 1 ] && [ "$#" -ne 2 ]; then
    echo "To use, type: $0 <local_network_range> [max_processes]" >&2
    exit 1
fi

network_range="$1"
max_processes="${2:-10}"  # Upper limit for scanning, network_range is globally defined

main "$network_range" "$max_processes"

