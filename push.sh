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

# --- デプロイ・運用メモ ---
# 1. デプロイ先(GCE等)での準備
#    gcloud auth configure-docker ${GCP_LOCATION}-docker.pkg.dev
#
# 2. 本番用 docker-compose.yml の構成案
#    image: ${GCP_LOCATION}-docker.pkg.dev/${GCP_PROJECT_ID}/${GCP_REPOSITORY}/${IMAGE_NAME}:${IMAGE_TAG}
#    ※ build 指定を image 指定に置き換え、レジストリから取得するようにする
#
# 3. 更新手順
#    docker compose pull
#    docker compose up -d
#
# 4. トラブルシューティング
#    docker compose logs -f
