#! /bin/bash

IP_REGEX='((1?[0-9][0-9]?|2[0-4][0-9]|25[0-5])\.){3}(1?[0-9][0-9]?|2[0-4][0-9]|25[0-5])'

dns_record_request () {
    method="$1"
    dns_id="$2"
    payload="$3"

    curl -s -X "$method" "$DNS_API_DOMAIN/zones/$DNS_API_ZONE_ID/dns_records/$dns_id" \
     -H "Authorization: Bearer $DNS_API_ACCESS_TOKEN" \
     -H "Content-Type:application/json" \
     --data "$payload"
}

# Get current server IP address
echo "Getting current server IP address..."
CURRENT_IP=\"$(host "$DDNS_HOSTNAME"."$DDNS_DOMAIN" | grep -oE "$IP_REGEX")\"


# Loop through record IDs
IFS=', ' read -r -a record_ids <<< "$DNS_API_RECORD_IDS"
for record_id in "${record_ids[@]}"
do
    # Get current DNS A record
    echo "Getting current DNS A record for $record_id..."
    CURRENT_A_RECORD_RESPONSE=$(dns_record_request 'GET' "$record_id")


    if [ "$(echo "$CURRENT_A_RECORD_RESPONSE" | jq ".success")" = "true" ]
    then
        CURRENT_A_RECORD=$(echo "$CURRENT_A_RECORD_RESPONSE" | jq  ".result.content")

        # Update current DNS A record
        if [ "$CURRENT_IP" != "$CURRENT_A_RECORD" ]
        then
            echo "Current DNS A record ($CURRENT_A_RECORD) does not match current IP ($CURRENT_IP)"
            echo "Updating DNS A record for $record_id..."
            PATCH_RESPONSE=$(dns_record_request 'PATCH' "$record_id" "{\"content\":$CURRENT_IP}" )

            if [ "$(echo "$PATCH_RESPONSE" | jq ".success")" = "true" ]
            then
                echo "DNS A record updated successfully"
            else
                echo "DNS A record update failed"
                echo "$PATCH_RESPONSE"
            fi
        else
            echo "Current A record ($CURRENT_A_RECORD) is correct"
        fi
    else
        echo "DNS A record check failed"
        echo "$CURRENT_A_RECORD_RESPONSE"
    fi
done
