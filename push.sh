#!/bin/bash

# エラー時に停止
set -e

# .envファイルを読み込む
if [ -f .env ]; then
  export $(grep -v '^#' .env | xargs)
else
  echo ".env file not found!"
  exit 1
fi

echo "--- GCP 認証設定 ---"
gcloud auth configure-docker ${GCP_LOCATION}-docker.pkg.dev --quiet

echo "--- Docker ビルド ---"
docker compose build

echo "--- Artifact Registry へ Push ---"
docker compose push

echo "--- 完了 ---"
echo "URL: https://console.cloud.google.com/artifacts/docker/${GCP_PROJECT_ID}/${GCP_LOCATION}/${GCP_REPOSITORY}"
