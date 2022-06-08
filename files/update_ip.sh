#! /bin/sh

IP_REGEX='((1?[0-9][0-9]?|2[0-4][0-9]|25[0-5])\.){3}(1?[0-9][0-9]?|2[0-4][0-9]|25[0-5])'

# Get current server IP address
echo "Getting current server IP address..."
CURRENT_IP=\"$(host "$DDNS_HOSTNAME"."$DDNS_DOMAIN" | grep -oE "$IP_REGEX")\"


# Get current DNS A record
echo "Gettting current DNS A record..."
CURRENT_A_RECORD_RESPONSE=$(curl -X GET "$DNS_API_DOMAIN/zones/$DNS_API_ZONE_ID/dns_records/$DNS_API_RECORD_ID" \
     -H "Authorization: Bearer $DNS_API_ACCESS_TOKEN" \
     -H "Content-Type:application/json")


if [ "$(echo "$CURRENT_A_RECORD_RESPONSE" | jq ".success")" = "true" ]
then
    CURRENT_A_RECORD=$(echo "$CURRENT_A_RECORD_RESPONSE" | jq  ".result.content")
fi


# Update current DNS A record
if [ "$CURRENT_IP" != "$CURRENT_A_RECORD" ]
then
    echo "Current DNS A record ($CURRENT_A_RECORD) does not match current IP ($CURRENT_IP)"
    echo "Updating DNS A record..."

    PATCH_RESPONSE=$(curl -X PATCH "$DNS_API_DOMAIN/zones/$DNS_API_ZONE_ID/dns_records/$DNS_API_RECORD_ID" \
     -H "Authorization: Bearer $DNS_API_ACCESS_TOKEN" \
     -H "Content-Type:application/json" \
     --data "{\"content\":$CURRENT_IP}")

    if [ "$(echo "$PATCH_RESPONSE" | jq ".success")" = "true" ]
    then
        echo "DNS A record updated sucessfully"
    else
        echo "DNS A record update failed"
        echo "$PATCH_RESPONSE"
    fi
else
    echo "Current A record ($CURRENT_A_RECORD) is correct"
fi
