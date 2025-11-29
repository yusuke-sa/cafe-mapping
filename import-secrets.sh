#!/bin/bash

ENV_NAME="PRD"
REPO="yusuke-sa/cafe-mapping"

while IFS='=' read -r key value; do
  if [[ "$key" =~ ^# ]] || [[ -z "$key" ]]; then
    continue
  fi

  echo "🔐 Setting $key ..."
  gh secret set "$key" --repos "$REPO" --env "$ENV_NAME" --body "$value"
done < .env