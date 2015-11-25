#!/bin/bash

set -eo pipefail

REGION="us-west-2"
TABLE="SaltPillar"

function test-table {
    (aws --region $REGION dynamodb describe-table --table-name $1 > /dev/null 2>&1 && echo $1) || true
}

function create-table {
    aws --region $REGION dynamodb create-table --cli-input-json "$1"
}

if [ -z "$(test-table $TABLE)" ]; then
    echo "Creating the $TABLE table ..."
    read -r -d '' JSON <<- EOF || true
{
    "TableName": "$TABLE",
    "AttributeDefinitions": [
        {
            "AttributeName": "id",
            "AttributeType": "S"
        }
    ],
    "KeySchema": [
        {
            "AttributeName": "id",
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
