#!/bin/sh

CLIENT_SECRET=$1

curl -s --location --request POST 'https://auth.flexbooker.com/connect/token' \
--form 'grant_type=client_credentials' \
--form 'scope=flexbookerApi' \
--form 'client_id=pubmob' \
--form "client_secret=$CLIENT_SECRET" | jq .access_token

