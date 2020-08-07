#!/bin/sh
curl -s -X GET "https://merchant-api.flexbooker.com/Account" -H "accept: application/json" -H "Authorization: Bearer $1" | jq .
