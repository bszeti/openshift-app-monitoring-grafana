#!/bin/bash

TOKEN=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)

if [ -e /var/run/secrets/tokens/thanos-token]; then
    TOKEN=$(cat /var/run/secrets/tokens/thanos-token)
fi

PATCH="[{\"op\": \"replace\", \"path\":\"/spec/datasources/0/secureJsonData/httpHeaderValue1\", \"value\": \"Bearer ${TOKEN}\"}]"

set +x
oc patch grafanadatasources thanos -n $(cat /run/secrets/kubernetes.io/serviceaccount/namespace) --type json --patch "${PATCH}"