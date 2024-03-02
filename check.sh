#!/bin/bash

HOST="test.example.com"
TCP_PORT="[PORTNR]"
# Cloudflare API details
API_TOKEN="[CLOUDFLARE_API_TOKEN]"
ZONE_ID="[CLOUDFLARE_ZONE_ID]"
dnsrecord="[DNS_RECORD]"
NEW_IP_ON_SUCCESS="[ORIGINAL_IP]"
ALTERNATE_IP_ON_FAILURE="[BACKUP_IP]"
#Status file determing latest state
STATUS_FILE="./status.txt"
current_status=$(cat "$STATUS_FILE")
dnsrecordid=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records?type=A&name=$dnsrecord" \
        -H "Authorization: Bearer $API_TOKEN" \
        -H "Content-Type: application/json" | jq -r '{"result"}[] | .[0] | .id')
dns_content=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records?type=A&name=$dnsrecord" \
       -H "Authorization: Bearer $API_TOKEN" \
       -H "Content-Type: application/json"| jq -r '{"result"}[] | .[0] | .content')
current_record=$(echo "$dns_content")
#Function to check the status file
get_previous_status() {
    if [ -f "$STATUS_FILE" ]; then
        cat "$STATUS_FILE"
    else
        echo "UNKNOWN"
    fi
}

# Function to set the current status
set_current_status() {
    local new_status="$1"
    echo "$new_status" > "$STATUS_FILE"
    echo "Status set to: $new_status"
}

previous_status=$(get_previous_status)
echo "Previous status: $previous_status"

# Assume you've determined the current status (e.g., from an external source)
current_status="PROD"
failed_status="FAILURE"

#------Debug-------
#Uncomment to check status of dns record ID
#echo "DNSrecordid for $dnsrecord is $dnsrecordid"
#----end Debug------
# Check TCP port availability
if netcat -v -w 3 "$HOST" "$TCP_PORT" &> /dev/null; then
        echo "TCP port $TCP_PORT for $HOST is reachable."
        echo "PROD" > "$STATUS_FILE"
        if [ "$current_status" != "$previous_status" ]; then
                if netcat -v -w 3 "$HOST" "$TCP_PORT" &> /dev/null; then
                        echo "Status has changed. Updating DNS record to PROD..."
                        # Update DNS record to point to the desired destination
                        curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records/$dnsrecordid" \
                        -H "Authorization: Bearer $API_TOKEN" \
                        -H "Content-Type: application/json" \
                        --data "{\"type\":\"A\",\"name\":\"$dnsrecord\",\"content\":\"$NEW_IP_ON_SUCCESS\",\"ttl\":1,\"proxied\":false}" | jq
                        set_current_status "$current_status"
                fi
        fi

else
#       echo "TCP port $TCP_PORT for $HOST is unreachable."
        echo "FAILURE" > "$STATUS_FILE"

# Check if the current status value has changed
        if [ "$current_status" != "$previous_status" ]; then
                if netcat -v -w 3 "$HOST" "$TCP_PORT" &> /dev/null; then
                        echo "Status has changed. Updating DNS record to PROD..."
                        # Update DNS record to point to the desired destination
                        curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records/$dnsrecordid" \
                        -H "Authorization: Bearer $API_TOKEN" \
                        -H "Content-Type: application/json" \
                        --data "{\"type\":\"A\",\"name\":\"$dnsrecord\",\"content\":\"$NEW_IP_ON_SUCCESS\",\"ttl\":1,\"proxied\":false}" | jq
                        set_current_status "$current_status"
                else
                        if [ "$current_record" == "$IP_ON_FAILURE" ]; then
                                echo "not changing record"
                        else
                                echo "Status has changed. Updating DNS record to BACKUP"
                                echo "TCP port $TCP_PORT is unreachable."
                                # Update DNS record to point to an alternate IP
                                curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records/$dnsrecordid" \
                                -H "Authorization: Bearer $API_TOKEN" \
                                -H "Content-Type: application/json" \
                                --data "{\"type\":\"A\",\"name\":\"$dnsrecord\",\"content\":\"$IP_ON_FAILURE\",\"ttl\":1,\"proxied\":false}" | jq
                                set_current_status "$failed_status"
                        fi
                fi
        fi
fi

