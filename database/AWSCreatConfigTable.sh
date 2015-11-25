#!/bin/bash

set -eo pipefail

REGION="us-west-2"
PREFIX="Test"
CONFIG="${PREFIX}Config"

function test-table {
    (aws --region $REGION dynamodb describe-table --table-name $1 > /dev/null 2>&1 && echo $1) || true
}

function create-table {
    aws --region $REGION dynamodb create-table --cli-input-json "$1"
}

if [ -z "$(test-table $CONFIG)" ]; then
    echo "Creating the $CONFIG table ..."
    read -r -d '' JSON <<- EOF || true
{
    "TableName": "$CONFIG",
    "AttributeDefinitions": [
        {
            "AttributeName": "key",
            "AttributeType": "S"
        }
    ],
    "KeySchema": [
        {
            "AttributeName": "key",
            "KeyType": "HASH"
        }
    ],
    "ProvisionedThroughput": {
        "ReadCapacityUnits": 5,
        "WriteCapacityUnits": 5
    }
}
EOF
    create-table "$JSON"
fi
