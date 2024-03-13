#!/bin/bash

HOST="test.example.com"
TCP_PORT="PORTNR"
# Cloudflare API details
API_TOKEN="CLOUDFLARE_API_TOKEN"
ZONE_ID="CLOUDFLARE_ZONE_ID"
DNS_RECORD="DNS_RECORD"
PROD_IP="ORIGINAL_IP"
BACKUP_IP="BACKUP_IP"
#Status file determing latest state
STATUS_FILE="./status.txt"
CURRENT_STATUS=$(cat "$STATUS_FILE")
DNS_RECORD_ID=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records?type=A&name=$DNSRECORD" \
        -H "Authorization: Bearer $API_TOKEN" \
        -H "Content-Type: application/json" | jq -r '{"result"}[] | .[0] | .id')
DNS_CONTENT=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records?type=A&name=$DNSRECORD" \
       -H "Authorization: Bearer $API_TOKEN" \
       -H "Content-Type: application/json"| jq -r '{"result"}[] | .[0] | .content')
CURRENT_RECORD=$(echo "$DNS_CONTENT")
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
    local NEW_STATUS="$1"
    echo "$NEW_STATUS" > "$STATUS_FILE"
    echo "Status set to: $NEW_STATUS"
}

previous_status=$(get_previous_status)
echo "Previous status: $previous_status"

# Assume you've determined the current status (e.g., from an external source)
CURRENT_STATUS="PROD"
FAILED_STATUS="BACKUP"

#------Debug-------
#Uncomment to check status of dns record ID
#echo "DNS_RECORD_ID for $DNS_RECORD is $DNS_RECORD_ID"
#----end Debug------
# Check TCP port availability
if netcat -v -w 3 "$HOST" "$TCP_PORT" &> /dev/null; then
        echo "TCP port $TCP_PORT for $HOST is reachable."
        echo "PROD" > "$STATUS_FILE"
        if [ "$CURRENT_STATUS" != "$previous_status" ]; then
                if netcat -v -w 3 "$HOST" "$TCP_PORT" &> /dev/null; then
                        echo "Status has changed. Updating DNS record to PROD..."
                        # Update DNS record to point to the desired destination
                        curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records/$DNS_RECORD_ID" \
                        -H "Authorization: Bearer $API_TOKEN" \
                        -H "Content-Type: application/json" \
                        --data "{\"type\":\"A\",\"name\":\"$DNS_RECORD\",\"content\":\"$PROD_IP\",\"ttl\":1,\"proxied\":false}" | jq
                        set_current_status "$CURRENT_STATUS"
                fi
        fi

else
#       echo "TCP port $TCP_PORT for $HOST is unreachable."
        echo "BACKUP" > "$STATUS_FILE"

# Check if the current status value has changed
        if [ "$CURRENT_STATUS" != "$previous_status" ]; then
                if netcat -v -w 3 "$HOST" "$TCP_PORT" &> /dev/null; then
                        echo "Status has changed. Updating DNS record to PROD..."
                        # Update DNS record to point to the desired destination
                        curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records/$DNS_RECORD_ID" \
                        -H "Authorization: Bearer $API_TOKEN" \
                        -H "Content-Type: application/json" \
                        --data "{\"type\":\"A\",\"name\":\"$DNS_RECORD\",\"content\":\"$PROD_IP\",\"ttl\":1,\"proxied\":false}" | jq
                        set_current_status "$CURRENT_STATUS"
                else
                        if [ "$CURRENT_RECORD" == "$BACKUP_IP" ]; then
                                echo "not changing record"
                        else
                                echo "Status has changed. Updating DNS record to BACKUP"
                                echo "TCP port $TCP_PORT is unreachable."
                                # Update DNS record to point to an alternate IP
                                curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records/$DNS_RECORD_ID" \
                                -H "Authorization: Bearer $API_TOKEN" \
                                -H "Content-Type: application/json" \
                                --data "{\"type\":\"A\",\"name\":\"$DNS_RECORD\",\"content\":\"$BACKUP_IP\",\"ttl\":1,\"proxied\":false}" | jq
                                set_current_status "$FAILED_STATUS"
                        fi
                fi
        fi
fi

