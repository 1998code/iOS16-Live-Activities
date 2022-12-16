#!/bin/bash

# Change all the below to your Apple Developer Account details
TEAM_ID=XXXXXXXXXX; # Your Apple Developer Team ID
TOKEN_KEY_FILE_NAME=/AUTHKEY.pem; # This is the name of the file you downloaded from the Apple Developer Portal
AUTH_KEY_ID=XXXXXXXXXXXX; # This is the key ID from the Apple Developer Portal
TOPIC=XXXXXXXXXXX.push-type.liveactivity; # This is {app bundle ID}.push-type.liveactivity
APNS_HOST_NAME=api.sandbox.push.apple.com; # Change to api.push.apple.com for production

DEVICE_TOKEN=$1;
DRIVERNAME=$2;
DELIVERYTIME=$3;
TIMESTAMP="$(date +%s)";

# test connection
# openssl s_client -connect "${APNS_HOST_NAME}":443;

JWT_ISSUE_TIME=$(date +%s);
JWT_HEADER=$(printf '{ "alg": "ES256", "kid": "%s" }' "${AUTH_KEY_ID}" | openssl base64 -e -A | tr -- '+/' '-_' | tr -d =);
JWT_CLAIMS=$(printf '{ "iss": "%s", "iat": %d }' "${TEAM_ID}" "${JWT_ISSUE_TIME}" | openssl base64 -e -A | tr -- '+/' '-_' | tr -d =);
JWT_HEADER_CLAIMS="${JWT_HEADER}.${JWT_CLAIMS}";
JWT_SIGNED_HEADER_CLAIMS=$(printf "${JWT_HEADER_CLAIMS}" | openssl dgst -binary -sha256 -sign "${TOKEN_KEY_FILE_NAME}" | openssl base64 -e -A | tr -- '+/' '-_' | tr -d =);
AUTHENTICATION_TOKEN="${JWT_HEADER}.${JWT_CLAIMS}.${JWT_SIGNED_HEADER_CLAIMS}"

rm -f payload_$1.json;
echo '{"aps": {"timestamp": '$JWT_ISSUE_TIME' , "event": "update", "content-state": {"driverName": "'$DRIVERNAME'", "estimatedDeliveryTime": '$DELIVERYTIME'}}}' >> payload_$1.json
curl -v --header "apns-topic: $TOPIC" --header "apns-push-type: liveactivity" --header "authorization: bearer $AUTHENTICATION_TOKEN" --data @payload_$1.json --http2 https://${APNS_HOST_NAME}/3/device/${DEVICE_TOKEN}
