#!/bin/bash
READ_PATH="/srv/Terraform_resources"

cd "$READ_PATH" || {
    echo "repo path does not exist"
    exit 1
}

echo "pulling the latest code in $READ_PATH"
if git pull; then
    echo "pull was successfull"
else
    echo "pull failed"
fi
